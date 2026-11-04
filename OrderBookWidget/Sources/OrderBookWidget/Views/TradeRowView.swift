import SwiftUI

/// One executed trade, coloured by the taker's side. Equatable on its inputs, so SwiftUI skips `body`
/// for rows already on screen when a new trade arrives.
struct TradeRowView: View, Equatable {
    let trade: Trade
    let unit: SizeUnit
    let height: CGFloat

    var body: some View {
        HStack(spacing: Spacing.m) {
            Text(verbatim: trade.labels.price)
                .foregroundStyle(trade.side.tint)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(verbatim: trade.label(size: unit))
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(verbatim: trade.labels.time)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(.footnote.monospacedDigit())
        .lineLimit(1)
        .minimumScaleFactor(Layout.minimumTextScale)
        .padding(.horizontal, Spacing.l)
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: Text {
        let size = trade.label(size: unit)
        return switch trade.side {
        case .bid: Text("Buy \(trade.labels.price), size \(size), at \(trade.labels.time)", bundle: .module)
        case .ask: Text("Sell \(trade.labels.price), size \(size), at \(trade.labels.time)", bundle: .module)
        }
    }
}

#if DEBUG
    #Preview {
        let labels = TradeLabels(price: "80,121", size: "0.01199", sizeUSD: "$961", time: "4:52:26 PM")
        VStack(spacing: 0) {
            TradeRowView(trade: Trade(id: 1, coin: Symbol.btc.coin, side: .bid, labels: labels), unit: .coin, height: Layout.rowHeight)
            TradeRowView(trade: Trade(id: 2, coin: Symbol.btc.coin, side: .ask, labels: labels), unit: .usd, height: Layout.rowHeight)
        }
    }
#endif
