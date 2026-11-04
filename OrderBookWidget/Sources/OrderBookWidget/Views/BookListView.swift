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

    @ScaledMetric(relativeTo: .footnote) private var rowHeight: CGFloat = 22
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
                .opacity(isStale && book != nil ? 0.45 : 1)
                .animation(.easeOut(duration: 0.2), value: isStale)
            }
            .defaultScrollAnchor(.center)
            .scrollIndicators(.hidden)
            .onChange(of: subscription) {
                proxy.scrollTo(Self.spreadID, anchor: .center)
            }
            .onChange(of: recentreRequests) {
                withAnimation(.smooth) { proxy.scrollTo(Self.spreadID, anchor: .center) }
            }
        }
    }
}
