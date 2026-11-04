import SwiftUI

/// A live Hyperliquid order book. Drop it into any screen; it owns its own connection, state and
/// controls, and fills whatever frame its host gives it.
public struct OrderBookWidget: View {
    @State private var viewModel: OrderBookViewModel
    @Environment(\.scenePhase) private var scenePhase

    /// - Parameter symbol: Overrides the remembered market, e.g. when opened from a deep link.
    @MainActor public init(symbol: Symbol? = nil) {
        let selections = UserDefaultsSelectionStore()
        if let symbol { selections.symbol = symbol }
        self.init(viewModel: OrderBookViewModel(feed: HyperliquidFeed(), selections: selections))
    }

    @MainActor init(viewModel: OrderBookViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            BookHeaderView(viewModel: viewModel)
            ColumnHeaderView(coin: viewModel.symbol.coin, unit: viewModel.sizeUnit)
            BookListView(
                book: viewModel.book,
                unit: viewModel.sizeUnit,
                isStale: viewModel.isStale,
                subscription: viewModel.subscription
            )
            BookFooterView(viewModel: viewModel)
        }
        .task { await viewModel.run() }
        // Haptics for user actions only. Market data never buzzes.
        .sensoryFeedback(.selection, trigger: viewModel.symbol)
        .sensoryFeedback(.selection, trigger: viewModel.precision)
        .sensoryFeedback(.selection, trigger: viewModel.sizeUnit)
        // Three numeric columns stop fitting past this size.
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background: Task { await viewModel.disconnect() }
            case .active: Task { await viewModel.reconnect() }
            default: break
            }
        }
    }
}

#if DEBUG
    #Preview {
        OrderBookWidget(viewModel: OrderBookViewModel(feed: PreviewFeed(), selections: InMemorySelectionStore()))
    }
#endif
