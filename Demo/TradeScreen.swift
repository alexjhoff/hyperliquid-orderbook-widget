import OrderBookWidget
import SwiftUI

/// A mock trade page that hosts the widget as a card, the way a trading app would.
struct TradeScreen: View {
    /// The last deep link. Every link, even one for the market already shown, rebuilds the
    /// widget, so identity comes from the link itself rather than its symbol.
    @State private var link: DeepLink?

    var body: some View {
        VStack(spacing: 12) {
            MarketHeader()
            OrderBookWidget(symbol: link?.symbol)
                .id(link?.id)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 16))
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .background(Color(uiColor: .systemGroupedBackground))
        .onOpenURL { url in
            if let symbol = DeepLinkRouter.symbol(from: url) { link = DeepLink(symbol: symbol) }
        }
    }
}

private struct DeepLink {
    let symbol: Symbol
    let id = UUID()
}

private struct MarketHeader: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Hyperliquid")
                    .font(.headline)
                Text("Perpetuals · live order book")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("10×")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(uiColor: .tertiarySystemGroupedBackground), in: .rect(cornerRadius: 8))
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
    }
}

#Preview {
    TradeScreen()
}
