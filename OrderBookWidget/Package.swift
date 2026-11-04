// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "OrderBookWidget",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "OrderBookWidget", targets: ["OrderBookWidget"])
    ],
    targets: [
        .target(name: "OrderBookWidget")
    ]
)
