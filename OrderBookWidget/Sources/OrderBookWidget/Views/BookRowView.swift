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
        // The flash sits behind the text so a burst of updates never makes prices harder to read.
        .background {
            Rectangle()
                .fill(flashTint)
                // Shorter than the feed's 0.5 s push interval, so a busy level reads as a series
                // of pulses rather than a permanent tint.
                .keyframeAnimator(initialValue: 0.0, trigger: flashTrigger) { flash, opacity in
                    flash.opacity(opacity)
                } keyframes: { _ in
                    LinearKeyframe(0.3, duration: 0.04)
                    LinearKeyframe(0, duration: 0.36, timingCurve: .easeOut)
                }
                .allowsHitTesting(false)
        }
        .background { DepthBar(fraction: level.depthFraction, tint: side.tint) }
        .onChange(of: level.flashToken) { flash() }
        .onAppear {
            if level.change == .new, level.flashToken > 0 { flash() }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(side.name) \(level.labels.price), size \(level.label(size: unit)), total \(level.label(total: unit))")
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
