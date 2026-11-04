import Foundation
import Testing

@testable import OrderBookWidget

struct BookRefresherTests {
    struct StubFetcher: BookSnapshotFetching {
        let result: Result<BookSnapshot, URLError>

        func fetch(_ subscription: BookSubscription) async throws -> BookSnapshot {
            try result.get()
        }
    }

    let now = Date(timeIntervalSince1970: 1_000)
    let btc = BookSubscription(coin: "BTC", nSigFigs: nil)

    @Test func successWaitsTheFullInterval() async {
        let refresher = BookRefresher(fetcher: StubFetcher(result: .success(makeSnapshot(btc))))
        let result = await refresher.refresh(btc, now: now)
        #expect(result.snapshot?.subscription == btc)
        #expect(result.nextRefresh == now.addingTimeInterval(BookRefresher.interval))
    }

    @Test func failureRetriesSooner() async {
        let refresher = BookRefresher(fetcher: StubFetcher(result: .failure(URLError(.notConnectedToInternet))))
        let result = await refresher.refresh(btc, now: now)
        #expect(result.snapshot == nil)
        #expect(result.nextRefresh == now.addingTimeInterval(BookRefresher.intervalAfterFailure))
    }
}
