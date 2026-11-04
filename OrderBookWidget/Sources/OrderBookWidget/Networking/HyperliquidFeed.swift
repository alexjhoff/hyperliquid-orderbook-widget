import Foundation

/// Hyperliquid `l2Book` feed over one socket: reconnects with backoff, keeps the socket alive,
/// and reconciles the one subscription the consumer wants with what the server has confirmed.
///
/// Book frames do not say which grouping they carry, so they are admitted only when `confirmed`
/// equals `wanted` and no request is in flight. A change therefore unsubscribes the old grouping,
/// waits for the ack, then subscribes the new one.
actor HyperliquidFeed: OrderBookFeed {
    static let url = URL(string: "wss://api.hyperliquid.xyz/ws")!

    private let url: URL
    private let policy: ReconnectPolicy
    private let clock: any Clock<Duration>
    private let makeSocket: SocketFactory
    private var builder = SnapshotBuilder()

    private var sink: AsyncStream<FeedEvent>.Continuation?
    private var connection: Task<Void, Never>?
    private var socket: (any SocketTransport)?
    private var isOpen = false
    /// Time since the last inbound frame and the last outbound one, advanced by the heartbeat.
    private var silence: Duration = .zero
    private var sinceLastSend: Duration = .zero

    private var wanted: BookSubscription?
    private var confirmed: BookSubscription?
    private var pending: Request?

    private enum Request: Equatable {
        case subscribe(BookSubscription)
        case unsubscribe(BookSubscription)
    }

    init(
        url: URL = HyperliquidFeed.url,
        policy: ReconnectPolicy = ReconnectPolicy(),
        clock: any Clock<Duration>,
        makeSocket: @escaping SocketFactory = { URLSessionSocket(url: $0) }
    ) {
        self.url = url
        self.policy = policy
        self.clock = clock
        self.makeSocket = makeSocket
    }

    /// The connection task retains the feed while it runs, so a feed is only released after
    /// `disconnect()`; the view model calls it when its event loop ends.
    isolated deinit {
        sink?.finish()
    }

    // MARK: - OrderBookFeed

    func events() -> AsyncStream<FeedEvent> {
        sink?.finish()
        let (stream, continuation) = AsyncStream.makeStream(of: FeedEvent.self)
        sink = continuation
        return stream
    }

    func subscribe(_ subscription: BookSubscription) async {
        wanted = subscription
        Log.feed.info("Want \(subscription, privacy: .public)")
        if connection == nil {
            connection = Task { await self.maintainConnection() }
        } else {
            await reconcile()
        }
    }

    func disconnect() async {
        guard let connection else { return }
        connection.cancel()
        self.connection = nil
        let closing = socket
        socket = nil
        isOpen = false
        confirmed = nil
        pending = nil
        Log.feed.info("Disconnected by client")
        emit(.status(.disconnected))
        // Last, because this suspends: a subscribe that lands here starts a new connection, and
        // nothing above may run after it.
        await closing?.close()
    }

    // MARK: - Connection

    private func maintainConnection() async {
        var attempt = 0
        while !Task.isCancelled {
            emit(.status(.connecting))
            let socket = makeSocket(url)
            self.socket = socket
            do {
                try await socket.open()
                try Task.checkCancellation()
                attempt = 0
                isOpen = true
                silence = .zero
                sinceLastSend = .zero
                Log.feed.info("Connected to \(self.url.host() ?? "", privacy: .public)")
                emit(.status(.connected))
                await reconcile()
                try await withThrowingTaskGroup(of: Void.self) { group in
                    group.addTask { try await self.receiveLoop(socket) }
                    group.addTask { try await self.heartbeatLoop(socket) }
                    var failure: (any Error)?
                    do { try await group.next() } catch { failure = error }
                    group.cancelAll()
                    // Close before the group waits for its children, so a blocked receive returns.
                    await socket.close()
                    if let failure { throw failure }
                }
            } catch is CancellationError {
                // disconnect() was called.
            } catch {
                // A cancelled connection fails its socket calls on the way out; that is not a loss.
                if !Task.isCancelled {
                    Log.feed.error("Connection lost: \(String(describing: error), privacy: .public)")
                }
            }

            await socket.close()
            // disconnect() already reset the state, and a newer connection may own it by now.
            guard !Task.isCancelled else { return }
            isOpen = false
            confirmed = nil
            pending = nil

            attempt += 1
            let delay = policy.delay(forAttempt: attempt, jitter: .random(in: policy.jitterRange))
            Log.feed.info("Reconnect attempt \(attempt) in \(delay, privacy: .public)")
            emit(.status(.reconnecting(attempt: attempt, delay: delay)))
            try? await clock.sleep(for: delay)
        }
    }

    private func receiveLoop(_ socket: any SocketTransport) async throws {
        while true {
            let text = try await socket.receive()
            // A frame from a socket being replaced must not touch the new connection's state.
            try Task.checkCancellation()
            silence = .zero
            await handle(text)
        }
    }

    private func heartbeatLoop(_ socket: any SocketTransport) async throws {
        while true {
            try await clock.sleep(for: policy.checkInterval)
            silence += policy.checkInterval
            sinceLastSend += policy.checkInterval
            if silence >= policy.receiveTimeout {
                throw SocketError.silent(for: policy.receiveTimeout)
            }
            if sinceLastSend >= policy.pingInterval {
                try await send(ClientMessage.ping, over: socket)
            }
        }
    }

    private func send(_ text: String, over socket: any SocketTransport) async throws {
        try await socket.send(text)
        sinceLastSend = .zero
    }

    private func emit(_ event: FeedEvent) {
        sink?.yield(event)
    }

    // MARK: - Subscriptions

    /// Brings the server's subscription in line with `wanted`, one request at a time.
    private func reconcile() async {
        guard isOpen, let socket, pending == nil, confirmed != wanted else { return }
        let request: Request
        if let confirmed {
            request = .unsubscribe(confirmed)
        } else if let wanted {
            request = .subscribe(wanted)
        } else {
            return
        }
        pending = request
        let text =
            switch request {
            case .subscribe(let subscription): ClientMessage.subscribe(subscription)
            case .unsubscribe(let subscription): ClientMessage.unsubscribe(subscription)
            }
        do {
            try await send(text, over: socket)
        } catch {
            Log.feed.error("Send failed: \(String(describing: error), privacy: .public)")
            pending = nil
        }
    }

    private func handle(_ text: String) async {
        let message: ServerMessage
        do {
            message = try ServerMessage.decode(text)
        } catch {
            Log.feed.error("Undecodable frame: \(text.prefix(120), privacy: .public)")
            return
        }

        switch message {
        case .book(let book):
            guard let wanted, pending == nil, confirmed == wanted, book.coin == wanted.coin else { return }
            if let snapshot = builder.build(from: book, subscription: wanted, receivedAt: .now) {
                emit(.book(snapshot))
            }
        case .subscribed(let subscription):
            Log.feed.info("Subscribed \(subscription, privacy: .public)")
            if pending == .subscribe(subscription) { pending = nil }
            confirmed = subscription
            builder.reset()
            await reconcile()
        case .unsubscribed(let subscription):
            Log.feed.info("Unsubscribed \(subscription, privacy: .public)")
            if pending == .unsubscribe(subscription) { pending = nil }
            if confirmed == subscription { confirmed = nil }
            await reconcile()
        case .pong:
            break
        case .error(let message):
            // Only documented groupings are ever requested, so this is logged rather than retried.
            Log.feed.error("Server error: \(message, privacy: .public)")
            pending = nil
        case .other(let channel):
            Log.feed.debug("Ignored channel \(channel, privacy: .public)")
        }
    }
}
