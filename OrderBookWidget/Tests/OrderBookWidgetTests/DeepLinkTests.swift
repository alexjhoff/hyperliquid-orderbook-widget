import Foundation
import Testing

@testable import OrderBookWidget

struct DeepLinkTests {
    @Test(arguments: Symbol.allCases)
    func roundTrips(_ symbol: Symbol) {
        #expect(DeepLink.symbol(from: DeepLink.url(for: symbol)) == symbol)
    }

    @Test func parsesCaseInsensitively() throws {
        #expect(DeepLink.symbol(from: try #require(URL(string: "orderbook://book?coin=eth"))) == .eth)
    }

    @Test(arguments: ["https://book?coin=BTC", "orderbook://trade?coin=BTC", "orderbook://book?coin=DOGE", "orderbook://book"])
    func rejectsOtherLinks(_ link: String) throws {
        #expect(DeepLink.symbol(from: try #require(URL(string: link))) == nil)
    }
}
