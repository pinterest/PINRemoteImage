// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PINRemoteImage",
    platforms: [
             .macOS(.v10_10),
             .iOS(.v9),
             .tvOS(.v9)
         ],
    products: [
        .library(
            name: "PINRemoteImage",
            type: .static,
            targets: ["PINRemoteImage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pinterest/PINCache.git", from: "3.0.3"),
        .package(name: "libwebp",
                 url: "https://github.com/SDWebImage/libwebp-Xcode",
                 from: "1.1.0"),
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
