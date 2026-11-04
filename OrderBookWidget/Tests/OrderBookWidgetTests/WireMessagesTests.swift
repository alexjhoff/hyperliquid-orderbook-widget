import Testing

@testable import OrderBookWidget

struct WireMessagesTests {
    @Test func decodesABookFrame() throws {
        let book = try Fixture.book(Fixture.btcBook)
        #expect(book.coin == "BTC")
        #expect(book.levels[0].map(\.px) == ["77719.0", "77718.0", "77717.0"])
        #expect(book.levels[1].first?.sz == "4.7368")
    }

    @Test func decodesAcksIntoSubscriptions() throws {
        #expect(try ServerMessage.decode(Fixture.subscribeAck).subscription == BookSubscription(coin: "BTC", nSigFigs: 5))
        #expect(try ServerMessage.decode(Fixture.fullPrecisionAck).subscription == BookSubscription(coin: "BTC", nSigFigs: nil))
        guard case .unsubscribed(let subscription) = try ServerMessage.decode(Fixture.unsubscribeAck) else {
            Issue.record("expected an unsubscribe ack")
            return
        }
        #expect(subscription == BookSubscription(coin: "ETH", nSigFigs: 3))
    }

    @Test func decodesPongErrorAndUnknownChannels() throws {
        #expect(try ServerMessage.decode(#"{"channel":"pong"}"#).isPong)
        #expect(try ServerMessage.decode(#"{"channel":"error","data":"bad"}"#).errorText == "bad")
        #expect(try ServerMessage.decode(#"{"channel":"candle","data":[]}"#).otherChannel == "candle")
    }

    @Test func rejectsMalformedInput() {
        #expect(throws: (any Error).self) { try ServerMessage.decode("{not json") }
        #expect(throws: (any Error).self) { try ServerMessage.decode(#"{"data":{}}"#) }
    }

    @Test func encodesSubscribeAndUnsubscribe() {
        let full = BookSubscription(coin: "BTC", nSigFigs: nil)
        #expect(ClientMessage.subscribe(full) == #"{"method":"subscribe","subscription":{"coin":"BTC","type":"l2Book"}}"#)
        let grouped = BookSubscription(coin: "ETH", nSigFigs: 3)
        #expect(
            ClientMessage.unsubscribe(grouped)
                == #"{"method":"unsubscribe","subscription":{"coin":"ETH","nSigFigs":3,"type":"l2Book"}}"#)
    }

    @Test func decodesATradesFrame() throws {
        guard case .trades(let trades) = try ServerMessage.decode(Fixture.btcTrades) else {
            Issue.record("not a trades frame")
            return
        }
        #expect(trades.map(\.tid) == [435_596_369_646_620, 471_324_263_320_187])
        #expect(trades.map(\.side) == ["B", "A"])
    }

    @Test func aTradesAckIsNotABookAck() throws {
        guard case .other = try ServerMessage.decode(Fixture.tradesSubscribeAck) else {
            Issue.record("a trades ack must not read as a book subscription")
            return
        }
    }

    @Test func encodesTradesRequests() {
        #expect(ClientMessage.subscribeTrades(coin: "BTC") == #"{"method":"subscribe","subscription":{"coin":"BTC","type":"trades"}}"#)
        #expect(ClientMessage.unsubscribeTrades(coin: "ETH") == #"{"method":"unsubscribe","subscription":{"coin":"ETH","type":"trades"}}"#)
    }
}

extension ServerMessage {
    fileprivate var subscription: BookSubscription? {
        switch self {
        case .subscribed(let subscription), .unsubscribed(let subscription): subscription
        default: nil
        }
    }

    fileprivate var isPong: Bool {
        if case .pong = self { true } else { false }
    }

    fileprivate var errorText: String? {
        if case .error(let text) = self { text } else { nil }
    }

    fileprivate var otherChannel: String? {
        if case .other(let channel) = self { channel } else { nil }
    }
}
