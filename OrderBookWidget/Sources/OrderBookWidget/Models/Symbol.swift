/// Markets the widget supports. The raw value is Hyperliquid's coin code.
public enum Symbol: String, CaseIterable, Identifiable, Sendable {
    case btc = "BTC"
    case eth = "ETH"

    public var id: Self { self }
    public var coin: String { rawValue }

    /// Every market the widget shows is quoted in dollars.
    public static let quoteCurrency = "USD"

    /// "BTC-USD", the pair as a trading app names it.
    public var pair: String { "\(coin)-\(Self.quoteCurrency)" }

    /// Hyperliquid's `szDecimals` for the perp, so sizes render at exchange precision.
    var sizeDecimals: Int {
        switch self {
        case .btc: 5
        case .eth: 4
        }
    }
}
