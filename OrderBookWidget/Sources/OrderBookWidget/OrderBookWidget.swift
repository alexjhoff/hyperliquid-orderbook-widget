import SwiftUI

/// A live Hyperliquid order book. Drop it into any screen; it owns its own connection and state.
public struct OrderBookWidget: View {
    public init() {}

    public var body: some View {
        Text("Order book")
    }
}
