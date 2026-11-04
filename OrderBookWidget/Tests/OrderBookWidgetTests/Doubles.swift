import Foundation

@testable import OrderBookWidget

/// A feed the test drives by hand.
actor FakeFeed: OrderBookFeed {
    private(set) var subscriptions: [BookSubscription] = []
    private(set) var disconnects = 0
    private var sink: AsyncStream<FeedEvent>.Continuation?

    func events() -> AsyncStream<FeedEvent> {
        let (stream, continuation) = AsyncStream.makeStream(of: FeedEvent.self)
        sink = continuation
        return stream
    }

    func subscribe(_ subscription: BookSubscription) {
        subscriptions.append(subscription)
    }

    func disconnect() {
        disconnects += 1
    }

    func send(_ event: FeedEvent) {
        sink?.yield(event)
    }
}

func makeSnapshot(_ subscription: BookSubscription, bestBid: String = "100") -> BookSnapshot {
    var builder = SnapshotBuilder()
    return builder.build(from: makeBook(bids: [(bestBid, "1")], asks: [("101", "1")]), subscription: subscription, receivedAt: .now)!
}

func makeTrade(_ id: Int64, coin: String = "BTC") -> Trade {
    Trade(id: id, coin: coin, side: .bid, labels: TradeLabels(price: "1", size: "1", sizeUSD: "$1", time: "0"))
}

/// Polls `condition` on the main actor until it holds or the timeout passes.
@MainActor
func eventually(timeout: Duration = .seconds(2), _ condition: @MainActor () async -> Bool) async -> Bool {
    let deadline = ContinuousClock.now + timeout
    while ContinuousClock.now < deadline {
        if await condition() { return true }
        try? await Task.sleep(for: .milliseconds(5))
    }
    return await condition()
}
