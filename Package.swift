// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PINRemoteImage",
    platforms: [
             .macOS(.v10_10),
             .iOS(.v12),
             .tvOS(.v9)
         ],
    products: [
        .library(
            name: "PINRemoteImage",
            type: .static,
            targets: ["PINRemoteImage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/basecamp/PINCache.git", from: "3.0.4"),
        .package(name: "libwebp",
                 url: "https://github.com/basecamp/libwebp-Xcode",
                 from: "1.2.1"),
    ],
    targets: [
        .target(
            name: "PINRemoteImage",
            dependencies: ["PINCache", "libwebp"],
            path: "Source/Classes",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("."),
                .headerSearchPath("Categories"),
                .headerSearchPath("AnimatedImages"),
                .headerSearchPath("ImageCategories"),
                .headerSearchPath("PinCache"),
                
                .define("USE_PINCACHE", to: "1"),
                .define("PIN_WEBP", to: "1"),
                ]),
    ]
)
