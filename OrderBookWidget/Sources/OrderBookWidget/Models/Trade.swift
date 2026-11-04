/// Pre-formatted strings for one trade, built off the main thread so views never format numbers.
public struct TradeLabels: Equatable, Sendable {
    public let price: String
    public let size: String
    public let sizeUSD: String
    public let time: String
}

/// One executed trade, fully computed before it reaches a view.
public struct Trade: Identifiable, Equatable, Sendable {
    /// Hyperliquid's `tid`. Unique, but not ordered.
    public let id: Int64
    public let coin: String
    /// The taker's side: `.bid` bought, `.ask` sold.
    public let side: Side
    public let labels: TradeLabels

    func label(size unit: SizeUnit) -> String {
        unit == .coin ? labels.size : labels.sizeUSD
    }
}
