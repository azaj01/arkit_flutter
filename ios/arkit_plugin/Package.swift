// swift-tools-version: 5.9

import Foundation
import PackageDescription

// ---------------------------------------------------------------------------
// TrueDepth / face-tracking configuration
//
// TrueDepth APIs are excluded by default so apps that don't use face tracking
// pass App Store review. Enable via (first match wins):
//
//  1. Environment variable — useful for monorepos / non-standard layouts:
//       launchctl setenv ARKIT_FACE_TRACKING_ENABLED 1
//
//  2. Info.plist key in ios/Runner/Info.plist:
//       <key>ARKitFaceTrackingEnabled</key><true/>
//
// After changing either, clear the manifest cache and DerivedData:
//   rm -rf ~/Library/Caches/org.swift.swiftpm/manifests
//   rm -rf ~/Library/Developer/Xcode/DerivedData
// ---------------------------------------------------------------------------

/// Walk up from `start` looking for a directory that anchors a Flutter app
/// (contains `pubspec.yaml` alongside `ios/Runner/Info.plist`), then return
/// the plist contents.
func findInfoPlist(from start: URL) -> [String: Any]? {
    let fm = FileManager.default
    var dir = start
    var visited = Set<String>()
    for _ in 0..<12 {
        let canonical = dir.resolvingSymlinksInPath().path
        guard visited.insert(canonical).inserted else { break }
        let pubspec = dir.appendingPathComponent("pubspec.yaml")
        let plist   = dir.appendingPathComponent("ios/Runner/Info.plist")
        if fm.fileExists(atPath: pubspec.path),
           let dict = NSDictionary(contentsOf: plist) as? [String: Any] {
            return dict
        }
        let parent = dir.deletingLastPathComponent()
        guard parent.path != dir.path else { break }
        dir = parent
    }
    return nil
}

let packageDir = URL(fileURLWithPath: #file).deletingLastPathComponent()
let cwdDir     = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

// Primary search: walk up from #file path and from cwd.
// When the package is accessed via an SPM symlink in the consuming project's
// ephemeral directory, the unresolved #file path traverses up through the
// project tree and finds ios/Runner/Info.plist before the loop limit.
var infoPlist = findInfoPlist(from: packageDir)
    ?? findInfoPlist(from: cwdDir)

// Local-development fallback: when building this plugin's own example app,
// #file resolves to the plugin's real ios/arkit_plugin/ path. That path's
// ancestors never contain ios/Runner/Info.plist (the plugin uses
// ios/arkit_plugin/, not ios/Runner/). Check the sibling example/ directory
// explicitly when we're not inside the pub cache.
if infoPlist == nil {
    let pubCachePath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".pub-cache").path
    if !packageDir.resolvingSymlinksInPath().path.hasPrefix(pubCachePath) {
        let pluginRoot = packageDir
            .deletingLastPathComponent()  // ios/arkit_plugin -> ios/
            .deletingLastPathComponent()  // ios/ -> plugin root
        infoPlist = findInfoPlist(from: pluginRoot.appendingPathComponent("example"))
    }
}

let envEnabled = ProcessInfo.processInfo.environment["ARKIT_FACE_TRACKING_ENABLED"].map { $0 != "0" }

let truedepthEnabled = envEnabled
    ?? ((infoPlist ?? [:])["ARKitFaceTrackingEnabled"] as? Bool == true)

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
            ],
            swiftSettings: truedepthEnabled ? [.define("ENABLE_TRUEDEPTH_API")] : []
        )
    ]
)
