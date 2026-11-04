import Testing

@testable import OrderBookWidget

@MainActor
struct OrderBookViewModelTests {
    let feed = FakeFeed()
    let store = InMemorySelectionStore()
    let btc = BookSubscription(coin: "BTC", nSigFigs: nil)

    @Test func defaultsComeFromTheStore() {
        let empty = OrderBookViewModel(feed: feed, selections: InMemorySelectionStore())
        #expect(empty.symbol == .btc && empty.precision == .full && empty.sizeUnit == .coin)

        let saved = OrderBookViewModel(feed: feed, selections: InMemorySelectionStore(symbol: .eth, precision: .three, sizeUnit: .usd))
        #expect(saved.symbol == .eth && saved.precision == .three && saved.sizeUnit == .usd)
    }

    @Test func runSubscribesAndAppliesMatchingSnapshots() async {
        let model = OrderBookViewModel(feed: feed, selections: store)
        let running = Task { await model.run() }
        defer { running.cancel() }
        #expect(await eventually { await feed.subscriptions == [btc] })

        await feed.send(.status(.connected))
        await feed.send(.book(makeSnapshot(BookSubscription(coin: "ETH", nSigFigs: nil))))
        await feed.send(.book(makeSnapshot(btc)))
        #expect(await eventually { model.book != nil })
        #expect(model.book?.subscription == btc, "a snapshot for another subscription is ignored")
        #expect(model.status == .connected)
        #expect(!model.isStale)
    }

    @Test func keepsTradesForTheCurrentMarketOnly() async {
        let model = OrderBookViewModel(feed: feed, selections: store)
        let running = Task { await model.run() }
        defer { running.cancel() }
        #expect(await eventually { await feed.subscriptions == [btc] })

        await feed.send(.trades([makeTrade(1, coin: "ETH"), makeTrade(2)]))
        #expect(await eventually { !model.trades.isEmpty })
        #expect(model.trades.map(\.id) == [2], "another market's trades are ignored")

        model.symbol = .eth
        #expect(model.trades.isEmpty, "changing market starts a new tape")
        await feed.send(.trades([makeTrade(3)]))
        await feed.send(.trades([makeTrade(4, coin: "ETH")]))
        #expect(await eventually { !model.trades.isEmpty })
        #expect(model.trades.map(\.id) == [4])
    }

    @Test func changingASelectionPersistsAndResubscribes() async {
        let model = OrderBookViewModel(feed: feed, selections: store)
        let running = Task { await model.run() }
        defer { running.cancel() }
        #expect(await eventually { await feed.subscriptions == [btc] })
        await feed.send(.book(makeSnapshot(btc)))
        #expect(await eventually { model.book != nil })

        model.symbol = .eth
        model.precision = .three
        model.sizeUnit = .usd
        #expect(store.symbol == .eth && store.precision == .three && store.sizeUnit == .usd)
        #expect(model.isStale, "the old book stays on screen, dimmed, until the new one arrives")
        #expect(await eventually { await feed.subscriptions.last == BookSubscription(coin: "ETH", nSigFigs: 3) })

        model.sizeUnit = .coin
        #expect(await feed.subscriptions.count == 3, "a size unit change does not resubscribe")
    }

    @Test func cancellingRunDisconnects() async {
        let model = OrderBookViewModel(feed: feed, selections: store)
        let running = Task { await model.run() }
        #expect(await eventually { await feed.subscriptions == [btc] })
        #expect(await feed.disconnects == 0)

        running.cancel()
        await running.value
        #expect(await feed.disconnects == 1, "the socket closes when the view's task ends")
    }

    @Test func nothingReopensTheSocketAfterRunEnds() async {
        let model = OrderBookViewModel(feed: feed, selections: store)
        let running = Task { await model.run() }
        #expect(await eventually { await feed.subscriptions == [btc] })
        running.cancel()
        await running.value

        model.sceneDidBecomeActive()
        model.symbol = .eth
        await Task.yield()
        #expect(await feed.subscriptions == [btc], "a late scene change on a dismissed widget must not reconnect")
        #expect(store.symbol == .eth, "the selection is still remembered")
    }

    @Test func feedCallsArriveInTheOrderTheyWereMade() async {
        let model = OrderBookViewModel(feed: feed, selections: store)
        model.symbol = .eth
        model.symbol = .btc
        model.precision = .three
        let last = BookSubscription(coin: "BTC", nSigFigs: 3)
        #expect(await eventually { await feed.subscriptions.count == 3 })
        #expect(await feed.subscriptions.last == last)
    }

    @Test func backgroundingDisconnectsAndActivatingResubscribes() async {
        let model = OrderBookViewModel(feed: feed, selections: store)
        model.sceneDidEnterBackground()
        #expect(await eventually { await feed.disconnects == 1 })
        model.sceneDidBecomeActive()
        #expect(await eventually { await feed.subscriptions == [btc] })
    }
}
