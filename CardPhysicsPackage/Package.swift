// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CardPhysicsPackage",
    platforms: [
        .iOS(.v18)
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
            ],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "CardPhysicsKitTests",
            dependencies: ["CardPhysicsKit"]
        )
    ]
)
