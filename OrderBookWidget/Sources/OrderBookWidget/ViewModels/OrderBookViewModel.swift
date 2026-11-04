import Foundation
import Observation

/// Main-actor state for the widget. Receives finished snapshots from the feed and assigns them;
/// all parsing, formatting and diffing already happened off the main thread.
@MainActor
@Observable
final class OrderBookViewModel {
    var symbol: Symbol {
        didSet {
            guard symbol != oldValue else { return }
            store.symbol = symbol
            resubscribe()
        }
    }

    var precision: Precision {
        didSet {
            guard precision != oldValue else { return }
            store.precision = precision
            resubscribe()
        }
    }

    var sizeUnit: SizeUnit {
        didSet { store.sizeUnit = sizeUnit }
    }

    private(set) var book: BookSnapshot?
    private(set) var status: ConnectionStatus = .disconnected
    /// When `status` last changed. The header counts down a reconnect delay from here.
    private(set) var statusChangedAt = Date()

    @ObservationIgnored private let feed: any OrderBookFeed
    @ObservationIgnored private let store: any SelectionStoring

    init(feed: any OrderBookFeed, selections: any SelectionStoring) {
        self.feed = feed
        store = selections
        symbol = selections.symbol ?? .btc
        precision = selections.precision ?? .full
        sizeUnit = selections.sizeUnit ?? .coin
    }

    /// What the widget wants to be streaming right now.
    var subscription: BookSubscription {
        BookSubscription(symbol: symbol, precision: precision)
    }

    /// True while the book on screen is not the one the user asked for, or the feed is down.
    var isStale: Bool {
        book?.subscription != subscription || status != .connected
    }

    /// Connects and applies events until cancelled. Call from `.task`.
    func run() async {
        let events = await feed.events()
        await feed.subscribe(subscription)
        for await event in events {
            apply(event)
        }
    }

    /// Scene went to the background: drop the socket instead of letting the OS kill it.
    func disconnect() async {
        await feed.disconnect()
    }

    /// Scene is active again.
    func reconnect() async {
        await feed.subscribe(subscription)
    }

    // MARK: - Private

    private func resubscribe() {
        Log.model.info("Selection changed to \(self.subscription, privacy: .public)")
        let feed = feed
        let subscription = subscription
        Task { await feed.subscribe(subscription) }
    }

    private func apply(_ event: FeedEvent) {
        switch event {
        case .status(let status):
            self.status = status
            statusChangedAt = .now
        case .book(let snapshot):
            // A late frame from a superseded symbol or grouping is never shown.
            guard snapshot.subscription == subscription else { return }
            book = snapshot
        }
    }
}
