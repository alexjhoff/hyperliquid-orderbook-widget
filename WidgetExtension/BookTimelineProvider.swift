import OrderBookWidget
import WidgetKit

/// Bridges WidgetKit to `BookRefresher`, which fetches the book and picks the next refresh time.
struct BookTimelineProvider: AppIntentTimelineProvider {
    let refresher: BookRefresher

    func placeholder(in context: Context) -> BookEntry {
        BookEntry(date: .now, symbol: .btc, snapshot: nil)
    }

    func snapshot(for configuration: BookConfiguration, in context: Context) async -> BookEntry {
        let result = await refresh(configuration)
        return BookEntry(date: .now, symbol: configuration.market.symbol, snapshot: result.snapshot)
    }

    func timeline(for configuration: BookConfiguration, in context: Context) async -> Timeline<BookEntry> {
        let result = await refresh(configuration)
        let entry = BookEntry(date: .now, symbol: configuration.market.symbol, snapshot: result.snapshot)
        return Timeline(entries: [entry], policy: .after(result.nextRefresh))
    }

    private func refresh(_ configuration: BookConfiguration) async -> BookRefresher.Result {
        await refresher.refresh(BookSubscription(symbol: configuration.market.symbol, precision: configuration.grouping.precision))
    }
}
