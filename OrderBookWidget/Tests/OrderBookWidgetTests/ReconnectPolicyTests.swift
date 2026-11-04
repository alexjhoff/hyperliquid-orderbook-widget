import Testing

@testable import OrderBookWidget

struct ReconnectPolicyTests {
    let policy = ReconnectPolicy()

    @Test func doublesFromHalfASecondUpToTheCap() {
        let delays = (1...7).map { policy.delay(forAttempt: $0, jitter: 1) }
        #expect(delays == [.milliseconds(500), .seconds(1), .seconds(2), .seconds(4), .seconds(8), .seconds(10), .seconds(10)])
    }

    @Test func jitterScalesTheDelayWithinBounds() {
        #expect(policy.delay(forAttempt: 2, jitter: 0.5) == .milliseconds(500))
        #expect(policy.delay(forAttempt: 2, jitter: 0) == .milliseconds(500), "jitter never goes below half")
        #expect(policy.delay(forAttempt: 2, jitter: 5) == .seconds(1), "or above the full delay")
    }

    @Test func pingsBeforeTheServerWouldClose() {
        #expect(policy.pingInterval < .seconds(60))
        #expect(policy.receiveTimeout > policy.pingInterval)
    }
}
