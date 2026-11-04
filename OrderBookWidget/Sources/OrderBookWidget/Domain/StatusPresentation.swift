import Foundation

/// What the header says about the connection. Liveness stays visible even when prices are not
/// moving: a quiet market reads "3s ago" instead of looking frozen.
struct StatusPresentation: Equatable {
    enum Tone: Equatable {
        case live, quiet, busy, offline
    }

    let label: String
    let tone: Tone

    /// - Parameters:
    ///   - bookAge: seconds since the last snapshot, or nil before the first one.
    ///   - statusAge: seconds since `status` last changed; a retry delay counts down from here.
    init(status: ConnectionStatus, bookAge: TimeInterval?, statusAge: TimeInterval) {
        switch status {
        case .connected:
            if let bookAge, bookAge >= 3 {
                label = "\(Int(bookAge))s ago"
                tone = bookAge >= 15 ? .quiet : .live
            } else {
                label = "Live"
                tone = .live
            }
        case .connecting:
            label = "Connecting"
            tone = .busy
        case .reconnecting(let attempt, let delay):
            let remaining = delay / .seconds(1) - statusAge
            if remaining >= 0.5 {
                let countdown = "Retry in \(Int(remaining.rounded(.up)))s"
                label = attempt > 1 ? "\(countdown) · #\(attempt)" : countdown
            } else {
                label = "Reconnecting"
            }
            tone = .busy
        case .disconnected:
            label = "Offline"
            tone = .offline
        }
    }
}
