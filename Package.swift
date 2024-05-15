// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PINRemoteImage",
    platforms: [             
             .iOS(.v14),
             .macOS(.v11),
             .tvOS(.v14),
         ],
    products: [
        .library(
            name: "PINRemoteImage",
            type: .static,
            targets: ["PINRemoteImage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pinterest/PINCache.git", from: "3.0.4"),
    ],
    targets: [
        .target(
            name: "PINRemoteImage",
            dependencies: ["PINCache"],
            path: "Source/Classes",
            resources: [.process("../PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("."),
                .headerSearchPath("Categories"),
                .headerSearchPath("AnimatedImages"),
                .headerSearchPath("ImageCategories"),
                .headerSearchPath("PinCache"),
                
                .define("NS_BLOCK_ASSERTIONS", to: "1", .when(configuration: .release)),
                .define("USE_PINCACHE", to: "1"),
                .define("PIN_WEBP", to: "1"),
                ]),
    ]
)
