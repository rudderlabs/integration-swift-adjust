// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "RudderIntegrationAdjust",
    platforms: [.iOS(.v15), .tvOS(.v15)],
    products: [.library(name: "RudderIntegrationAdjust", targets: ["RudderIntegrationAdjust"])],
    dependencies: [.package(url: "https://github.com/rudderlabs/rudder-sdk-swift.git", from: "2.0.0"), .package(url: "https://github.com/adjust/ios_sdk", .upToNextMajor(from: "5.4.6"))],
    targets: [.target(name: "RudderIntegrationAdjust", dependencies: [.product(name: "RudderStackAnalytics", package: "rudder-sdk-swift"), .product(name: "AdjustSdk", package: "ios_sdk")])]
)
