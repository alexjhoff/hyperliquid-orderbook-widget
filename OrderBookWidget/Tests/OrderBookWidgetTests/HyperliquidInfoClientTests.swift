import Foundation
import Testing

@testable import OrderBookWidget

struct HyperliquidInfoClientTests {
    @Test func postsTheQueryAndBuildsASnapshot() async throws {
        let client = HyperliquidInfoClient { request in
            #expect(request.httpMethod == "POST")
            #expect(request.url == HyperliquidInfoClient.url)
            let body = try #require(request.httpBody)
            #expect(String(decoding: body, as: UTF8.self) == #"{"coin":"ETH","nSigFigs":3,"type":"l2Book"}"#)
            return (Data(Fixture.infoResponse.utf8), HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
        }

        let snapshot = try await client.fetch(BookSubscription(coin: "ETH", nSigFigs: 3))
        #expect(snapshot.subscription == BookSubscription(coin: "ETH", nSigFigs: 3))
        #expect(snapshot.bids.map(\.id) == ["2229.9"])
        #expect(snapshot.asks.first?.size == 149.3142)
    }

    @Test func rejectsAFailedResponse() async {
        let client = HyperliquidInfoClient { request in
            (Data(), HTTPURLResponse(url: request.url!, statusCode: 503, httpVersion: nil, headerFields: nil)!)
        }
        await #expect(throws: URLError.self) {
            try await client.fetch(BookSubscription(coin: "BTC", nSigFigs: nil))
        }
    }
}

