// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "WalletExampleApp",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .executable(
            name: "WalletExampleApp",
            targets: ["WalletExampleApp"]
        )
    ],
    dependencies: [
        .package(name: "mobile-wallet-adapter-swift", path: ".."),
    ],
    targets: [
        .executableTarget(
            name: "WalletExampleApp",
            dependencies: [
                .product(name: "MobileWalletAdapterSwift", package: "mobile-wallet-adapter-swift")
            ],
            path: "Sources/WalletExampleApp"
        )
    ]
)

