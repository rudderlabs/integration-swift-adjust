<p align="center">
  <a href="https://rudderstack.com/">
    <img alt="RudderStack" width="512" src="https://raw.githubusercontent.com/rudderlabs/rudder-sdk-js/develop/assets/rs-logo-full-light.jpg">
  </a>
  <br />
  <caption>The Customer Data Platform for Developers</caption>
</p>
<p align="center">
  <b>
    <a href="https://rudderstack.com">Website</a>
    ·
    <a href="https://rudderstack.com/docs/">Documentation</a>
    ·
    <a href="https://rudderstack.com/join-rudderstack-slack-community">Community Slack</a>
  </b>
</p>

---


# Adjust Integration

The Adjust integration allows you to send your event data from RudderStack to Adjust for mobile measurement and attribution.

## Installation

### Swift Package Manager

Add the Adjust integration to your Swift project using Swift Package Manager:

1. In Xcode, go to `File > Add Package Dependencies`

<img width="1920" height="1079" alt="add_package_dependency" src="https://github.com/user-attachments/assets/efd48eb4-68fe-453a-92e4-5d721af5d5a1" />

2. Enter the package repository URL: `https://github.com/rudderlabs/integration-swift-adjust` in the search bar
3. Select the version you want to use
   
   <img width="1084" height="601" alt="select_package" src="https://github.com/user-attachments/assets/ec758a05-9df7-4077-811d-71a1ff3c6286" />

4. Select the target to which you want to add the package
5. Finally, click on **Add Package**

   <img width="640" height="282" alt="select_target" src="https://github.com/user-attachments/assets/72d6b00d-4862-4948-987e-971adf16d0fa" />

Alternatively, add it to your `Package.swift` file:

```swift
// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "YourApp",
    products: [
        .library(
            name: "YourApp",
            targets: ["YourApp"]),
    ],
    dependencies: [
        // Add the Adjust integration
        .package(url: "https://github.com/rudderlabs/integration-swift-adjust.git", .upToNextMajor(from: "<latest_version>"))
    ],
    targets: [
        .target(
            name: "YourApp",
            dependencies: [
                .product(name: "RudderIntegrationAdjust", package: "integration-swift-adjust")
            ]),
    ]
)
```

## Supported Native Adjust SDK Version

This integration supports Adjust iOS SDK version:

```
5.4.6+
```

### Platform Support

The integration supports the following platforms:
- iOS 15.0+
- tvOS 15.0+

## Usage

Initialize the RudderStack SDK and add the Adjust integration:

```swift
import RudderStackAnalytics
import RudderIntegrationAdjust

class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Initialize the RudderStack Analytics SDK
        let config = Configuration(
            writeKey: "<WRITE_KEY>",
            dataPlaneUrl: "<DATA_PLANE_URL>"
        )
        let analytics = Analytics(configuration: config)

        // Add Adjust integration
        analytics.add(plugin: AdjustIntegration())

        return true
    }
}
```

Replace:
- `<WRITE_KEY>`: Your project's write key from the RudderStack dashboard
- `<DATA_PLANE_URL>`: The URL of your RudderStack data plane

---

## Contact us

For more information:

- Email us at [docs@rudderstack.com](mailto:docs@rudderstack.com)
- Join our [Community Slack](https://rudderstack.com/join-rudderstack-slack-community)

## Follow Us

- [RudderStack Blog](https://rudderstack.com/blog/)
- [Slack](https://rudderstack.com/join-rudderstack-slack-community)
- [Twitter](https://twitter.com/rudderstack)
- [YouTube](https://www.youtube.com/channel/UCgV-B77bV_-LOmKYHw8jvBw)
