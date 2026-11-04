import Foundation
import Testing

@testable import OrderBookWidget

struct SnapshotBuilderTests {
    let btc = BookSubscription(coin: "BTC", nSigFigs: 5)
    var builder = SnapshotBuilder(format: BookFormatter(locale: Locale(identifier: "en_US")))

    private mutating func build(_ book: WireBook) -> BookSnapshot? {
        builder.build(from: book, subscription: btc, receivedAt: .now)
    }

    @Test mutating func accumulatesDepthAndLabelsACapturedBook() throws {
        let built = build(try Fixture.book(Fixture.btcBook))
        let snapshot = try #require(built)

        #expect(snapshot.bids.map(\.labels.total) == ["6.28612", "7.43102", "7.85650"])
        #expect(snapshot.bids.last?.depthFraction == 1)
        #expect(snapshot.asks.last.map { $0.depthFraction < 1 } == true)
        #expect(snapshot.mid == 77_719.5)
        #expect(snapshot.midLabel == "77,719.5")
        #expect(snapshot.spreadLabel == "1")
        #expect(snapshot.spreadBpsLabel == "0.13")
        #expect(snapshot.bids[0].labels == LevelLabels(price: "77,719", size: "6.28612", sizeUSD: "$489K", total: "6.28612", totalUSD: "$489K"))
        #expect(snapshot.bids.allSatisfy { $0.change == .unchanged && $0.flashToken == 0 })
    }

    @Test mutating func classifiesChangesAgainstThePreviousSnapshot() throws {
        _ = build(makeBook(bids: [("100", "1"), ("99", "1")], asks: [("101", "1")]))
        let second = build(makeBook(bids: [("100", "2"), ("98", "1")], asks: [("101", "0.5")]))
        let next = try #require(second)

        #expect(next.sequence == 2)
        #expect(next.bids.map(\.change) == [.increased, .new])
        #expect(next.asks.map(\.change) == [.decreased])
        #expect(next.bids.map(\.flashToken) == [2, 2])

        let third = build(makeBook(bids: [("100", "2"), ("98", "1")], asks: [("101", "0.5")]))
        let same = try #require(third)
        #expect(same.bids.map(\.change) == [.unchanged, .unchanged])
        #expect(same.bids.map(\.flashToken) == [2, 2], "an unchanged row keeps its token so it does not flash again")
    }

    @Test mutating func tracksTheMidTrend() {
        let first = build(makeBook(bids: [("100", "1")], asks: [("101", "1")]))
        let up = build(makeBook(bids: [("101", "1")], asks: [("102", "1")]))
        let flat = build(makeBook(bids: [("101", "1")], asks: [("102", "1")]))
        let down = build(makeBook(bids: [("99", "1")], asks: [("100", "1")]))
        #expect([first?.trend, up?.trend, flat?.trend, down?.trend] == [.flat, .up, .up, .down])
    }

    @Test mutating func resetForgetsHistory() throws {
        _ = build(makeBook(bids: [("100", "1")], asks: [("101", "1")]))
        builder.reset()
        let built = build(makeBook(bids: [("200", "1")], asks: [("201", "1")]))
        let fresh = try #require(built)
        #expect(fresh.sequence == 1)
        #expect(fresh.bids[0].change == .unchanged)
        #expect(fresh.trend == .flat)
    }

    @Test mutating func handlesOneSidedAndMalformedBooks() throws {
        let oneSidedBuilt = build(makeBook(bids: [("100", "1")], asks: []))
        let oneSided = try #require(oneSidedBuilt)
        #expect(oneSided.mid == 100)
        #expect(oneSided.spread == nil)
        #expect(oneSided.spreadLabel == "–")

        #expect(build(WireBook(coin: "BTC", time: 0, levels: [[]])) == nil)

        let junkBuilt = build(makeBook(bids: [("abc", "1"), ("100", "1")], asks: []))
        let junk = try #require(junkBuilt)
        #expect(junk.bids.map(\.id) == ["100"])
    }
}
