import Foundation

/// Price grouping, sent to Hyperliquid as `nSigFigs`: 2 to 5 significant figures, or omitted for
/// full precision. Cases run finest to coarsest. The raw value is the persisted form.
public enum Precision: String, CaseIterable, Identifiable, Sendable {
    case full
    case five = "5"
    case four = "4"
    case three = "3"
    case two = "2"

    public var id: Self { self }

    public var nSigFigs: Int? {
        switch self {
        case .full: nil
        case .five: 5
        case .four: 4
        case .three: 3
        case .two: 2
        }
    }

    public var name: String {
        nSigFigs.map { "\($0) sig figs" } ?? "Full precision"
    }

    /// Price increment this grouping produces near `price`: 4 sig figs at 77,719 gives 10.
    /// Hyperliquid always allows integer prices, so full precision never widens past 1.
    public func tick(near price: Double) -> Double {
        guard price.isFinite, price > 0 else { return 0 }
        let integerDigits = Int((log10(price) + 1e-9).rounded(.down)) + 1
        guard let nSigFigs else { return pow(10, Double(min(integerDigits - 5, 0))) }
        return pow(10, Double(integerDigits - nSigFigs))
    }
}
