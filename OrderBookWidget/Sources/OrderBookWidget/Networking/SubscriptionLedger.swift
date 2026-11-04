/// What the server should be streaming against what it has confirmed. Pure bookkeeping: the feed
/// sends what `nextRequests()` returns and reports acks back.
///
/// Book frames do not say which grouping they carry, so they are admitted only when `confirmed`
/// equals `wanted` and no request is in flight. A change therefore unsubscribes the old grouping,
/// waits for the ack, then subscribes the new one.
struct SubscriptionLedger: Sendable {
    enum Request: Equatable, Sendable {
        case subscribe(BookSubscription)
        case unsubscribe(BookSubscription)

        var text: String {
            switch self {
            case .subscribe(let subscription): ClientMessage.subscribe(subscription)
            case .unsubscribe(let subscription): ClientMessage.unsubscribe(subscription)
            }
        }
    }

    private(set) var wanted: BookSubscription?
    private var confirmed: BookSubscription?
    private var pending: Request?

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
    }

    /// What to send now to move the server towards `wanted`, recorded as in flight.
    mutating func nextRequests() -> [Request] {
        guard pending == nil, confirmed != wanted else { return [] }
        let request: Request
        if let confirmed {
            request = .unsubscribe(confirmed)
        } else if let wanted {
            request = .subscribe(wanted)
        } else {
            return []
        }
        pending = request
        return [request]
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
