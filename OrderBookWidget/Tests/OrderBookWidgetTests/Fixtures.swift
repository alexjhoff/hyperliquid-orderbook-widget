@testable import OrderBookWidget

/// Frames captured from wss://api.hyperliquid.xyz/ws on 2026-11-03, trimmed to three levels per side.
enum Fixture {
    static let btcBook = #"""
        {"channel":"l2Book","data":{"coin":"BTC","time":1793731205404,"levels":[[{"px":"77719.0","sz":"6.28612","n":13},{"px":"77718.0","sz":"1.1449","n":8},{"px":"77717.0","sz":"0.42548","n":4}],[{"px":"77720.0","sz":"4.7368","n":18},{"px":"77721.0","sz":"0.93376","n":2},{"px":"77722.0","sz":"0.83727","n":1}]],"spread":"1.0"}}
        """#

    static let ethBook = #"""
        {"channel":"l2Book","data":{"coin":"ETH","time":1793751536260,"levels":[[{"px":"2269.0","sz":"48.0959","n":20},{"px":"2268.9","sz":"397.9817","n":47},{"px":"2268.8","sz":"60.7923","n":21}],[{"px":"2269.1","sz":"15.0989","n":8},{"px":"2269.2","sz":"12.8055","n":4},{"px":"2269.3","sz":"160.7525","n":13}]],"spread":"0.1"}}
        """#

    static let subscribeAck = #"""
        {"channel":"subscriptionResponse","data":{"method":"subscribe","subscription":{"type":"l2Book","coin":"BTC","nSigFigs":5,"mantissa":null,"fast":false}}}
        """#

    static let fullPrecisionAck = #"""
        {"channel":"subscriptionResponse","data":{"method":"subscribe","subscription":{"type":"l2Book","coin":"BTC","nSigFigs":null,"mantissa":null,"fast":false}}}
        """#

    static let unsubscribeAck = #"""
        {"channel":"subscriptionResponse","data":{"method":"unsubscribe","subscription":{"type":"l2Book","coin":"ETH","nSigFigs":3}}}
        """#

    static func book(_ frame: String) throws -> WireBook {
        guard case .book(let book) = try ServerMessage.decode(frame) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "not a book frame"))
        }
        return book
    }
}
