import SwiftUI

/// A single price level. Equatable on its inputs, so SwiftUI skips `body` for rows whose level
/// did not change.
struct BookRowView: View, Equatable {
    let level: BookLevel
    let side: Side
    let unit: SizeUnit
    let height: CGFloat

    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.level == rhs.level && lhs.side == rhs.side && lhs.unit == rhs.unit && lhs.height == rhs.height
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(level.labels.price)
                .foregroundStyle(side.tint)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(level.label(size: unit))
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(level.label(total: unit))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(.footnote.monospacedDigit())
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .padding(.horizontal, 12)
        .frame(height: height)
        .background { DepthBar(fraction: level.depthFraction, tint: side.tint) }
    }
}

/// Keeps the layout fixed while a side has fewer levels than slots.
struct EmptyRow: View {
    let height: CGFloat

    var body: some View {
        HStack {
            Text("–").frame(maxWidth: .infinity, alignment: .leading)
            Text("–").frame(maxWidth: .infinity, alignment: .trailing)
            Text("–").frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(.footnote)
        .foregroundStyle(.quaternary)
        .padding(.horizontal, 12)
        .frame(height: height)
        .accessibilityHidden(true)
    }
}
