#if DEBUG
    import Foundation

    extension BookSnapshot {
        /// A fixed BTC book for previews, in the app and in the Home Screen widget.
        public static let preview: BookSnapshot = {
            var builder = SnapshotBuilder()
            let levels = (0..<BookListView.depth).map { offset in
                (bid: WireLevel(px: "\(77_719 - offset).0", sz: "\(Double(offset + 1) * 0.7)", n: 1),
                 ask: WireLevel(px: "\(77_720 + offset).0", sz: "\(Double(offset + 1) * 0.5)", n: 1))
            }
            let book = WireBook(coin: "BTC", time: 0, levels: [levels.map(\.bid), levels.map(\.ask)])
            return builder.build(from: book, subscription: BookSubscription(coin: "BTC", nSigFigs: nil), receivedAt: .now)!
        }()
    }

    /// A synthetic market for previews: a book that drifts and churns every half second.
    actor PreviewFeed: OrderBookFeed {
        private var sink: AsyncStream<FeedEvent>.Continuation?
        private var ticker: Task<Void, Never>?
        private var builder = SnapshotBuilder()
        private var mid = 77_720.0

        func events() -> AsyncStream<FeedEvent> {
            let (stream, continuation) = AsyncStream.makeStream(of: FeedEvent.self)
            sink = continuation
            return stream
        }

        func subscribe(_ subscription: BookSubscription) {
            ticker?.cancel()
            builder.reset()
            sink?.yield(.status(.connected))
            ticker = Task {
                while !Task.isCancelled {
                    tick(subscription)
                    try? await Task.sleep(for: .milliseconds(500))
                }
            }
        }

        func disconnect() {
            ticker?.cancel()
            sink?.yield(.status(.disconnected))
        }

        private func tick(_ subscription: BookSubscription) {
            mid += Double.random(in: -2...2)
            let tick = subscription.nSigFigs.map { pow(10, Double(5 - $0)) } ?? 1
            let base = (mid / tick).rounded() * tick
            func level(_ offset: Int) -> (String, String) {
                (String(format: "%.1f", base + Double(offset) * tick), String(format: "%.5f", Double.random(in: 0.1...8)))
            }
            let book = WireBook(
                coin: subscription.coin,
                time: Int64(Date.now.timeIntervalSince1970 * 1000),
                levels: [
                    (0..<BookListView.depth).map { let l = level(-$0); return WireLevel(px: l.0, sz: l.1, n: 1) },
                    (1...BookListView.depth).map { let l = level($0); return WireLevel(px: l.0, sz: l.1, n: 1) },
                ]
            )
            if let snapshot = builder.build(from: book, subscription: subscription, receivedAt: .now) {
                sink?.yield(.book(snapshot))
            }
        }
    }
#endif
