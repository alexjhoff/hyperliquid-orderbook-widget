import Foundation

/// What the widget's main area shows.
public enum WidgetPane: String, CaseIterable, Identifiable, Sendable {
    case book, trades

    public var id: Self { self }

    var name: String {
        switch self {
        case .book: String(localized: "Book", bundle: .module)
        case .trades: String(localized: "Trades", bundle: .module)
        }
    }
}
