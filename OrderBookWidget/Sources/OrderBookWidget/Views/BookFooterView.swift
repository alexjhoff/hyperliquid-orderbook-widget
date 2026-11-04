import SwiftUI

/// Price grouping on the left, size unit on the right, like the footer of Hyperliquid's own book.
struct BookFooterView: View {
    @Bindable var viewModel: OrderBookViewModel

    var body: some View {
        HStack {
            PrecisionMenu(selection: $viewModel.precision, mid: viewModel.book?.mid)
            Spacer()
            Picker(selection: $viewModel.sizeUnit) {
                Text(verbatim: viewModel.symbol.coin).tag(SizeUnit.coin)
                Text(verbatim: Symbol.quoteCurrency).tag(SizeUnit.usd)
            } label: {
                Text("Size unit", bundle: .module)
            }
            .pickerStyle(.segmented)
            .fixedSize()
            .accessibilityIdentifier("unitPicker")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

/// `nSigFigs` as a native menu picker, each option labelled by the tick it produces.
private struct PrecisionMenu: View {
    @Binding var selection: Precision
    let mid: Double?

    var body: some View {
        Menu {
            Picker(selection: $selection) {
                ForEach(Precision.allCases) { option in
                    Text("\(PrecisionPresentation.tickLabel(for: option, near: mid))  ·  \(option.name)", bundle: .module).tag(option)
                }
            } label: {
                Text("Price grouping", bundle: .module)
            }
            .pickerStyle(.inline)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "square.stack.3d.down.right")
                Text(verbatim: PrecisionPresentation.tickLabel(for: selection, near: mid)).monospacedDigit()
            }
            .font(.subheadline.weight(.medium))
        }
        .accessibilityLabel(Text("Price grouping", bundle: .module))
        .accessibilityValue(Text("\(PrecisionPresentation.tickLabel(for: selection, near: mid)), \(selection.name)", bundle: .module))
        .accessibilityIdentifier("precisionMenu")
    }
}
