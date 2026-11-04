import Foundation

public enum PriceTrend: Sendable, Equatable {
    case flat, up, down
}

/// A display-ready order book. Bids and asks are both ordered best price first.
public struct BookSnapshot: Equatable, Sendable {
    /// The subscription this book came from, so a late frame from a superseded symbol or
    /// grouping is never shown.
    public let subscription: BookSubscription
    /// 1-based position within the current subscription. Resets on resubscribe and reconnect.
    public let sequence: UInt64
    public let bids: [BookLevel]
    public let asks: [BookLevel]
    public let mid: Double?
    public let spread: Double?
    public let trend: PriceTrend
    public let midLabel: String
    public let spreadLabel: String
    public let spreadBpsLabel: String
    public let receivedAt: Date

    public func levels(_ side: Side) -> [BookLevel] {
        side == .bid ? bids : asks
    }
}
