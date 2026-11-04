import SwiftUI

struct ColumnHeaderView: View {
    let coin: String
    let unit: SizeUnit
    let pane: WidgetPane

    var body: some View {
        let unitName = unit == .usd ? Symbol.quoteCurrency : coin
        HStack(spacing: Spacing.m) {
            Text("Price (USD)", bundle: .module).frame(maxWidth: .infinity, alignment: .leading)
            Text("Size (\(unitName))", bundle: .module).frame(maxWidth: .infinity, alignment: .trailing)
            Group {
                switch pane {
                case .book: Text("Total (\(unitName))", bundle: .module)
                case .trades: Text("Time", bundle: .module)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(.caption2.weight(.medium))
        .foregroundStyle(.secondary)
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.s)
    }
}

#if DEBUG
    #Preview {
        ColumnHeaderView(coin: Symbol.btc.coin, unit: .usd, pane: .book)
        ColumnHeaderView(coin: Symbol.btc.coin, unit: .coin, pane: .trades)
    }
#endif
