import Foundation

/// `orderbook://book?coin=ETH` opens the live book on that market. The Home Screen widget builds
/// these; the host app parses them.
public enum DeepLink {
    public static let scheme = "orderbook"
    static let host = "book"
    static let coinQuery = "coin"

    public static func url(for symbol: Symbol) -> URL {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.queryItems = [URLQueryItem(name: coinQuery, value: symbol.coin)]
        // Every part is a fixed, URL-safe literal, so this cannot fail.
        return components.url!
    }

    public static func symbol(from url: URL) -> Symbol? {
        guard url.scheme == scheme, url.host() == host,
            let coin = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == coinQuery })?.value
        else { return nil }
        return Symbol(rawValue: coin.uppercased())
    }
}
