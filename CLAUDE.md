# CardPhysics

## Project Overview
iOS sandbox app for developing and tuning realistic card animations and physics using RealityKit. All animation code is isolated from game logic for easy extraction into production card-game apps.

**Role in the broader workspace:** CardPhysics is the live tuning playground. Stable engine code is extracted into the standalone `CardEngine` repo (https://github.com/john-Graham/CardEngine), which is consumed as a git submodule by `../Euchre/` and any future card games. Tune here → extract to CardEngine → bump submodule in Euchre. The sandbox UI for live parameter tuning stays in this repo and is not extracted.

## Directory Layout
```
CardPhysics/
├── CardPhysicsPackage/          # Swift Package with all core logic (CardPhysicsKit library)
│   ├── Package.swift            # swift-tools-version: 6.3, iOS 26.4+
│   ├── Sources/CardPhysicsKit/  # 3D scene, physics, entities, textures, UI
│   └── Tests/CardPhysicsKitTests/
├── CardPhysicsApp/              # Xcode project wrapper (thin shell around CardPhysicsKit)
│   ├── CardPhysicsApp.xcodeproj
│   ├── CardPhysicsApp/          # Main app target (entry point + ContentView)
│   ├── CardPhysicsAppTests/     # Unit tests
│   ├── CardPhysicsAppUITests/   # UI automation tests
│   └── card-physics.rtf         # Reference doc on RealityKit card physics theory
├── Config/                      # Reserved for configuration files (currently empty)
└── README.md
```

## Build and Run
1. Open `CardPhysicsApp/CardPhysicsApp.xcodeproj` in Xcode 16.3+
2. Select an iOS 26.4+ simulator or device
3. Build and run the CardPhysicsApp scheme

The app is built through the Xcode project, which depends on `CardPhysicsPackage/` as a local Swift package.

### Installing on Physical Device
John's iPhone (iOS 26.3) is usually available for installation, either:
- Connected via USB (device ID: `00008150-0010281E2261401C`)
- On the same WiFi network for wireless deployment

To install via command line:
```bash
# Build and deploy
xcrun devicectl device install app --device 00008150-0010281E2261401C \
  ~/Library/Developer/Xcode/DerivedData/CardPhysicsApp-*/Build/Products/Debug-iphoneos/CardPhysicsApp.app

# Launch
xcrun devicectl device process launch --device 00008150-0010281E2261401C johndgraham.CardPhysicsApp
```

## Key Conventions
- **Swift 6.3** with strict concurrency enabled by default in Swift 6 language mode
- **iOS 26.4+** minimum deployment target (currently 26.4)
- **SwiftUI + RealityKit** for all UI and 3D rendering
- **Modular folder structure** in CardPhysicsKit: feature-based organization (Core, Configuration, Scene, Entities, Geometry, Rendering, Animations, Effects, UI, Storage)
- **Swift extensions for code splitting**: Large classes (CardPhysicsScene, CardView, ProceduralTextureGenerator, CardPhysicsView) are split across multiple extension files to keep each file focused
- **`@Observable` PanelState**: Panel visibility state consolidated into a single `@Observable` class instead of scattered `@State` booleans
- **Liquid Glass** design language for all floating panels and buttons (iOS 26 `.glassEffect`)
- **GestureComponent** (iOS 26 RealityKit) for entity-level tap gestures (feature-flagged)
- **Apple Testing framework** for unit tests
- App target is intentionally minimal -- all logic lives in CardPhysicsKit
- Landscape-only orientation, locked at app launch

## Architecture
- `CardPhysicsKit` is the framework with all substance: 3D scene management, physics simulation, procedural texture generation, card entities, curved mesh generation, animation triggers, and the interactive SwiftUI control panel
- **Modular organization**: feature-based folders (Scene/, Animations/, UI/, Rendering/, etc.)
- **Extension-based splitting**: CardPhysicsScene methods distributed via Swift extensions (Setup, Environment, Wear, Dealing, PickUp, InHands). CardView split by face/back/pip layouts. ProceduralTextureGenerator split by material type (Felt, Wood, CardWear)
- **Panel state management**: `PanelState` `@Observable` class consolidates panel visibility flags (replaces scattered `@State` vars in CardPhysicsView)
- `CardPhysicsApp` is a thin shell: `@main` entry point, orientation lock, `ContentView` wrapping `CardPhysicsView`

## Open GitHub Issues (planned changes)
- #1 Deal button: add long-press menu with multiple deal modes
- #2 Remove Play Card button
- #3 Pick Up button: long-press menu to gather and pick up cards by corner
- #4 Remove Slide button
- #5 Settings panel: reorganize sliders grouped by animation type
