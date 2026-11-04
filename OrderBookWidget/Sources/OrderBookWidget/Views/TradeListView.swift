import SwiftUI

/// The trade stream, newest on top. New trades slide in, which is most of what makes it feel live.
struct TradeListView: View {
    let trades: [Trade]
    let unit: SizeUnit

    @ScaledMetric(relativeTo: .footnote) private var rowHeight = Layout.rowHeight
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if trades.isEmpty {
            Text("Waiting for trades", bundle: .module)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(trades) { trade in
                        TradeRowView(trade: trade, unit: unit, height: rowHeight)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .animation(reduceMotion ? nil : .smooth(duration: Motion.rowSlide), value: trades.first?.id)
            }
            .scrollIndicators(.hidden)
        }
    }
}

#if DEBUG
    #Preview("Live") {
        PreviewHost { TradeListView(trades: $0.trades, unit: $0.sizeUnit) }
    }

    #Preview("Waiting") {
        TradeListView(trades: [], unit: .coin)
    }
#endif
