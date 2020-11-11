// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PINCache",
    platforms: [
        .macOS(.v10_10),
        .iOS(.v9),
        .watchOS(.v2),
        .tvOS(.v9)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "PINCache",
            targets: ["PINCache"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/pinterest/PINOperation.git", from: "1.2.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "PINCache",
            dependencies: ["PINOperation"],
            path: "Source",
            exclude: ["Carthage", "docs",
                      "build_docs.sh", "Cartfile",
                      "Cartfile.resolved", "Makefile",
                      "PINCache.podspec", "Info.plist"],
            publicHeadersPath: "."),
        .testTarget(
            name: "PINCacheTests",
            dependencies: ["PINCache"],
            path: "Tests",
            exclude: ["Info.plist"],
            resources: [.process("Default-568h@2x.png")],
            cSettings: [
                .define("TEST_AS_SPM"),
            ]),
    ]
)
