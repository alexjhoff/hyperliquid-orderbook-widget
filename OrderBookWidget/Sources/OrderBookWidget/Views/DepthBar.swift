import SwiftUI

/// Cumulative depth behind a row, anchored to the trailing edge like Hyperliquid's own book.
/// Driven by `scaleEffect`, a render-time transform, so animating it never triggers layout.
struct DepthBar: View {
    let fraction: Double
    let tint: Color

    var body: some View {
        Rectangle()
            .fill(tint.opacity(0.14))
            .scaleEffect(x: fraction, y: 1, anchor: .trailing)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
