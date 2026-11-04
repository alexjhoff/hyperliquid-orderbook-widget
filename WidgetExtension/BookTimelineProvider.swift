import OrderBookWidget
import WidgetKit

/// Fetches one book per refresh. WidgetKit decides when; this asks for 15 minutes between
/// snapshots, or 5 after a failure.
struct BookTimelineProvider: AppIntentTimelineProvider {
    let fetcher: any BookSnapshotFetching

    private enum Refresh {
        static let interval: TimeInterval = 15 * 60
        static let afterFailure: TimeInterval = 5 * 60
    }

    func placeholder(in context: Context) -> BookEntry {
        BookEntry(date: .now, symbol: .btc, snapshot: nil)
    }

    func snapshot(for configuration: BookConfiguration, in context: Context) async -> BookEntry {
        await entry(symbol: configuration.market.symbol, precision: configuration.grouping.precision)
    }

    func timeline(for configuration: BookConfiguration, in context: Context) async -> Timeline<BookEntry> {
        let entry = await entry(symbol: configuration.market.symbol, precision: configuration.grouping.precision)
        let refresh = Date.now.addingTimeInterval(entry.snapshot == nil ? Refresh.afterFailure : Refresh.interval)
        return Timeline(entries: [entry], policy: .after(refresh))
    }

    private func entry(symbol: Symbol, precision: Precision) async -> BookEntry {
        do {
            let snapshot = try await fetcher.fetch(BookSubscription(symbol: symbol, precision: precision))
            return BookEntry(date: .now, symbol: symbol, snapshot: snapshot)
        } catch {
            Log.widget.error("Fetch failed: \(String(describing: error), privacy: .public)")
            return BookEntry(date: .now, symbol: symbol, snapshot: nil)
        }
    }
}
