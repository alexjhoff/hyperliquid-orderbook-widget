/// Whether sizes show in the coin or in US dollars.
public enum SizeUnit: String, CaseIterable, Sendable {
    case coin, usd
}

public enum Side: Sendable {
    case bid, ask

    var name: String {
        switch self {
        case .bid: "Bid"
        case .ask: "Ask"
        }
    }
}
