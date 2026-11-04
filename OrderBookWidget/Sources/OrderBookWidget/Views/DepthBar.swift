import SwiftUI

/// Cumulative depth behind a row, anchored to the trailing edge like Hyperliquid's own book.
/// Driven by `scaleEffect`, a render-time transform, so animating it never triggers layout.
public struct DepthBar: View {
    let fraction: Double
    let tint: Color

    public init(fraction: Double, tint: Color) {
        self.fraction = fraction
        self.tint = tint
    }

    public var body: some View {
        Rectangle()
            .fill(tint.opacity(Opacity.depthBar))
            .scaleEffect(x: fraction, y: 1, anchor: .trailing)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
