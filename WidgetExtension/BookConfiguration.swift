import AppIntents

/// What the user can change from the widget's edit sheet.
struct BookConfiguration: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Order Book"
    static let description = IntentDescription("Top of the Hyperliquid book.")
}
