import AppIntents
import OrderBookWidget

/// What the user can change from the widget's edit sheet: the market and the price grouping,
/// as native pickers. AppIntents needs its enums declared in this module, so these two mirror
/// the package's `Symbol` and `Precision`.
struct BookConfiguration: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Order Book"
    static let description = IntentDescription("Choose the market and price grouping.")

    @Parameter(title: "Market", default: .btc)
    var market: MarketOption

    @Parameter(title: "Price grouping", default: .full)
    var grouping: GroupingOption
}

enum MarketOption: String, AppEnum {
    case btc, eth

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Market")
    static let caseDisplayRepresentations: [MarketOption: DisplayRepresentation] = [
        .btc: "BTC",
        .eth: "ETH",
    ]

    var symbol: Symbol {
        switch self {
        case .btc: .btc
        case .eth: .eth
        }
    }
}

enum GroupingOption: String, AppEnum {
    case full, five, four, three, two

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Price grouping")
    static let caseDisplayRepresentations: [GroupingOption: DisplayRepresentation] = [
        .full: "Full precision",
        .five: "5 significant figures",
        .four: "4 significant figures",
        .three: "3 significant figures",
        .two: "2 significant figures",
    ]

    var precision: Precision {
        switch self {
        case .full: .full
        case .five: .five
        case .four: .four
        case .three: .three
        case .two: .two
        }
    }
}
