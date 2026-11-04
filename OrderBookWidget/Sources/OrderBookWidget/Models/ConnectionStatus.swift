public enum ConnectionStatus: Equatable, Sendable {
    case connecting
    case connected
    case reconnecting(attempt: Int, delay: Duration)
    case disconnected
}
