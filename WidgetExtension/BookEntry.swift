import OrderBookWidget
import WidgetKit

struct BookEntry: TimelineEntry {
    let date: Date
    let symbol: Symbol
    /// Nil before the first fetch, or when the last one failed.
    let snapshot: BookSnapshot?
}
