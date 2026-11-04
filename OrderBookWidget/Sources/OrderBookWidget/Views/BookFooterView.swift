import SwiftUI

/// Price grouping on the left, size unit on the right, like the footer of Hyperliquid's own book.
struct BookFooterView: View {
    @Bindable var viewModel: OrderBookViewModel

    var body: some View {
        HStack {
            // Grouping applies to the book only; a trade happens at one exact price.
            if viewModel.pane == .book {
                PrecisionMenu(selection: $viewModel.precision, mid: viewModel.book?.mid)
            }
            Spacer()
            Picker(selection: $viewModel.sizeUnit) {
                Text(verbatim: viewModel.symbol.coin).tag(SizeUnit.coin)
                Text(verbatim: Symbol.quoteCurrency).tag(SizeUnit.usd)
            } label: {
                Text("Size unit", bundle: .module)
            }
            .pickerStyle(.segmented)
            .fixedSize()
            .accessibilityIdentifier(A11yID.unitPicker)
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
    }
}

#if DEBUG
    #Preview {
        PreviewHost { BookFooterView(viewModel: $0) }
    }
#endif
