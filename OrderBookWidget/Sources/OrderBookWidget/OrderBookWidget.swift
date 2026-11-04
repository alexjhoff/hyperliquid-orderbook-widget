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
        self.init(viewModel: OrderBookViewModel(feed: HyperliquidFeed(clock: ContinuousClock()), selections: selections))
    }

    @MainActor init(viewModel: OrderBookViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            BookHeaderView(viewModel: viewModel)
            PanePickerView(viewModel: viewModel)
            ColumnHeaderView(coin: viewModel.symbol.coin, unit: viewModel.sizeUnit, pane: viewModel.pane)
            switch viewModel.pane {
            case .book:
                BookListView(
                    book: viewModel.book,
                    unit: viewModel.sizeUnit,
                    isStale: viewModel.isStale,
                    subscription: viewModel.subscription
                )
            case .trades:
                TradeListView(trades: viewModel.trades, unit: viewModel.sizeUnit)
            }
            BookFooterView(viewModel: viewModel)
        }
        .task { await viewModel.run() }
        // Haptics for user actions only. Market data never buzzes.
        .sensoryFeedback(.selection, trigger: viewModel.pane)
        .sensoryFeedback(.selection, trigger: viewModel.symbol)
        .sensoryFeedback(.selection, trigger: viewModel.precision)
        .sensoryFeedback(.selection, trigger: viewModel.sizeUnit)
        // Three numeric columns stop fitting past this size.
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background: viewModel.sceneDidEnterBackground()
            case .active: viewModel.sceneDidBecomeActive()
            default: break
            }
        }
    }
}

#if DEBUG
    #Preview {
        OrderBookWidget(viewModel: OrderBookViewModel(feed: PreviewFeed(), selections: InMemorySelectionStore()))
    }

    #Preview("Dark, largest type") {
        OrderBookWidget(viewModel: OrderBookViewModel(feed: PreviewFeed(), selections: InMemorySelectionStore()))
            .preferredColorScheme(.dark)
            .dynamicTypeSize(.accessibility5)
    }
#endif
