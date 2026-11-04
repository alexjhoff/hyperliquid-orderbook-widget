/// What the server should be streaming against what it has confirmed. Pure bookkeeping: the feed
/// sends what `nextRequests()` returns and reports acks back.
///
/// Book frames do not say which grouping they carry, so they are admitted only when `confirmed`
/// equals `wanted` and no request is in flight. A change therefore unsubscribes the old grouping,
/// waits for the ack, then subscribes the new one. Trades need none of this, because each trade names
/// its coin: they follow the book's coin, and their requests go out without waiting.
struct SubscriptionLedger: Sendable {
    enum Request: Equatable, Sendable {
        case subscribe(BookSubscription)
        case unsubscribe(BookSubscription)
        case subscribeTrades(coin: String)
        case unsubscribeTrades(coin: String)

        var text: String {
            switch self {
            case .subscribe(let subscription): ClientMessage.subscribe(subscription)
            case .unsubscribe(let subscription): ClientMessage.unsubscribe(subscription)
            case .subscribeTrades(let coin): ClientMessage.subscribeTrades(coin: coin)
            case .unsubscribeTrades(let coin): ClientMessage.unsubscribeTrades(coin: coin)
            }
        }
    }

    private(set) var wanted: BookSubscription?
    private var confirmed: BookSubscription?
    private var pending: Request?
    private var tradesCoin: String?

    /// True when a book frame on the socket is known to belong to `wanted`.
    var admitsBooks: Bool {
        wanted != nil && pending == nil && confirmed == wanted
    }

    mutating func want(_ subscription: BookSubscription) {
        wanted = subscription
    }

    /// Nothing on the server outlives its connection.
    mutating func connectionEnded() {
        confirmed = nil
        pending = nil
        tradesCoin = nil
    }

    /// What to send now to move the server towards `wanted`, recorded as in flight.
    mutating func nextRequests() -> [Request] {
        var requests = nextTradesRequests()
        if let book = nextBookRequest() { requests.insert(book, at: 0) }
        return requests
    }

    private mutating func nextBookRequest() -> Request? {
        guard pending == nil, confirmed != wanted else { return nil }
        if let confirmed {
            pending = .unsubscribe(confirmed)
        } else if let wanted {
            pending = .subscribe(wanted)
        }
        return pending
    }

    private mutating func nextTradesRequests() -> [Request] {
        guard let coin = wanted?.coin, coin != tradesCoin else { return [] }
        defer { tradesCoin = coin }
        return (tradesCoin.map { [.unsubscribeTrades(coin: $0)] } ?? []) + [.subscribeTrades(coin: coin)]
    }

    mutating func didSubscribe(_ subscription: BookSubscription) {
        if pending == .subscribe(subscription) { pending = nil }
        confirmed = subscription
    }

    mutating func didUnsubscribe(_ subscription: BookSubscription) {
        if pending == .unsubscribe(subscription) { pending = nil }
        if confirmed == subscription { confirmed = nil }
    }

    /// The request in flight was refused or never sent.
    mutating func requestFailed() {
        pending = nil
    }
}
