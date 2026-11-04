import Foundation

/// Animation timings, in seconds. Every animated view also honours Reduce Motion.
public enum Motion {
    /// A flash rises fast and fades well inside the feed's half-second push interval, so a busy
    /// level reads as pulses rather than a permanent tint.
    public static let flashIn: TimeInterval = 0.04
    public static let flashOut: TimeInterval = 0.36
    /// Rows sliding to their new slot when the market moves.
    public static let rowSlide: TimeInterval = 0.28
    /// The book dimming while a new subscription loads.
    public static let staleFade: TimeInterval = 0.2
}
