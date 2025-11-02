// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SolanaSwiftKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        // Framework 1: Core Solana crypto and transaction handling
        .library(
            name: "SolanaSwift",
            targets: ["SolanaSwift"]
        ),
        // Framework 2: Safari Extension integration helpers
        .library(
            name: "SolanaSafariKit",
            targets: ["SolanaSafariKit"]
        ),
    ],
    dependencies: [],
    targets: [
        // SolanaSwift: Pure Solana crypto primitives
        .target(
            name: "SolanaSwift",
            dependencies: ["Ed25519"],
            path: "Sources/SolanaSwift"
        ),
        
        // Ed25519: C implementation for signing
        .target(
            name: "Ed25519",
            dependencies: [],
            path: "Sources/Ed25519",
            publicHeadersPath: "include"
        ),
        
        // SolanaSafariKit: Safari Extension bridge
        .target(
            name: "SolanaSafariKit",
            dependencies: ["SolanaSwift"],
            path: "Sources/SolanaSafariKit",
            resources: [
                .copy("Resources/JSBundles")
            ]
        ),
        
        // Tests
        .testTarget(
            name: "SolanaSwiftTests",
            dependencies: ["SolanaSwift"]
        ),
        .testTarget(
            name: "SolanaSafariKitTests",
            dependencies: ["SolanaSafariKit"]
        ),
    ]
)

