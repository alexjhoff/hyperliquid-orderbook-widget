import SwiftUI

/// A single price level. Equatable on its inputs, so SwiftUI skips `body` for rows whose level
/// did not change. A change flashes the row: green for more size, red for less, white for a
/// new level.
struct BookRowView: View, Equatable {
    let level: BookLevel
    let side: Side
    let unit: SizeUnit
    let height: CGFloat

    @State private var flashTrigger = 0
    @State private var flashTint = Color.clear
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.level == rhs.level && lhs.side == rhs.side && lhs.unit == rhs.unit && lhs.height == rhs.height
    }

    var body: some View {
        HStack(spacing: Spacing.m) {
            Text(verbatim: level.labels.price)
                .foregroundStyle(side.tint)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(verbatim: level.label(size: unit))
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(verbatim: level.label(total: unit))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(.footnote.monospacedDigit())
        .lineLimit(1)
        .minimumScaleFactor(Layout.minimumTextScale)
        .padding(.horizontal, Spacing.l)
        .frame(height: height)
        // The flash sits behind the text so a burst of updates never makes prices harder to read.
        .background {
            Rectangle()
                .fill(flashTint)
                .keyframeAnimator(initialValue: 0.0, trigger: flashTrigger) { flash, opacity in
                    flash.opacity(opacity)
                } keyframes: { _ in
                    LinearKeyframe(Opacity.flashPeak, duration: Motion.flashIn)
                    LinearKeyframe(0, duration: Motion.flashOut, timingCurve: .easeOut)
                }
                .allowsHitTesting(false)
        }
        .background { DepthBar(fraction: level.depthFraction, tint: side.tint) }
        .onChange(of: level.flashToken) { flash() }
        .onAppear {
            if level.change == .new, level.flashToken > 0 { flash() }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            Text("\(side.name) \(level.labels.price), size \(level.label(size: unit)), total \(level.label(total: unit))", bundle: .module))
    }

    private func flash() {
        guard !reduceMotion else { return }
        flashTint =
            switch level.change {
            case .increased: .bid
            case .decreased: .ask
            case .new: .primary
            case .unchanged: .clear
            }
        flashTrigger &+= 1
    }
}

/// Keeps the layout fixed while a side has fewer levels than slots.
struct EmptyRow: View {
    let height: CGFloat

    var body: some View {
        HStack {
            Text(verbatim: BookFormatter.placeholder).frame(maxWidth: .infinity, alignment: .leading)
            Text(verbatim: BookFormatter.placeholder).frame(maxWidth: .infinity, alignment: .trailing)
            Text(verbatim: BookFormatter.placeholder).frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(.footnote)
        .foregroundStyle(.quaternary)
        .padding(.horizontal, Spacing.l)
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

#if DEBUG
    #Preview {
        VStack(spacing: 0) {
            BookRowView(level: BookSnapshot.preview.asks[0], side: .ask, unit: .coin, height: Layout.rowHeight)
            BookRowView(level: BookSnapshot.preview.bids[0], side: .bid, unit: .usd, height: Layout.rowHeight)
            EmptyRow(height: Layout.rowHeight)
        }
    }
#endif
