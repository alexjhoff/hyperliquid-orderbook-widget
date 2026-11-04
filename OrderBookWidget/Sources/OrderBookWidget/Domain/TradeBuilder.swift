import Foundation

/// Turns raw trades into display-ready ones. A pure value type, so it runs inside the feed actor.
struct TradeBuilder: Sendable {
    private static let buySide = "B"
    private static let sellSide = "A"
    /// Hyperliquid perp prices carry at most this many significant figures, which keeps the price
    /// column at one width even though individual trades drop trailing zeros.
    private static let priceSignificantFigures = 5
    private static let millisecondsPerSecond = 1_000.0

    private let format: BookFormatter

    init(format: BookFormatter = BookFormatter()) {
        self.format = format
    }

    /// Skips anything malformed rather than failing the batch. Keeps the server's order.
    func build(_ trades: [WireTrade]) -> [Trade] {
        trades.compactMap(build)
    }

    private func build(_ trade: WireTrade) -> Trade? {
        guard let side = Self.side(trade.side), let price = Double(trade.px), let size = Double(trade.sz) else { return nil }
        let priceDecimals = BookFormatter.priceDecimals(nSigFigs: Self.priceSignificantFigures, reference: price, prices: [trade.px])
        let sizeDecimals = Symbol(rawValue: trade.coin)?.sizeDecimals ?? BookFormatter.fallbackSizeDecimals
        return Trade(
            id: trade.tid,
            coin: trade.coin,
            side: side,
            labels: TradeLabels(
                price: format.decimal(price, fractionDigits: priceDecimals),
                size: format.decimal(size, fractionDigits: sizeDecimals),
                sizeUSD: format.compactUSD(price * size),
                time: format.time(Date(timeIntervalSince1970: Double(trade.time) / Self.millisecondsPerSecond))
            )
        )
    }

    private static func side(_ wire: String) -> Side? {
        switch wire {
        case buySide: .bid
        case sellSide: .ask
        default: nil
        }
    }
}
