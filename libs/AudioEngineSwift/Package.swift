// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AudioEngineSwift",
    platforms: [
        .iOS(.v13),
        .macOS(.v12)
    ],
    products: [
        .library(name: "AudioEngineSwift", targets: ["AudioEngineSwift"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-atomics.git", from: "1.2.0")
    ],
    targets: [
        // FFmpeg prebuilt binary
        .binaryTarget(
            name: "FFmpeg",
            path: "FFmpeg.xcframework"
        ),

        // C bridge for FFmpeg
        .target(
            name: "FFmpegBridge",
            dependencies: ["FFmpeg"],
            path: "Sources/FFmpegBridge",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include")
            ]
        ),

        // Swift audio engine core
        .target(
            name: "AudioEngineSwift",
            dependencies: [
                "FFmpegBridge",
                .product(name: "Atomics", package: "swift-atomics")
            ],
            path: "Sources/AudioEngineSwift",
            linkerSettings: [
                .linkedLibrary("iconv"),
                .linkedLibrary("z"),
                .linkedFramework("AudioToolbox"),
                .linkedFramework("CoreAudio"),
                .linkedFramework("CoreVideo"),
                .linkedFramework("VideoToolbox")
            ]
        ),

        .testTarget(
            name: "AudioEngineSwiftTests",
            dependencies: ["AudioEngineSwift"],
            path: "Tests/AudioEngineSwiftTests"
        )
    ]
)
