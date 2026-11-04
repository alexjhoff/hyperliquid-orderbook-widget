import OrderBookWidget
import WidgetKit
import os

/// Fetches one book per refresh. WidgetKit decides when; this asks for 15 minutes between
/// snapshots, or 5 after a failure.
struct BookTimelineProvider: AppIntentTimelineProvider {
    let fetcher: any BookSnapshotFetching
    private let log = Logger(subsystem: "com.alexhoff.OrderBookWidget", category: "widget")

    func placeholder(in context: Context) -> BookEntry {
        BookEntry(date: .now, symbol: .btc, snapshot: nil)
    }

    func snapshot(for configuration: BookConfiguration, in context: Context) async -> BookEntry {
        await entry(symbol: configuration.market.symbol, precision: configuration.grouping.precision)
    }

    func timeline(for configuration: BookConfiguration, in context: Context) async -> Timeline<BookEntry> {
        let entry = await entry(symbol: configuration.market.symbol, precision: configuration.grouping.precision)
        let refresh = Date.now.addingTimeInterval(entry.snapshot == nil ? 5 * 60 : 15 * 60)
        return Timeline(entries: [entry], policy: .after(refresh))
    }

    private func entry(symbol: Symbol, precision: Precision) async -> BookEntry {
        do {
            let snapshot = try await fetcher.fetch(BookSubscription(symbol: symbol, precision: precision))
            return BookEntry(date: .now, symbol: symbol, snapshot: snapshot)
        } catch {
            log.error("Fetch failed: \(String(describing: error), privacy: .public)")
            return BookEntry(date: .now, symbol: symbol, snapshot: nil)
        }
    }
}
