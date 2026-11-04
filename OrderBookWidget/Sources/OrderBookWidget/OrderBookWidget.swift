import SwiftUI

/// A live Hyperliquid order book. Drop it into any screen; it owns its own connection, state and
/// controls, and fills whatever frame its host gives it.
public struct OrderBookWidget: View {
    @State private var viewModel: OrderBookViewModel
    @Environment(\.scenePhase) private var scenePhase

    @MainActor public init() {
        self.init(viewModel: OrderBookViewModel(feed: HyperliquidFeed(), selections: UserDefaultsSelectionStore()))
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
