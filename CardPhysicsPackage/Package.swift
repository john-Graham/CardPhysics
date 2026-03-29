// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "CardPhysicsPackage",
    platforms: [
        .iOS("26.4")
    ],
    products: [
        .library(
            name: "CardPhysicsKit",
            targets: ["CardPhysicsKit"]
        )
    ],
    targets: [
        .target(
            name: "CardPhysicsKit",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "CardPhysicsKitTests",
            dependencies: ["CardPhysicsKit"]
        )
    ]
)
