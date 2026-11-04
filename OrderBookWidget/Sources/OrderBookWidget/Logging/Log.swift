import os

/// Central loggers. Filter in Console.app with `subsystem:com.alexhoff.OrderBookWidget`.
public enum Log {
    public static let subsystem = "com.alexhoff.OrderBookWidget"
    static let feed = Logger(subsystem: subsystem, category: "feed")
    static let model = Logger(subsystem: subsystem, category: "model")
    public static let widget = Logger(subsystem: subsystem, category: "widget")
}
