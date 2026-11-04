import Foundation

/// Formats prices and sizes for display. A value type, so the feed can format every label off
/// the main thread and views never touch a number formatter.
struct BookFormatter: Sendable {
    static let maxFractionDigits = 9
    /// Shown wherever a number is not available yet.
    static let placeholder = "–"

    private let locale: Locale

    init(locale: Locale = .autoupdatingCurrent) {
        self.locale = locale
    }

    func decimal(_ value: Double, fractionDigits: Int) -> String {
        guard value.isFinite else { return Self.placeholder }
        return value.formatted(.number.precision(.fractionLength(fractionDigits)).locale(locale))
    }

    /// Dollar amounts at a glance: "$842", "$12.3K", "$1.92M".
    func compactUSD(_ value: Double) -> String {
        guard value.isFinite else { return Self.placeholder }
        if value < 999.5 {
            return "$" + decimal(value, fractionDigits: 0)
        }
        return "$" + value.formatted(.number.notation(.compactName).precision(.significantDigits(3)).locale(locale))
    }

    /// Decimal places for prices in one book. Derived from the grouping and the price magnitude so
    /// the column is stable, then widened if the server sends more digits so nothing is rounded away.
    static func priceDecimals(nSigFigs: Int?, reference: Double, prices: [String]) -> Int {
        let integerDigits = reference >= 1 ? Int((log10(reference) + 1e-9).rounded(.down)) + 1 : 1
        var decimals = nSigFigs.map { max(0, $0 - integerDigits) } ?? 0
        for price in prices {
            decimals = max(decimals, significantDecimals(in: price))
        }
        return min(decimals, maxFractionDigits)
    }

    private static func significantDecimals(in price: String) -> Int {
        guard let dot = price.firstIndex(of: ".") else { return 0 }
        let fraction = price[price.index(after: dot)...]
        guard let last = fraction.lastIndex(where: { $0 != "0" }) else { return 0 }
        return fraction.distance(from: fraction.startIndex, to: last) + 1
    }
}
