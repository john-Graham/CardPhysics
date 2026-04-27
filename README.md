# CardPhysics

A standalone iOS sandbox for developing and fine-tuning realistic card animations and physics using RealityKit.

## Overview

CardPhysics provides a 3D RealityKit scene with procedurally generated table and felt, HDRI lighting, and a floating control panel for triggering and tweaking card animations in real time. All animation code is isolated from game logic, making it easy to extract and reuse in production card-game apps.

Built with iOS 26's latest features including Liquid Glass design language (`.glassEffect()`) and landscape-only orientation, this sandbox demonstrates advanced RealityKit physics techniques including continuous collision detection (CCD), tribological modeling, and impulse-based throwing mechanics.

## Quick Start

```swift
import SwiftUI
import CardPhysicsKit

struct ContentView: View {
    var body: some View {
        CardPhysicsView()  // Full-featured card physics sandbox
    }
}
```

The `CardPhysicsView` includes the complete 3D scene with floating controls, settings panels, and animation triggers.

## Project Structure

```
CardPhysics/
├── CardPhysicsPackage/              # Swift Package with all core logic (CardPhysicsKit library)
│   ├── Package.swift                # swift-tools-version: 6.3, iOS 26.4+
│   └── Sources/CardPhysicsKit/      # 49 files organized in modular folders
│       ├── Core/Models/             # Card, Suit, Rank, CardWearComponent
│       ├── Configuration/           # PhysicsSettings, SceneCoordinator, themes
│       ├── Scene/                   # CardPhysicsScene + Setup/Environment extensions
│       ├── Entities/                # CardEntity3D, HandEntity3D (factory pattern)
│       ├── Geometry/                # CurvedCardMesh (procedural mesh generation)
│       ├── Rendering/               # Texture generators, CardView
│       ├── Animations/              # Scene extensions: Wear, Dealing, PickUp, InHands
│       ├── Effects/                 # ParticleEffects, SkyboxEntity
│       ├── UI/                      # CardPhysicsView + Components + Panels (11 panels)
│       ├── Storage/                 # Image persistence for custom cards/rooms
│       └── Resources/               # HDRI environment, room backgrounds
├── CardPhysicsApp/                  # Xcode project wrapper (thin shell)
│   ├── CardPhysicsApp.xcodeproj
│   ├── CardPhysicsApp/              # Main app target (entry point + ContentView)
│   ├── CardPhysicsAppTests/         # Unit tests
│   ├── CardPhysicsAppUITests/       # UI automation tests
│   └── card-physics.rtf             # Reference doc on RealityKit card physics theory
└── Config/                          # Reserved for configuration files
```

## Getting Started

### Build and Run

1. Open `CardPhysicsApp/CardPhysicsApp.xcodeproj` in Xcode 16.3+
2. Select an iOS 26.4+ simulator or device
3. Build and run the CardPhysicsApp scheme
4. Use the floating buttons to trigger animations
5. Open the Settings panel to adjust physics parameters in real time

### Test the Swift Package

`CardPhysicsPackage` is iOS-only. Use Xcode's iOS simulator test runner rather than bare `swift test`, which builds for the host macOS platform.

```bash
cd CardPhysicsPackage
xcodebuild test -scheme CardPhysicsPackage -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4.1'
```

### Installing on Physical Device

For testing on John's iPhone (iOS 26.3):

```bash
# Build and deploy
xcrun devicectl device install app --device 00008150-0010281E2261401C \
  ~/Library/Developer/Xcode/DerivedData/CardPhysicsApp-*/Build/Products/Debug-iphoneos/CardPhysicsApp.app

# Launch
xcrun devicectl device process launch --device 00008150-0010281E2261401C johndgraham.CardPhysicsApp
```

## Features

### Core Animations

| Action | Description | Status |
|--------|-------------|--------|
| **Deal Cards** | Multiple deal modes: 4, 12, 20 cards, Euchre, In-Hands | ✅ Active |
| **Pick Up Cards** | Gather and lift cards from table to hand positions | ✅ Active |
| **In-Hands Fanning** | Spread cards in arc formations with tap-to-flip | ✅ Active |
| **Reset** | Return scene to initial state | ✅ Active |

### Visual Customization

- **Card Design**: Custom face/back images, wear effects, curvature
- **Table Themes**: Procedural felt and wood materials with color customization
- **Room Backgrounds**: 360° panoramic environments (3 included, custom upload supported)
- **Lighting**: HDRI-based realistic lighting with fallback 3-point setup
- **Effects**: Particle systems for dust and felt disturbance

### Physics Settings

Real-time sliders for:
- Deal animation: duration, arc height, rotation, velocity, spin
- Pick up animation: gather speed, lift height, timing
- In-hands positioning: fan spread, height, rotation per player
- Card properties: curvature, wear progression, friction

### Presets

- **Realistic** — Balanced, natural-looking defaults
- **Slow Motion** — Exaggerated for detailed observation
- **Fast** — Snappy for fast-paced gameplay

## Architecture Highlights

### Modular Organization
49 files organized across 10 feature-based folders in CardPhysicsKit. Major components split using Swift extensions:
- **CardPhysicsScene**: 1,466 → 217 lines (85% reduction via 7 extension files)
- **CardPhysicsView**: 1,797 → 328 lines (82% reduction via component extraction)
- **CardView**: 757 → 133 lines (82% reduction via 4 files: FaceStyles, BackStyles, PipLayouts)
- **ProceduralTextureGenerator**: 438 → 57 lines (87% reduction via 4 files: Felt, Wood, CardWear)
- **PanelState**: `@Observable` class consolidating 10 panel visibility booleans

### Design Patterns
- **Factory Pattern**: `CardEntity3D.makeCard()` centralizes entity creation
- **Coordinator Pattern**: `SceneCoordinator` decouples SwiftUI from RealityKit
- **Singleton + Cache**: `CardTextureGenerator.shared` generates textures once
- **Observable State**: `@Observable` classes for automatic SwiftUI reactivity

### iOS 26 Features
- **Liquid Glass** design language for all floating panels and buttons
- **GestureComponent** for entity-level tap gestures (feature-flagged)
- **Landscape-only orientation** locked at app launch

## Requirements

- **iOS 26.4+** (currently 26.4)
- **Xcode 16.3+**
- **Swift 6.3** with strict concurrency enabled by default in Swift 6 language mode

## Documentation

- **CLAUDE.md** — Comprehensive project guide (conventions, architecture, open issues)
- **CardPhysicsPackage/CLAUDE.md** — Framework architecture and patterns
- **CardPhysicsKit/CLAUDE.md** — Detailed file-by-file reference
- **card-physics.rtf** — Deep technical reference on RealityKit card physics theory
- **Resources/Rooms/** — Asset specifications and sourcing guides for room backgrounds

## Physics Deep Dive

The `card-physics.rtf` reference document covers:
- Physics body modes (static/kinematic/dynamic) and state transitions
- Continuous Collision Detection (CCD) for thin objects
- Tribological modeling: friction and restitution coefficients
- Linear and angular impulse calculations for realistic throwing
- Solver iteration tuning for stack stability
- Performance optimization for 52-card scenes

## Roadmap

See [GitHub Issues](https://github.com/yourusername/CardPhysics/issues) for planned enhancements:
- #1 Deal button: long-press menu with multiple deal modes
- #2 Remove Play Card button
- #3 Pick Up button: long-press menu to gather cards by corner
- #4 Remove Slide button
- #5 Settings panel: reorganize sliders grouped by animation type
