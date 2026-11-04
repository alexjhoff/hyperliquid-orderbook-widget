/// What a feed tells its consumer, in order.
enum FeedEvent: Sendable, Equatable {
    case status(ConnectionStatus)
    case book(BookSnapshot)
    /// New trades, oldest first. The first batch of a subscription is a snapshot of recent ones.
    case trades([Trade])
}

/// Source of order book snapshots for the view model. `HyperliquidFeed` is the live one; previews
/// and tests use fakes.
protocol OrderBookFeed: Sendable {
    /// A fresh stream of events. Calling it again finishes the previous stream.
    func events() async -> AsyncStream<FeedEvent>
    /// Streams `subscription` and its coin's trades, replacing any previous ones, and connects if needed.
    func subscribe(_ subscription: BookSubscription) async
    func disconnect() async
}
