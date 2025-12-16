// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RudderIntegrationAdjust",
    platforms: [
        .iOS(.v15),
        .tvOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "RudderIntegrationAdjust",
            targets: ["RudderIntegrationAdjust"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/adjust/ios_sdk", .upToNextMajor(from: "5.4.6")),
        .package(url: "https://github.com/rudderlabs/rudder-sdk-swift.git", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "RudderIntegrationAdjust",
            dependencies: [
                .product(name: "AdjustSdk", package: "ios_sdk"),
                .product(name: "RudderStackAnalytics", package: "rudder-sdk-swift")
            ]
        ),
        .testTarget(
            name: "RudderIntegrationAdjustTests",
            dependencies: ["RudderIntegrationAdjust"]
        ),
    ]
)
