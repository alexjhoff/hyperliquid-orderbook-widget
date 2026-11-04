import Foundation
import Synchronization

@testable import OrderBookWidget

/// A scripted socket: records what the feed sends and hands it the frames the test pushes.
final class FakeSocket: SocketTransport, Sendable {
    private struct State {
        var sent: [String] = []
        var queued: [Result<String, any Error>] = []
        var waiter: CheckedContinuation<String, any Error>?
        var isClosed = false
        var holdsClose = false
        var closeWaiters: [CheckedContinuation<Void, Never>] = []
    }

    private let state = Mutex(State())

    var sent: [String] { state.withLock { $0.sent } }
    var isClosed: Bool { state.withLock { $0.isClosed } }

    func open() throws {}

    func send(_ text: String) {
        state.withLock { $0.sent.append(text) }
    }

    func receive() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let ready = state.withLock { state -> Result<String, any Error>? in
                if !state.queued.isEmpty { return state.queued.removeFirst() }
                if state.isClosed { return .failure(SocketError.closed(code: 1000)) }
                state.waiter = continuation
                return nil
            }
            if let ready { continuation.resume(with: ready) }
        }
    }

    func close() async {
        deliver(.failure(SocketError.closed(code: 1000)), closing: true)
        await withCheckedContinuation { continuation in
            let held = state.withLock { state -> Bool in
                if state.holdsClose { state.closeWaiters.append(continuation) }
                return state.holdsClose
            }
            if !held { continuation.resume() }
        }
    }

    /// Makes `close()` suspend until `releaseClose()`, like a slow teardown.
    func holdClose() {
        state.withLock { $0.holdsClose = true }
    }

    func releaseClose() {
        let waiters = state.withLock { state -> [CheckedContinuation<Void, Never>] in
            state.holdsClose = false
            defer { state.closeWaiters = [] }
            return state.closeWaiters
        }
        for waiter in waiters { waiter.resume() }
    }

    /// A frame from the server.
    func push(_ text: String) {
        deliver(.success(text), closing: false)
    }

    /// The server dropped the connection.
    func drop() {
        deliver(.failure(SocketError.closed(code: 1006)), closing: false)
    }

    private func deliver(_ result: Result<String, any Error>, closing: Bool) {
        let waiter = state.withLock { state -> CheckedContinuation<String, any Error>? in
            if closing { state.isClosed = true }
            if let waiter = state.waiter {
                state.waiter = nil
                return waiter
            }
            state.queued.append(result)
            return nil
        }
        waiter?.resume(with: result)
    }
}

/// Hands the feed a fresh socket per connection and keeps them for the test to inspect.
final class FakeSockets: Sendable {
    private let made = Mutex<[FakeSocket]>([])

    var all: [FakeSocket] { made.withLock { $0 } }

    func make(_ url: URL) -> any SocketTransport {
        let socket = FakeSocket()
        made.withLock { $0.append(socket) }
        return socket
    }
}
