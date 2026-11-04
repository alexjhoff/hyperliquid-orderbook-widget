import SwiftUI

/// One side of the book as a fixed number of slots. Asks render worst-to-best so the best ask sits
/// next to the spread; missing levels become placeholder rows so the layout never jumps.
struct BookSideView: View {
    let side: Side
    /// Best price first.
    let levels: [BookLevel]
    let unit: SizeUnit
    let depth: Int
    let rowHeight: CGFloat

    var body: some View {
        ForEach(slots) { slot in
            switch slot {
            case .level(let level):
                BookRowView(level: level, side: side, unit: unit, height: rowHeight)
            case .empty:
                EmptyRow(height: rowHeight)
            }
        }
    }

    private enum Slot: Identifiable {
        case level(BookLevel)
        case empty(Int)

        var id: String {
            switch self {
            case .level(let level): level.id
            case .empty(let index): "empty-\(index)"
            }
        }
    }

    private var slots: [Slot] {
        var slots = levels.prefix(depth).map(Slot.level)
        for index in slots.count..<depth {
            slots.append(.empty(index))
        }
        return side == .ask ? slots.reversed() : slots
    }
}
