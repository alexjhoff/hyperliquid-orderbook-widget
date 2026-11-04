import SwiftUI

/// The centre line: mid price with its last direction, and the spread in price and basis points.
struct SpreadRowView: View {
    let book: BookSnapshot?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let trend = book?.trend ?? .flat
        let tint: Color =
            switch trend {
            case .up: .bid
            case .down: .ask
            case .flat: .primary
            }

        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(verbatim: book?.midLabel ?? BookFormatter.placeholder)
                .font(.title3.weight(.semibold).monospacedDigit())
                .foregroundStyle(tint)
                .contentTransition(reduceMotion ? .identity : .numericText(value: book?.mid ?? 0))
                .animation(reduceMotion ? nil : .snappy, value: book?.mid)
            Image(systemName: trend == .down ? "arrow.down" : "arrow.up")
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
                .opacity(trend == .flat ? 0 : 1)
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 1) {
                Text("Spread", bundle: .module)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(book?.spreadLabel ?? BookFormatter.placeholder) · \(book?.spreadBpsLabel ?? BookFormatter.placeholder) bps", bundle: .module)
                    .font(.caption.monospacedDigit())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.06))
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: accessibilityText))
        .accessibilityHint(Text("Double tap to recentre the book", bundle: .module))
        .accessibilityAddTraits(.isButton)
    }

    private var accessibilityText: String {
        guard let book else { return String(localized: "Loading order book", bundle: .module) }
        return switch book.trend {
        case .up:
            String(localized: "Mid price \(book.midLabel), up, spread \(book.spreadLabel), \(book.spreadBpsLabel) basis points", bundle: .module)
        case .down:
            String(localized: "Mid price \(book.midLabel), down, spread \(book.spreadLabel), \(book.spreadBpsLabel) basis points", bundle: .module)
        case .flat:
            String(localized: "Mid price \(book.midLabel), spread \(book.spreadLabel), \(book.spreadBpsLabel) basis points", bundle: .module)
        }
    }
}
