import Foundation

/// Where the widget keeps the user's last symbol, grouping and size unit.
protocol SelectionStoring: AnyObject {
    var symbol: Symbol? { get set }
    var precision: Precision? { get set }
    var sizeUnit: SizeUnit? { get set }
}

/// Persists selections in `UserDefaults` under keys prefixed so they never collide with the host app's.
final class UserDefaultsSelectionStore: SelectionStoring {
    private let defaults: UserDefaults
    private static let prefix = "orderBookWidget."

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var symbol: Symbol? {
        get { read("symbol") }
        set { write(newValue, "symbol") }
    }

    var precision: Precision? {
        get { read("precision") }
        set { write(newValue, "precision") }
    }

    var sizeUnit: SizeUnit? {
        get { read("sizeUnit") }
        set { write(newValue, "sizeUnit") }
    }

    private func read<Value: RawRepresentable<String>>(_ key: String) -> Value? {
        defaults.string(forKey: Self.prefix + key).flatMap(Value.init(rawValue:))
    }

    private func write<Value: RawRepresentable<String>>(_ value: Value?, _ key: String) {
        defaults.set(value?.rawValue, forKey: Self.prefix + key)
    }
}

/// For previews and tests. Starts with whatever the caller sets.
final class InMemorySelectionStore: SelectionStoring {
    var symbol: Symbol?
    var precision: Precision?
    var sizeUnit: SizeUnit?

    init(symbol: Symbol? = nil, precision: Precision? = nil, sizeUnit: SizeUnit? = nil) {
        self.symbol = symbol
        self.precision = precision
        self.sizeUnit = sizeUnit
    }
}
