/// An `l2Book` subscription. Encodes to Hyperliquid's wire shape and matches the server's echo in
/// acks, which spell an absent `nSigFigs` as `null`; Codable treats both as nil, so equality holds.
public struct BookSubscription: Codable, Hashable, Sendable, CustomStringConvertible {
    var type = "l2Book"
    public let coin: String
    public let nSigFigs: Int?

    public init(coin: String, nSigFigs: Int?) {
        self.coin = coin
        self.nSigFigs = nSigFigs
    }

    public init(symbol: Symbol, precision: Precision) {
        self.init(coin: symbol.coin, nSigFigs: precision.nSigFigs)
    }

    public var description: String {
        "\(coin)@\(nSigFigs.map(String.init) ?? "full")"
    }
}
