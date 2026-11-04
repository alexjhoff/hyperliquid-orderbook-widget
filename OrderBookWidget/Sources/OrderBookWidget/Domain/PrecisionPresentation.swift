import Foundation

/// How a grouping is named in the menu: by the tick it produces near the current price, the way
/// traders think about it, e.g. "$10" for 4 sig figs at $77,000.
enum PrecisionPresentation {
    static func tickLabel(for precision: Precision, near price: Double?, format: BookFormatter = BookFormatter()) -> String {
        guard let price, case let tick = precision.tick(near: price), tick > 0 else { return precision.name }
        let decimals = max(0, Int((-log10(tick)).rounded(.up)))
        return "$" + format.decimal(tick, fractionDigits: decimals)
    }
}
