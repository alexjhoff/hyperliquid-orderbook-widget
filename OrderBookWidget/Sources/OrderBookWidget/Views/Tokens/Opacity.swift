import Foundation

/// Translucency levels.
public enum Opacity {
    /// A depth bar behind a row, light enough that text over it stays readable.
    public static let depthBar = 0.14
    /// A book waiting to be replaced after a selection change.
    public static let stale = 0.45
    /// The band behind the spread row.
    public static let spreadBackground = 0.06
    /// The brightest moment of a row flash.
    public static let flashPeak = 0.3
}
