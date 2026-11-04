import Foundation

/// Fixed dimensions.
public enum Layout {
    /// Height of one price level at the default type size; scales with Dynamic Type.
    public static let rowHeight: CGFloat = 22
    public static let statusDot: CGFloat = 7
    public static let symbolPickerWidth: CGFloat = 180
    /// How far a row may shrink its text before truncating.
    public static let minimumTextScale = 0.8
}
