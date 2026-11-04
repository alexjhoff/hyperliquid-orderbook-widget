import OrderBookWidget
import SwiftUI
import WidgetKit

/// A glance at the top of the book: a few asks, the mid and spread, a few bids, and when it was taken.
struct BookEntryView: View {
    let entry: BookEntry
    @Environment(\.widgetFamily) private var family

    private var rowsPerSide: Int {
        switch family {
        case .systemSmall: 3
        case .systemMedium: 5
        default: 8
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack {
                Text(verbatim: entry.symbol.pair)
                    .font(.caption.weight(.semibold))
                Spacer()
                Text(entry.date, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, Spacing.xxs)
            if let book = entry.snapshot {
                ForEach(book.asks.prefix(rowsPerSide).reversed()) { row($0, side: .ask) }
                HStack(alignment: .firstTextBaseline) {
                    Text(verbatim: book.midLabel)
                        .font(.footnote.weight(.semibold).monospacedDigit())
                    Spacer()
                    spreadText(book)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, Spacing.xxs)
                ForEach(book.bids.prefix(rowsPerSide)) { row($0, side: .bid) }
            } else {
                Spacer()
                Text("Couldn't reach Hyperliquid")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
        .widgetURL(DeepLink.url(for: entry.symbol))
    }

    private func spreadText(_ book: BookSnapshot) -> Text {
        family == .systemSmall ? Text(verbatim: book.spreadLabel) : Text("\(book.spreadLabel) · \(book.spreadBpsLabel) bps")
    }

    private func row(_ level: BookLevel, side: Side) -> some View {
        HStack {
            Text(verbatim: level.labels.price).foregroundStyle(side.tint)
            Spacer()
            Text(verbatim: level.labels.size)
        }
        .font(.caption2.monospacedDigit())
        .lineLimit(1)
        .padding(.horizontal, Spacing.xs)
        .background { DepthBar(fraction: level.depthFraction, tint: side.tint) }
    }
}
