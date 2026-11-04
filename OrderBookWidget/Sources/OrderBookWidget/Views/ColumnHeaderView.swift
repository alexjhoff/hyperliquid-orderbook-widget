import SwiftUI

struct ColumnHeaderView: View {
    let coin: String
    let unit: SizeUnit

    var body: some View {
        let unitName = unit == .usd ? "USD" : coin
        HStack(spacing: 8) {
            Text("Price (USD)").frame(maxWidth: .infinity, alignment: .leading)
            Text("Size (\(unitName))").frame(maxWidth: .infinity, alignment: .trailing)
            Text("Total (\(unitName))").frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(.caption2.weight(.medium))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
