import Foundation

/// Turns raw `l2Book` payloads into display-ready snapshots: parses numbers, accumulates depth,
/// pre-formats every label, and diffs against the previous snapshot so rows know whether to flash.
/// A pure value type with no networking, so it runs inside the feed actor and tests directly.
struct SnapshotBuilder: Sendable {
    private var previous: BookSnapshot?
    private var sequence: UInt64 = 0
    private let format: BookFormatter

    init(format: BookFormatter = BookFormatter()) {
        self.format = format
    }

    /// Forget history, so the next snapshot starts a new sequence and nothing flashes on arrival.
    mutating func reset() {
        previous = nil
        sequence = 0
    }

    mutating func build(from book: WireBook, subscription: BookSubscription, receivedAt: Date) -> BookSnapshot? {
        guard book.levels.count == 2 else { return nil }
        let rawBids = Self.parse(book.levels[0])
        let rawAsks = Self.parse(book.levels[1])
        sequence += 1

        let bestBid = rawBids.first?.price
        let bestAsk = rawAsks.first?.price
        let mid: Double? = if let bestBid, let bestAsk { (bestBid + bestAsk) / 2 } else { bestBid ?? bestAsk }
        let spread: Double? = if let bestBid, let bestAsk { bestAsk - bestBid } else { nil }
        let spreadBps = if let spread, let mid, mid > 0 { spread / mid * 10_000 } else { Double.nan }

        let context = SideContext(
            maxDepth: max(rawBids.reduce(0) { $0 + $1.size }, rawAsks.reduce(0) { $0 + $1.size }),
            sequence: sequence,
            priceDecimals: BookFormatter.priceDecimals(
                nSigFigs: subscription.nSigFigs, reference: mid ?? 0, prices: book.levels.flatMap { $0.map(\.px) }),
            sizeDecimals: Symbol(rawValue: book.coin)?.sizeDecimals ?? BookFormatter.fallbackSizeDecimals,
            hasHistory: previous != nil
        )
        let trend: PriceTrend =
            switch (mid, previous?.mid) {
            case let (mid?, last?) where mid > last: .up
            case let (mid?, last?) where mid < last: .down
            default: previous?.trend ?? .flat
            }

        let snapshot = BookSnapshot(
            subscription: subscription,
            sequence: sequence,
            bids: finalize(rawBids, previous: previous?.bids ?? [], context: context),
            asks: finalize(rawAsks, previous: previous?.asks ?? [], context: context),
            mid: mid,
            spread: spread,
            trend: trend,
            midLabel: mid.map { format.decimal($0, fractionDigits: context.priceDecimals + 1) } ?? "–",
            spreadLabel: spread.map { format.decimal($0, fractionDigits: context.priceDecimals) } ?? "–",
            spreadBpsLabel: format.decimal(spreadBps, fractionDigits: 2),
            receivedAt: receivedAt
        )
        previous = snapshot
        return snapshot
    }

    // MARK: - Sides

    private struct RawLevel {
        let id: String
        let price: Double
        let size: Double
    }

    private struct SideContext {
        let maxDepth: Double
        let sequence: UInt64
        let priceDecimals: Int
        let sizeDecimals: Int
        let hasHistory: Bool
    }

    private static func parse(_ levels: [WireLevel]) -> [RawLevel] {
        levels.compactMap { level in
            guard let price = Double(level.px), let size = Double(level.sz) else { return nil }
            return RawLevel(id: level.px, price: price, size: size)
        }
    }

    /// Bars are a few hundred points wide at most, so 1/512 is below a pixel. Rounding to it means a
    /// row whose bar would not visibly move compares equal to its previous value and skips `body`.
    private static let depthResolution = 512.0

    private static func quantise(_ fraction: Double) -> Double {
        (fraction * depthResolution).rounded() / depthResolution
    }

    private func finalize(_ raw: [RawLevel], previous: [BookLevel], context: SideContext) -> [BookLevel] {
        var result: [BookLevel] = []
        result.reserveCapacity(raw.count)
        var total = 0.0
        var notional = 0.0
        for level in raw {
            total += level.size
            notional += level.price * level.size

            // 20 levels per side: a linear scan beats building a dictionary every snapshot.
            let prior = previous.first { $0.id == level.id }
            let change: LevelChange =
                switch prior {
                case nil: context.hasHistory ? .new : .unchanged
                case let prior? where level.size > prior.size: .increased
                case let prior? where level.size < prior.size: .decreased
                default: .unchanged
                }

            result.append(
                BookLevel(
                    id: level.id,
                    price: level.price,
                    size: level.size,
                    total: total,
                    depthFraction: Self.quantise(context.maxDepth > 0 ? total / context.maxDepth : 0),
                    change: change,
                    flashToken: change == .unchanged ? (prior?.flashToken ?? 0) : context.sequence,
                    labels: LevelLabels(
                        price: format.decimal(level.price, fractionDigits: context.priceDecimals),
                        size: format.decimal(level.size, fractionDigits: context.sizeDecimals),
                        sizeUSD: format.compactUSD(level.price * level.size),
                        total: format.decimal(total, fractionDigits: context.sizeDecimals),
                        totalUSD: format.compactUSD(notional)
                    )
                ))
        }
        return result
    }
}
