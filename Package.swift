// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Img2Cubemap",
    platforms: [
        .macOS(.v11),
        .iOS(.v15),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Img2Cubemap",
            targets: ["Img2Cubemap"]),
    ],
    dependencies: [
        .package(url: "https://github.com/nhiroyasu/OpenEXRWrapper.git", from: "0.1.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Img2Cubemap",
            dependencies: [
                .product(name: "OpenEXRWrapper", package: "OpenEXRWrapper")
            ],
            resources: [
                .process("Shader/"),
            ]),
        .testTarget(
            name: "Img2CubemapTests",
            dependencies: ["Img2Cubemap"],
            resources: [
                .process("Resources/test_exr.exr")
            ]
        ),
    ]
)
