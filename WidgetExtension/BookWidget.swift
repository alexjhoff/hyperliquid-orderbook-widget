import OrderBookWidget
import SwiftUI
import WidgetKit

struct BookWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "com.alexhoff.OrderBookWidget.book",
            intent: BookConfiguration.self,
            provider: BookTimelineProvider(fetcher: HyperliquidInfoClient())
        ) { entry in
            BookEntryView(entry: entry)
        }
        .configurationDisplayName("Order Book")
        .description("Top of the Hyperliquid book, refreshed every 15 minutes.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#if DEBUG
    #Preview(as: .systemMedium) {
        BookWidget()
    } timeline: {
        BookEntry(date: .now, symbol: .btc, snapshot: .preview)
        BookEntry(date: .now, symbol: .btc, snapshot: nil)
    }
#endif
