import Foundation
import Testing

@testable import OrderBookWidget

struct TradeBuilderTests {
    let builder = TradeBuilder(format: BookFormatter(locale: Locale(identifier: "en_US")))

    func wire(coin: String = "BTC", side: String = "B", px: String = "80121.0", sz: String = "0.01199") -> WireTrade {
        WireTrade(coin: coin, side: side, px: px, sz: sz, time: 1_793_829_146_896, tid: 1)
    }

    @Test func formatsLabelsAtExchangePrecision() throws {
        let btc = try #require(builder.build([wire()]).first)
        #expect(btc.labels.price == "80,121")
        #expect(btc.labels.size == "0.01199")
        #expect(btc.labels.sizeUSD == "$961")
        #expect(!btc.labels.time.isEmpty)

        let eth = try #require(builder.build([wire(coin: "ETH", px: "2269.1", sz: "1.5")]).first)
        #expect(eth.labels.price == "2,269.1")
        #expect(eth.labels.size == "1.5000")
    }

    @Test func wholeEthPricesKeepTheColumnWidth() throws {
        let eth = try #require(builder.build([wire(coin: "ETH", px: "2269.0", sz: "1")]).first)
        #expect(eth.labels.price == "2,269.0")
    }

    @Test func mapsTheTakersSide() {
        #expect(builder.build([wire(side: "B"), wire(side: "A")]).map(\.side) == [.bid, .ask])
    }

    @Test func skipsMalformedTradesAndKeepsTheRest() {
        let trades = [wire(side: "X"), wire(px: "nope"), wire()]
        #expect(builder.build(trades).count == 1)
    }
}
