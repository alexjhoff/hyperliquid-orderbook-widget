import Foundation
import Testing

@testable import OrderBookWidget

struct HyperliquidFeedTests {
    let clock = TestClock()
    let sockets = FakeSockets()
    let policy = ReconnectPolicy()
    let btc = BookSubscription(coin: "BTC", nSigFigs: nil)
    let btcGrouped = BookSubscription(coin: "BTC", nSigFigs: 3)

    static let unsubscribeBTCAck = #"""
        {"channel":"subscriptionResponse","data":{"method":"unsubscribe","subscription":{"type":"l2Book","coin":"BTC","nSigFigs":null}}}
        """#
    static let subscribeGroupedAck = #"""
        {"channel":"subscriptionResponse","data":{"method":"subscribe","subscription":{"type":"l2Book","coin":"BTC","nSigFigs":3}}}
        """#

    func makeFeed() -> HyperliquidFeed {
        HyperliquidFeed(url: URL(string: "wss://example.test/ws")!, policy: policy, clock: clock, makeSocket: { [sockets] in sockets.make($0) })
    }

    /// Subscribes and waits for the first socket to be connected and the subscribe request sent.
    func connect(_ feed: HyperliquidFeed, _ events: inout AsyncStream<FeedEvent>.AsyncIterator) async throws -> FakeSocket {
        await feed.subscribe(btc)
        let connecting = await events.next()
        #expect(connecting == .status(.connecting))
        let connected = await events.next()
        #expect(connected == .status(.connected))
        let socket = try #require(sockets.all.last)
        #expect(await eventually { socket.sent == [ClientMessage.subscribe(btc)] })
        return socket
    }

    @Test func connectsSubscribesAndEmitsBooks() async throws {
        let feed = makeFeed()
        var events = await feed.events().makeAsyncIterator()
        let socket = try await connect(feed, &events)

        socket.push(Fixture.fullPrecisionAck)
        socket.push(Fixture.btcBook)
        let event = await events.next()
        guard case .book(let snapshot) = event else {
            Issue.record("expected a book, got \(String(describing: event))")
            return
        }
        #expect(snapshot.subscription == btc)
        #expect(snapshot.bids.count == 3 && snapshot.asks.count == 3)

        await feed.disconnect()
        #expect(socket.isClosed)
    }

    @Test func groupingChangeUnsubscribesBeforeSubscribing() async throws {
        let feed = makeFeed()
        var events = await feed.events().makeAsyncIterator()
        let socket = try await connect(feed, &events)
        socket.push(Fixture.fullPrecisionAck)

        await feed.subscribe(btcGrouped)
        #expect(await eventually { socket.sent.last == ClientMessage.unsubscribe(btc) })
        socket.push(Fixture.btcBook)  // still the old grouping: must not reach the consumer
        socket.push(Self.unsubscribeBTCAck)
        #expect(await eventually { socket.sent.last == ClientMessage.subscribe(btcGrouped) })
        socket.push(Self.subscribeGroupedAck)
        socket.push(Fixture.btcBook)

        let event = await events.next()
        guard case .book(let snapshot) = event else {
            Issue.record("expected a book, got \(String(describing: event))")
            return
        }
        #expect(snapshot.subscription == btcGrouped, "the first book out is stamped with the new grouping")
        await feed.disconnect()
    }

    @Test func reconnectsWithBackoffAndResubscribes() async throws {
        let feed = makeFeed()
        var events = await feed.events().makeAsyncIterator()
        let first = try await connect(feed, &events)

        first.drop()
        let retry = await events.next()
        guard case .status(.reconnecting(let attempt, let delay)) = retry else {
            Issue.record("expected a retry, got \(String(describing: retry))")
            return
        }
        #expect(attempt == 1)
        #expect(delay <= policy.base)
        #expect(await eventually { clock.sleeperCount == 1 })
        clock.advance(by: policy.base)

        let connecting = await events.next()
        #expect(connecting == .status(.connecting))
        let connected = await events.next()
        #expect(connected == .status(.connected))
        let second = try #require(sockets.all.last)
        #expect(second !== first)
        #expect(await eventually { second.sent == [ClientMessage.subscribe(btc)] })
        await feed.disconnect()
    }

    @Test func pingsWhenIdleAndGivesUpOnSilence() async throws {
        let feed = makeFeed()
        var events = await feed.events().makeAsyncIterator()
        let socket = try await connect(feed, &events)

        var elapsed = Duration.zero
        while elapsed < policy.pingInterval {
            #expect(await eventually { clock.sleeperCount == 1 })
            clock.advance(by: policy.checkInterval)
            elapsed += policy.checkInterval
        }
        #expect(await eventually { socket.sent.last == ClientMessage.ping })

        while elapsed < policy.receiveTimeout {
            #expect(await eventually { clock.sleeperCount == 1 })
            clock.advance(by: policy.checkInterval)
            elapsed += policy.checkInterval
        }
        let retry = await events.next()
        guard case .status(.reconnecting(let attempt, _)) = retry else {
            Issue.record("expected a retry, got \(String(describing: retry))")
            return
        }
        #expect(attempt == 1)
        await feed.disconnect()
    }
}
