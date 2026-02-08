# CardPhysicsPackage

## Overview
Local Swift Package providing the CardPhysicsKit framework -- a 3D card physics and rendering system built on RealityKit. Handles realistic card animations, physics simulation, procedural PBR materials, and scene management.

## Package Structure
```
CardPhysicsPackage/
├── Package.swift
├── Sources/
│   └── CardPhysicsKit/
│       ├── Resources/         # HDRI environment (room_bg.exr)
│       ├── Card.swift
│       ├── CardEntity3D.swift
│       ├── CardPhysicsScene.swift
│       ├── CardPhysicsView.swift
│       ├── CardTextureGenerator.swift
│       ├── CardView.swift
│       ├── CurvedCardMesh.swift
│       ├── PhysicsSettings.swift
│       └── ProceduralTextureGenerator.swift
└── Tests/
    └── CardPhysicsKitTests/
        └── CardPhysicsKitTests.swift
```

## Package Configuration (Package.swift)
- **Swift Tools Version**: 6.2
- **Minimum Platform**: iOS 26.0
- **Product**: `CardPhysicsKit` (library)
- **Swift Settings**: `ExistentialAny` (upcoming), `StrictConcurrency` (experimental)
- **Resources**: `Sources/CardPhysicsKit/Resources/` processed at build time

## System Framework Dependencies
- SwiftUI -- UI layer and 2D card rendering
- RealityKit -- 3D rendering, physics simulation, PBR materials
- CoreGraphics -- Procedural texture generation

No external third-party dependencies.

## Adding as Local Package
In Xcode: File > Add Package Dependencies > Add Local > select `CardPhysicsPackage/` directory. Then import:
```swift
import CardPhysicsKit
```

## Quick Usage
```swift
// Simplest integration -- drop-in view with built-in controls
CardPhysicsView()

// Custom configuration
let settings = PhysicsSettings()
settings.dealDuration = 1.5
CardPhysicsScene(
    settings: settings,
    cameraPosition: [0, 0.55, 0.41],
    cameraTarget: [0, 0, 0]
)
```

## Build & Test
```bash
cd CardPhysicsPackage
swift build
swift test
```
Or in Xcode: Cmd+B to build, Cmd+U to test.

## Architecture Summary
- **Data models**: `Card`, `Suit`, `Rank`, `PhysicsSettings` -- pure data, `Sendable`
- **3D entities**: `CardEntity3D` (factory), `CurvedCardMesh` (procedural mesh)
- **Scene**: `CardPhysicsScene` (RealityKit scene with table, lighting, physics)
- **Views**: `CardPhysicsView` (SwiftUI wrapper with controls), `CardView` (2D card)
- **Textures**: `CardTextureGenerator` (card faces/backs), `ProceduralTextureGenerator` (table PBR)
- **Coordination**: `SceneCoordinator` bridges SwiftUI controls to RealityKit scene actions

Key patterns: Factory pattern (CardEntity3D), Singleton with caching (CardTextureGenerator), Coordinator pattern (SceneCoordinator), Observable state (@Observable PhysicsSettings).
