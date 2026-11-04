import SwiftUI

/// The market as a native menu picker, the same control as `PrecisionMenu`.
struct MarketMenu: View {
    @Binding var selection: Symbol

    var body: some View {
        Menu {
            Picker(selection: $selection) {
                ForEach(Symbol.allCases) { symbol in
                    Text(verbatim: symbol.coin).tag(symbol)
                }
            } label: {
                Text("Market", bundle: .module)
            }
            .pickerStyle(.inline)
        } label: {
            HStack(spacing: Spacing.s) {
                Text(verbatim: selection.coin)
                Image(systemName: Glyph.menu)
            }
            .font(.subheadline.weight(.medium))
        }
        .accessibilityLabel(Text("Market", bundle: .module))
        .accessibilityValue(Text(verbatim: selection.coin))
        .accessibilityIdentifier(A11yID.symbolPicker)
    }
}

#if DEBUG
    #Preview {
        @Previewable @State var selection = Symbol.btc
        MarketMenu(selection: $selection)
    }
#endif
