import Foundation
import OrderBookWidget

/// `orderbook://book?coin=ETH` opens the live book on that market.
enum DeepLinkRouter {
    static let scheme = "orderbook"

    static func symbol(from url: URL) -> Symbol? {
        guard url.scheme == scheme, url.host() == "book",
            let coin = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "coin" })?.value
        else { return nil }
        return Symbol(rawValue: coin.uppercased())
    }
}
