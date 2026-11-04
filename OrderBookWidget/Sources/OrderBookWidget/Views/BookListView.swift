import SwiftUI

/// The book itself: asks above the spread, bids below, in one natively scrolling column that
/// opens centred on the spread. Tapping the spread recentres it.
struct BookListView: View {
    let book: BookSnapshot?
    let unit: SizeUnit
    let isStale: Bool
    /// Changing it scrolls back to the spread, since the rows are about to be replaced.
    let subscription: BookSubscription

    nonisolated static let depth = 20
    private static let spreadID = "spread"

    @ScaledMetric(relativeTo: .footnote) private var rowHeight = Layout.rowHeight
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var recentreRequests = 0

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    BookSideView(side: .ask, levels: book?.asks ?? [], unit: unit, depth: Self.depth, rowHeight: rowHeight)
                    SpreadRowView(book: book)
                        .id(Self.spreadID)
                        .onTapGesture { recentreRequests += 1 }
                    BookSideView(side: .bid, levels: book?.bids ?? [], unit: unit, depth: Self.depth, rowHeight: rowHeight)
                }
                .opacity(isStale && book != nil ? Opacity.stale : 1)
                .animation(rowAnimation, value: book?.sequence)
                .animation(.easeOut(duration: Motion.staleFade), value: isStale)
            }
            .defaultScrollAnchor(.center)
            .scrollIndicators(.hidden)
            .onChange(of: subscription) {
                proxy.scrollTo(Self.spreadID, anchor: .center)
            }
            .onChange(of: recentreRequests) {
                withAnimation(reduceMotion ? nil : .smooth) { proxy.scrollTo(Self.spreadID, anchor: .center) }
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: recentreRequests)
    }

    /// Rows keyed by price slide to their new slot when the market moves. The first snapshot of a
    /// subscription replaces the book outright instead of sliding every row.
    private var rowAnimation: Animation? {
        !reduceMotion && (book?.sequence ?? 0) > 1 ? .smooth(duration: Motion.rowSlide) : nil
    }
}
