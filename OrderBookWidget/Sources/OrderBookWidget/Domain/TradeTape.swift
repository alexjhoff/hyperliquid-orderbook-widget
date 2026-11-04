/// The most recent trades, newest first, with nothing shown twice. Pure, so the view model holds one
/// and tests drive it directly.
struct TradeTape: Equatable, Sendable {
    /// More than a screenful, so the list scrolls, without growing for as long as the app runs.
    static let capacity = 50

    private(set) var trades: [Trade] = []

    /// - Parameter batch: oldest first, as the server sends it. A reconnect's snapshot overlaps what
    ///   is already here, so anything seen before is dropped.
    mutating func append(_ batch: [Trade]) {
        var seen = Set(trades.map(\.id))
        let fresh = batch.reversed().filter { seen.insert($0.id).inserted }
        guard !fresh.isEmpty else { return }
        trades = Array((fresh + trades).prefix(Self.capacity))
    }

    mutating func reset() {
        trades = []
    }
}
