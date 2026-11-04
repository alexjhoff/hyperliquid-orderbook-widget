import SwiftUI

extension Color {
    /// Bid green and ask red, with light-mode variants that hold 4.5:1 over the depth bars.
    public static let bid = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.160, green: 0.780, blue: 0.550, alpha: 1)
                : UIColor(red: 0.043, green: 0.478, blue: 0.314, alpha: 1)
        })
    public static let ask = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.950, green: 0.320, blue: 0.380, alpha: 1)
                : UIColor(red: 0.784, green: 0.196, blue: 0.247, alpha: 1)
        })
}

extension Side {
    public var tint: Color { self == .bid ? .bid : .ask }
}
