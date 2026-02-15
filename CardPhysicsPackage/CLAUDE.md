# CardPhysicsPackage

## Overview
Local Swift Package providing the CardPhysicsKit framework -- a 3D card physics and rendering system built on RealityKit. Handles realistic card animations, physics simulation, procedural PBR materials, and scene management.

## Package Structure
```
CardPhysicsPackage/
├── Package.swift
├── Sources/
│   └── CardPhysicsKit/       # Modular folder-based architecture (41 files)
│       ├── Core/Models/      # Card, CardWearComponent
│       ├── Configuration/    # Settings, SceneCoordinator, themes
│       ├── Scene/            # CardPhysicsScene + Setup/Environment extensions
│       ├── Entities/         # CardEntity3D, HandEntity3D
│       ├── Geometry/         # CurvedCardMesh
│       ├── Rendering/        # Texture generators, CardView
│       ├── Animations/       # Scene extensions: Wear, Dealing, PickUp, InHands
│       ├── Effects/          # ParticleEffects, SkyboxEntity
│       ├── UI/               # CardPhysicsView + Components/ + Panels/
│       ├── Storage/          # Image storage utilities
│       └── Resources/        # HDRI environment (room_bg.exr)
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
- **Core/Models**: `Card`, `Suit`, `Rank`, `CardWearComponent` -- pure data, `Sendable`
- **Configuration**: `PhysicsSettings`, `SceneCoordinator`, `TableThemeSettings`, `RoomEnvironment` -- observable settings
- **Scene**: `CardPhysicsScene` (217 lines) + 2 extensions (Setup, Environment) for scene management
- **Entities**: `CardEntity3D` (factory), `HandEntity3D` -- 3D entity creation
- **Geometry**: `CurvedCardMesh` -- procedural parabolic mesh generation
- **Rendering**: `CardTextureGenerator`, `ProceduralTextureGenerator`, `CardView` -- PBR textures and 2D views
- **Animations**: 4 scene extensions (Wear, Dealing, PickUp, InHands) -- animation logic split from scene
- **Effects**: `ParticleEffects`, `SkyboxEntity` -- visual effects
- **UI**: `CardPhysicsView` (328 lines) + 4 Components + 11 Panels -- modular SwiftUI interface
- **Storage**: Image persistence for custom card faces/backs and room backgrounds

**Key patterns**: Modular folder structure (feature-based), Extensions for code splitting (6 scene extensions), Factory pattern (CardEntity3D), Singleton with caching (CardTextureGenerator), Coordinator pattern (SceneCoordinator), Observable state (@Observable).

**File reductions**: CardPhysicsView: 1,797 → 328 lines (82% reduction). CardPhysicsScene: 1,466 → 217 lines (85% reduction).
