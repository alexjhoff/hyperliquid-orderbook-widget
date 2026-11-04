import SwiftUI

/// Switches the main area between the order book and the trade stream.
struct PanePickerView: View {
    @Bindable var viewModel: OrderBookViewModel

    var body: some View {
        Picker(selection: $viewModel.pane) {
            ForEach(WidgetPane.allCases) { pane in
                Text(verbatim: pane.name).tag(pane)
            }
        } label: {
            Text("View", bundle: .module)
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier(A11yID.panePicker)
        .padding(.horizontal, Spacing.l)
        .padding(.bottom, Spacing.xs)
    }
}

#if DEBUG
    #Preview {
        PreviewHost { PanePickerView(viewModel: $0) }
    }
#endif
