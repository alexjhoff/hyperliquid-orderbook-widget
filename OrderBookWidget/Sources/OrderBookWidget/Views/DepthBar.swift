import SwiftUI

/// Cumulative depth behind a row, growing from the leading edge. A small inset leaves a gap between
/// neighbouring bars, so each level reads as its own bar.
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
            .scaleEffect(x: fraction, y: 1, anchor: .leading)
            .padding(.vertical, Spacing.hairline)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

#if DEBUG
    #Preview {
        DepthBar(fraction: 0.6, tint: .bid)
            .frame(height: Layout.rowHeight)
    }
#endif
