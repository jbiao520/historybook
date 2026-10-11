// swift-tools-version: 6.0
import PackageDescription
import Foundation

// Some Command Line Tools releases ship Testing.framework outside the normal
// SwiftPM search paths. Xcode toolchains already expose the Testing module.
let cltRoot = "/Library/Developer/CommandLineTools"
#if canImport(Testing)
let useCLTTesting = false
#else
let useCLTTesting = FileManager.default.fileExists(atPath: "\(cltRoot)/Library/Developer/Frameworks/Testing.framework/Modules")
#endif
let testingSwiftSettings: [SwiftSetting] = useCLTTesting ? [
    .unsafeFlags([
        "-I\(cltRoot)/Library/Developer/Frameworks/Testing.framework/Modules",
        "-Xfrontend", "-disable-cross-import-overlays",
        "-load-plugin-library", "\(cltRoot)/usr/lib/swift/host/plugins/testing/libTestingMacros.dylib"
    ])
] : []
let testingLinkerSettings: [LinkerSetting] = useCLTTesting ? [
    .unsafeFlags([
        "-F", "\(cltRoot)/Library/Developer/Frameworks",
        "-framework", "Testing",
        "-Xlinker", "-rpath",
        "-Xlinker", "\(cltRoot)/Library/Developer/Frameworks"
    ])
] : []

let package = Package(
    name: "Historybook",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Historybook", targets: ["Historybook"])
    ],
    targets: [
        .target(name: "HistorybookCore"),
        .executableTarget(
            name: "Historybook",
            dependencies: ["HistorybookCore"],
            resources: [
                .copy("Content")
            ]
        ),
        .testTarget(
            name: "HistorybookCoreTests",
            dependencies: ["HistorybookCore"],
            swiftSettings: testingSwiftSettings,
            linkerSettings: testingLinkerSettings
        )
    ]
)
