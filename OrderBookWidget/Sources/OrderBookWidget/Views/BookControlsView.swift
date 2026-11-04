import SwiftUI

/// Price grouping on the left and the market on the right, as matching menus.
struct BookControlsView: View {
    @Bindable var viewModel: OrderBookViewModel

    var body: some View {
        HStack {
            // Grouping applies to the book only; a trade happens at one exact price.
            if viewModel.pane == .book {
                PrecisionMenu(selection: $viewModel.precision, mid: viewModel.book?.mid)
            }
            Spacer()
            MarketMenu(selection: $viewModel.symbol)
        }
        .padding(.horizontal, Spacing.l)
        .padding(.bottom, Spacing.xs)
    }
}

#if DEBUG
    #Preview {
        PreviewHost { BookControlsView(viewModel: $0) }
    }
#endif
