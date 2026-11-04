public enum LevelChange: Sendable, Equatable {
    case unchanged, new, increased, decreased
}

/// Pre-formatted strings for one level, built off the main thread so views never format numbers.
public struct LevelLabels: Equatable, Sendable {
    public let price: String
    public let size: String
    public let sizeUSD: String
    public let total: String
    public let totalUSD: String
}

/// One aggregated price level, fully computed before it reaches a view.
public struct BookLevel: Identifiable, Equatable, Sendable {
    /// Hyperliquid's price string. Stable across snapshots, so SwiftUI diffs rows in place.
    public let id: String
    public let price: Double
    public let size: Double
    /// Cumulative size from the best price through this level.
    public let total: Double
    /// `total` relative to the deeper side's total, 0...1.
    public let depthFraction: Double
    public let change: LevelChange
    /// Sequence number of the snapshot that last changed this level, or 0 if it has not changed
    /// since the subscription started. Rows flash when this value changes.
    public let flashToken: UInt64
    public let labels: LevelLabels

    func label(size unit: SizeUnit) -> String {
        unit == .coin ? labels.size : labels.sizeUSD
    }

    func label(total unit: SizeUnit) -> String {
        unit == .coin ? labels.total : labels.totalUSD
    }
}
