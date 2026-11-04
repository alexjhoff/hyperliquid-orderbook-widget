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
                label = String(localized: "\(Int(bookAge))s ago", bundle: .module)
                tone = bookAge >= 15 ? .quiet : .live
            } else {
                label = String(localized: "Live", bundle: .module)
                tone = .live
            }
        case .connecting:
            label = String(localized: "Connecting", bundle: .module)
            tone = .busy
        case .reconnecting(let attempt, let delay):
            let remaining = delay / .seconds(1) - statusAge
            if remaining >= 0.5 {
                let countdown = String(localized: "Retry in \(Int(remaining.rounded(.up)))s", bundle: .module)
                label = attempt > 1 ? String(localized: "\(countdown) · #\(attempt)", bundle: .module) : countdown
            } else {
                label = String(localized: "Reconnecting", bundle: .module)
            }
            tone = .busy
        case .disconnected:
            label = String(localized: "Offline", bundle: .module)
            tone = .offline
        }
    }
}
