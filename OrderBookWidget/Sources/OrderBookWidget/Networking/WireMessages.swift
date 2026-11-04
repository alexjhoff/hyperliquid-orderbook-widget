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

    private struct Envelope: Encodable {
        let method: String
        let subscription: BookSubscription
    }

    private static func encode(_ envelope: Envelope) -> String {
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

/// Server frames, decoded in a single pass keyed on `channel`.
enum ServerMessage: Decodable, Sendable {
    case book(WireBook)
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
        case "subscriptionResponse":
            let ack = try container.decode(Ack.self, forKey: .data)
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
