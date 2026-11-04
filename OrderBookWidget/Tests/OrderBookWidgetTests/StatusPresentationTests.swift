import Testing

@testable import OrderBookWidget

struct StatusPresentationTests {
    @Test func liveUntilTheBookGoesQuiet() {
        #expect(StatusPresentation(status: .connected, bookAge: nil, statusAge: 0).label == "Live")
        #expect(StatusPresentation(status: .connected, bookAge: 1, statusAge: 0).tone == .live)
        #expect(StatusPresentation(status: .connected, bookAge: 7.6, statusAge: 0).label == "7s ago")
        #expect(StatusPresentation(status: .connected, bookAge: 20, statusAge: 0).tone == .quiet)
    }

    @Test func countsDownToTheNextRetry() {
        let retrying = ConnectionStatus.reconnecting(attempt: 3, delay: .seconds(4))
        #expect(StatusPresentation(status: retrying, bookAge: nil, statusAge: 1.2).label == "Retry in 3s · #3")
        #expect(StatusPresentation(status: .reconnecting(attempt: 1, delay: .seconds(1)), bookAge: nil, statusAge: 0).label == "Retry in 1s")
        #expect(StatusPresentation(status: retrying, bookAge: nil, statusAge: 3.8).label == "Reconnecting")
        #expect(StatusPresentation(status: .disconnected, bookAge: nil, statusAge: 0).tone == .offline)
    }
}
