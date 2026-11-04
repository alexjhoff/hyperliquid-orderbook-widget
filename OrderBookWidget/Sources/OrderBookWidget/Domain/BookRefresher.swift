import Foundation

/// One Home Screen widget refresh: fetch a book and decide when to try again. Lives here rather
/// than in the extension so it can be tested with a fake fetcher.
public struct BookRefresher: Sendable {
    public struct Result: Sendable {
        /// Nil when the fetch failed.
        public let snapshot: BookSnapshot?
        public let nextRefresh: Date
    }

    static let interval: TimeInterval = 15 * 60
    static let intervalAfterFailure: TimeInterval = 5 * 60

    private let fetcher: any BookSnapshotFetching

    public init(fetcher: any BookSnapshotFetching) {
        self.fetcher = fetcher
    }

    public func refresh(_ subscription: BookSubscription, now: Date = .now) async -> Result {
        do {
            let snapshot = try await fetcher.fetch(subscription)
            return Result(snapshot: snapshot, nextRefresh: now.addingTimeInterval(Self.interval))
        } catch {
            Log.widget.error("Fetch failed: \(String(describing: error), privacy: .public)")
            return Result(snapshot: nil, nextRefresh: now.addingTimeInterval(Self.intervalAfterFailure))
        }
    }
}
