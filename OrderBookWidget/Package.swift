// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "OrderBookWidget",
    defaultLocalization: "en",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "OrderBookWidget", targets: ["OrderBookWidget"])
    ],
    targets: [
        .target(name: "OrderBookWidget", resources: [.process("Resources/Localizable.xcstrings"), .copy("Resources/PrivacyInfo.xcprivacy")]),
        .testTarget(name: "OrderBookWidgetTests", dependencies: ["OrderBookWidget"]),
    ]
)
