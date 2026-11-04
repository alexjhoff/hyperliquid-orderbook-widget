import OrderBookWidget
import SwiftUI

/// A mock trade page that hosts the widget as a card, the way a trading app would.
struct TradeScreen: View {
    /// The last deep link. Every link, even one for the market already shown, rebuilds the
    /// widget, so identity comes from the link itself rather than its symbol.
    @State private var link: OpenedLink?

    var body: some View {
        VStack(spacing: Spacing.l) {
            MarketHeader()
            OrderBookWidget(symbol: link?.symbol)
                .id(link?.id)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: Radius.card))
        }
        .padding(.horizontal, Spacing.l)
        .padding(.bottom, Spacing.m)
        .background(Color(uiColor: .systemGroupedBackground))
        .onOpenURL { url in
            if let symbol = DeepLink.symbol(from: url) { link = OpenedLink(symbol: symbol) }
        }
    }
}

private struct OpenedLink {
    let symbol: Symbol
    let id = UUID()
}

private struct MarketHeader: View {
    /// A mock value: the demo has no account or positions.
    private static let leverageLabel = "10×"
    private static let icon = "chart.line.uptrend.xyaxis.circle.fill"

    var body: some View {
        HStack(spacing: Spacing.l) {
            Image(systemName: Self.icon)
                .font(.largeTitle)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Hyperliquid")
                    .font(.headline)
                Text("Perpetuals · live order book")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(verbatim: Self.leverageLabel)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, Spacing.m)
                .padding(.vertical, Spacing.s)
                .background(Color(uiColor: .tertiarySystemGroupedBackground), in: .rect(cornerRadius: Radius.badge))
        }
        .padding(Spacing.xl)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: .rect(cornerRadius: Radius.card))
    }
}

#Preview {
    TradeScreen()
}
