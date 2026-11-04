import Testing

@testable import OrderBookWidget

struct TradeTapeTests {
    func trade(_ id: Int64) -> Trade {
        Trade(id: id, coin: "BTC", side: .bid, labels: TradeLabels(price: "1", size: "1", sizeUSD: "$1", time: "0"))
    }

    @Test func newestFirstAcrossBatches() {
        var tape = TradeTape()
        tape.append([trade(1), trade(2)])
        tape.append([trade(3)])
        #expect(tape.trades.map(\.id) == [3, 2, 1])
    }

    @Test func aReconnectSnapshotShowsNothingTwice() {
        var tape = TradeTape()
        tape.append([trade(1), trade(2)])
        tape.append([trade(2), trade(3)])
        #expect(tape.trades.map(\.id) == [3, 2, 1])
    }

    @Test func dropsTheOldestPastCapacity() {
        var tape = TradeTape()
        tape.append((0..<Int64(TradeTape.capacity + 5)).map(trade))
        #expect(tape.trades.count == TradeTape.capacity)
        #expect(tape.trades.first?.id == Int64(TradeTape.capacity + 4))
    }

    @Test func resetEmptiesIt() {
        var tape = TradeTape()
        tape.append([trade(1)])
        tape.reset()
        #expect(tape.trades.isEmpty)
    }
}
