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
        .package(url: "git@github.com:john-Graham/CardEngine.git", from: "0.2.0")
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
