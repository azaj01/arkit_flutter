// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "arkit_plugin",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "arkit-plugin", targets: ["arkit_plugin"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(url: "https://github.com/magicien/GLTFSceneKit.git", from: "0.4.0")
    ],
    targets: [
        .target(
            name: "arkit_plugin",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "GLTFSceneKit", package: "GLTFSceneKit")
            ]
        )
    ]
)
