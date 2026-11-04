import Foundation

/// Messages the client sends. Keys are sorted so the output is stable and easy to assert on.
enum ClientMessage {
    static let ping = #"{"method":"ping"}"#

    static func subscribe(_ subscription: BookSubscription) -> String {
        encode(Envelope(method: "subscribe", subscription: subscription))
    }

    static func unsubscribe(_ subscription: BookSubscription) -> String {
        encode(Envelope(method: "unsubscribe", subscription: subscription))
    }

    static func subscribeTrades(coin: String) -> String {
        encode(Envelope(method: "subscribe", subscription: TradesSubscription(coin: coin)))
    }

    static func unsubscribeTrades(coin: String) -> String {
        encode(Envelope(method: "unsubscribe", subscription: TradesSubscription(coin: coin)))
    }

    private struct TradesSubscription: Encodable {
        var type = BookSubscriptionKind.trades
        let coin: String
    }

    private struct Envelope<Subscription: Encodable>: Encodable {
        let method: String
        let subscription: Subscription
    }

    private static func encode<Subscription: Encodable>(_ envelope: Envelope<Subscription>) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        guard let data = try? encoder.encode(envelope) else { return "" }
        return String(decoding: data, as: UTF8.self)
    }
}

struct WireLevel: Decodable, Sendable {
    let px: String
    let sz: String
    let n: Int
}

/// Raw `l2Book` payload. `levels[0]` holds bids (best first), `levels[1]` holds asks (best first).
/// Every message is a full snapshot, so there is no sequence or delta state to maintain.
struct WireBook: Decodable, Sendable {
    let coin: String
    let time: Int64
    let levels: [[WireLevel]]
}

/// One trade from the `trades` channel. `side` is the taker's: "B" bought, "A" sold. `tid` is unique
/// but not ordered, so arrival order is the only ordering; `hash` is often all zeros and is unused.
struct WireTrade: Decodable, Sendable {
    let coin: String
    let side: String
    let px: String
    let sz: String
    let time: Int64
    let tid: Int64
}

/// Channel names that appear in a subscription's `type`.
enum BookSubscriptionKind {
    static let trades = "trades"
}

/// Server frames, decoded in a single pass keyed on `channel`.
enum ServerMessage: Decodable, Sendable {
    case book(WireBook)
    case trades([WireTrade])
    case subscribed(BookSubscription)
    case unsubscribed(BookSubscription)
    case pong
    case error(String)
    case other(channel: String)

    private enum CodingKeys: String, CodingKey {
        case channel, data
    }

    private struct Ack: Decodable {
        let method: String
        let subscription: BookSubscription
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let channel = try container.decode(String.self, forKey: .channel)
        switch channel {
        case "l2Book":
            self = .book(try container.decode(WireBook.self, forKey: .data))
        case BookSubscriptionKind.trades:
            self = .trades(try container.decode([WireTrade].self, forKey: .data))
        case "subscriptionResponse":
            let ack = try container.decode(Ack.self, forKey: .data)
            // Trades need no handshake: each trade names its coin. Their acks must not reach the
            // book's bookkeeping, where one would read as a confirmed book subscription.
            guard ack.subscription.type != BookSubscriptionKind.trades else {
                self = .other(channel: channel)
                return
            }
            self = ack.method == "unsubscribe" ? .unsubscribed(ack.subscription) : .subscribed(ack.subscription)
        case "pong":
            self = .pong
        case "error":
            self = .error((try? container.decode(String.self, forKey: .data)) ?? "unknown error")
        default:
            self = .other(channel: channel)
        }
    }

    static func decode(_ text: String) throws -> ServerMessage {
        try JSONDecoder().decode(ServerMessage.self, from: Data(text.utf8))
    }
}
