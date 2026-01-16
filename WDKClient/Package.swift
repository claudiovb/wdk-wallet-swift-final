// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WDKClient",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "WDKClient",
            targets: ["WDKClient"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/holepunchto/bare-kit-swift", branch: "main")
    ],
    targets: [
        .target(
            name: "WDKClient",
            dependencies: [
                .product(name: "BareKit", package: "bare-kit-swift")
            ]
        )
    ]
)
