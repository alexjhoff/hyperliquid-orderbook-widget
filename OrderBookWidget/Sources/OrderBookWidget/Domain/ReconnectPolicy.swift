/// When to retry and how often to check the socket is alive. Pure, so the schedule is tested
/// without sockets or clocks.
struct ReconnectPolicy: Sendable {
    var base: Duration = .milliseconds(500)
    var cap: Duration = .seconds(10)
    /// Hyperliquid closes sockets that go 60 s without traffic; ping well inside that window.
    var pingInterval: Duration = .seconds(20)
    /// A socket that stays silent this long is treated as dead, which catches half-open connections.
    var receiveTimeout: Duration = .seconds(30)
    var checkInterval: Duration = .seconds(5)
    /// Multiplier applied to each delay so clients do not all retry in the same instant.
    var jitterRange: ClosedRange<Double> = 0.5...1
    /// Caps `1 << exponent` well inside Int.
    private static let maxExponent = 16

    /// - Parameters:
    ///   - attempt: 1 for the first retry.
    ///   - jitter: multiplier in `jitterRange`, randomised by the caller to spread out reconnect storms.
    func delay(forAttempt attempt: Int, jitter: Double) -> Duration {
        let exponent = min(max(attempt - 1, 0), Self.maxExponent)
        return min(base * (1 << exponent), cap) * min(max(jitter, jitterRange.lowerBound), jitterRange.upperBound)
    }
}
