import SwiftUI

struct ColumnHeaderView: View {
    let coin: String
    let unit: SizeUnit

    var body: some View {
        let unitName = unit == .usd ? Symbol.quoteCurrency : coin
        HStack(spacing: Spacing.m) {
            Text("Price (USD)", bundle: .module).frame(maxWidth: .infinity, alignment: .leading)
            Text("Size (\(unitName))", bundle: .module).frame(maxWidth: .infinity, alignment: .trailing)
            Text("Total (\(unitName))", bundle: .module).frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(.caption2.weight(.medium))
        .foregroundStyle(.secondary)
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.s)
    }
}

#if DEBUG
    #Preview {
        ColumnHeaderView(coin: Symbol.btc.coin, unit: .usd)
    }
#endif
