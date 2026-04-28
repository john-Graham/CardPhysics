// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "CardPhysicsPackage",
    platforms: [
        .iOS("26.4")
    ],
    products: [
        .library(
            name: "CardPhysicsSandbox",
            targets: ["CardPhysicsSandbox"]
        )
    ],
    dependencies: [
        // CardEngine consumed via local path during development.
        // After CardEngine v0.1.0 is tagged and pushed (Phase 9), this can be switched to:
        //   .package(url: "https://github.com/john-Graham/CardEngine.git", .upToNextMinor(from: "0.1.0"))
        .package(path: "../../../../../CardEngine")
    ],
    targets: [
        .target(
            name: "CardPhysicsSandbox",
            dependencies: [
                .product(name: "CardEngine", package: "CardEngine")
            ]
        ),
        .testTarget(
            name: "CardPhysicsSandboxTests",
            dependencies: ["CardPhysicsSandbox"]
        )
    ]
)
