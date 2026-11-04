import Foundation

/// One-shot book fetch for callers that cannot hold a socket, such as the Home Screen widget.
public protocol BookSnapshotFetching: Sendable {
    func fetch(_ subscription: BookSubscription) async throws -> BookSnapshot
}

/// Hyperliquid's `info` endpoint: `POST {"type":"l2Book","coin":...}` returns the same payload as
/// one websocket `l2Book` frame, so decoding and building are shared with the live feed.
public struct HyperliquidInfoClient: BookSnapshotFetching {
    public typealias Transport = @Sendable (URLRequest) async throws -> (Data, URLResponse)

    static let url = URL(string: "https://api.hyperliquid.xyz/info")!
    private let transport: Transport

    public init() {
        self.init { try await URLSession.shared.data(for: $0) }
    }

    init(transport: @escaping Transport) {
        self.transport = transport
    }

    public func fetch(_ subscription: BookSubscription) async throws -> BookSnapshot {
        var request = URLRequest(url: Self.url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        request.httpBody = try encoder.encode(Query(coin: subscription.coin, nSigFigs: subscription.nSigFigs))

        let (data, response) = try await transport(request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            Log.widget.error("Info request failed with status \(http.statusCode)")
            throw URLError(.badServerResponse)
        }
        let book = try JSONDecoder().decode(WireBook.self, from: data)
        var builder = SnapshotBuilder()
        guard let snapshot = builder.build(from: book, subscription: subscription, receivedAt: .now) else {
            throw URLError(.cannotParseResponse)
        }
        Log.widget.info("Fetched \(subscription, privacy: .public) over info")
        return snapshot
    }

    private struct Query: Encodable {
        var type = "l2Book"
        let coin: String
        let nSigFigs: Int?
    }
}
