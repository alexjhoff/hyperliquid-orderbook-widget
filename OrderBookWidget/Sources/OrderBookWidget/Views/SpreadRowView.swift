import SwiftUI

/// The centre line: mid price with its last direction, and the spread in price and basis points.
struct SpreadRowView: View {
    let book: BookSnapshot?

    var body: some View {
        let trend = book?.trend ?? .flat
        let tint: Color =
            switch trend {
            case .up: .bid
            case .down: .ask
            case .flat: .primary
            }

        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(book?.midLabel ?? "–")
                .font(.title3.weight(.semibold).monospacedDigit())
                .foregroundStyle(tint)
                .contentTransition(.numericText(value: book?.mid ?? 0))
                .animation(.snappy, value: book?.mid)
            Image(systemName: trend == .down ? "arrow.down" : "arrow.up")
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
                .opacity(trend == .flat ? 0 : 1)
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 1) {
                Text("Spread")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(book?.spreadLabel ?? "–") · \(book?.spreadBpsLabel ?? "–") bps")
                    .font(.caption.monospacedDigit())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.06))
        .contentShape(.rect)
    }
}
