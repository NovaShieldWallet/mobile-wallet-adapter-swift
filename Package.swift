// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MobileWalletAdapterSwift",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "MobileWalletAdapterSwift",
            targets: ["MobileWalletAdapterSwift"]
        ),
    ],
    dependencies: [
        // Ed25519 implementation via Sodium (libsodium wrapper)
        .package(url: "https://github.com/jedisct1/swift-sodium.git", from: "0.9.1"),
    ],
    targets: [
        .target(
            name: "MobileWalletAdapterSwift",
            dependencies: [
                .product(name: "Sodium", package: "swift-sodium")
            ],
            path: "Sources/MobileWalletAdapterSwift"
        ),
        .testTarget(
            name: "MobileWalletAdapterSwiftTests",
            dependencies: ["MobileWalletAdapterSwift"]
        ),
    ]
)
