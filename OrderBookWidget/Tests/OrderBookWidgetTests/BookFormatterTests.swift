import Foundation
import Testing

@testable import OrderBookWidget

struct BookFormatterTests {
    let format = BookFormatter(locale: Locale(identifier: "en_US"))

    @Test func fixedFractionDigitsWithGrouping() {
        #expect(format.decimal(77719, fractionDigits: 1) == "77,719.0")
        #expect(format.decimal(2268.95, fractionDigits: 1) == "2,269.0")
        #expect(format.decimal(0.42548, fractionDigits: 5) == "0.42548")
        #expect(format.decimal(.nan, fractionDigits: 2) == "–")
    }

    @Test func compactDollars() {
        #expect(format.compactUSD(842.4) == "$842")
        #expect(format.compactUSD(1_234) == "$1.23K")
        #expect(format.compactUSD(12_345) == "$12.3K")
        #expect(format.compactUSD(1_920_000) == "$1.92M")
    }

    @Test func priceDecimalsFollowGroupingAndServerDigits() {
        #expect(BookFormatter.priceDecimals(nSigFigs: 5, reference: 77_719.5, prices: ["77719.0"]) == 0)
        #expect(BookFormatter.priceDecimals(nSigFigs: 5, reference: 2_269.05, prices: ["2269.0"]) == 1)
        #expect(BookFormatter.priceDecimals(nSigFigs: 2, reference: 77_500, prices: ["77000.0"]) == 0)
        #expect(BookFormatter.priceDecimals(nSigFigs: nil, reference: 2_269.05, prices: ["2269.0", "2268.95"]) == 2)
    }
}
