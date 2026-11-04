import Foundation

/// One websocket connection. `URLSessionSocket` is the real one; tests script their own.
protocol SocketTransport: Sendable {
    /// Returns once the handshake has completed.
    func open() async throws
    func send(_ text: String) async throws
    func receive() async throws -> String
    func close() async
}

typealias SocketFactory = @Sendable (URL) -> any SocketTransport

enum SocketError: Error, CustomStringConvertible {
    /// The peer closed the socket. `code` is the websocket close code.
    case closed(code: Int)
    case silent(for: Duration)

    var description: String {
        switch self {
        case .closed(let code): "closed by peer (\(code))"
        case .silent(let duration): "no frames for \(duration)"
        }
    }
}

/// `URLSessionWebSocketTask` behind the protocol. Surfaces the peer's close code, which the task
/// only exposes after `receive` fails.
actor URLSessionSocket: SocketTransport {
    private let task: URLSessionWebSocketTask

    init(url: URL, session: URLSession = .shared) {
        task = session.webSocketTask(with: url)
    }

    func open() async throws {
        task.resume()
        // `send` completes only after the handshake succeeds, so the first ping doubles as the open signal.
        try await task.send(.string(ClientMessage.ping))
    }

    func send(_ text: String) async throws {
        try await task.send(.string(text))
    }

    func receive() async throws -> String {
        do {
            switch try await task.receive() {
            case .string(let text): return text
            case .data(let data): return String(decoding: data, as: UTF8.self)
            @unknown default: return ""
            }
        } catch {
            if task.closeCode != .invalid { throw SocketError.closed(code: task.closeCode.rawValue) }
            throw error
        }
    }

    func close() {
        task.cancel(with: .goingAway, reason: nil)
    }
}
