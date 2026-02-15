# CardPhysics

## Project Overview
iOS sandbox app for developing and tuning realistic card animations and physics using RealityKit. All animation code is isolated from game logic for easy extraction into production card-game apps.

## Directory Layout
```
CardPhysics/
├── CardPhysicsPackage/          # Swift Package with all core logic (CardPhysicsKit library)
│   ├── Package.swift            # swift-tools-version: 6.2, iOS 26+
│   ├── Sources/CardPhysicsKit/  # 3D scene, physics, entities, textures, UI
│   └── Tests/CardPhysicsKitTests/
├── CardPhysicsApp/              # Xcode project wrapper (thin shell around CardPhysicsKit)
│   ├── CardPhysicsApp.xcodeproj
│   ├── CardPhysicsApp/          # Main app target (entry point + ContentView)
│   ├── CardPhysicsAppTests/     # Unit tests
│   ├── CardPhysicsAppUITests/   # UI automation tests
│   └── card-physics.rtf         # Reference doc on RealityKit card physics theory
├── CardPhysics/                 # Alternate @main entry using SwiftUI App protocol
├── Sources/CardPhysicsApp/      # SPM executable target (@main stub, placeholder only)
├── Config/                      # Reserved for configuration files (currently empty)
├── Package.swift                # Root SPM manifest (swift-tools-version: 6.2)
├── create_project.sh            # One-time script that scaffolded the Xcode project
└── README.md
```

## Build and Run
1. Open `CardPhysicsApp/CardPhysicsApp.xcodeproj` in Xcode 16.3+
2. Select an iOS 26+ simulator or device
3. Build and run the CardPhysicsApp scheme

The root `Package.swift` defines an SPM executable target (`Sources/CardPhysicsApp/`) but the real app is built through the Xcode project, which depends on `CardPhysicsPackage/` as a local Swift package.

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
- **Swift 6.1+** with StrictConcurrency and ExistentialAny enabled in the package
- **iOS 26.0+** minimum deployment target (currently 26.2)
- **SwiftUI + RealityKit** for all UI and 3D rendering
- **Modular folder structure** in CardPhysicsKit: feature-based organization (Core, Configuration, Scene, Entities, Geometry, Rendering, Animations, Effects, UI, Storage) with 41 files across 10 top-level folders
- **Swift extensions for code splitting**: Large classes split into focused extension files (CardPhysicsScene: 6 files, CardPhysicsView: components/panels extracted)
- **Liquid Glass** design language for all floating panels and buttons (iOS 26 `.glassEffect`)
- **GestureComponent** (iOS 26 RealityKit) for entity-level tap gestures (feature-flagged)
- **Apple Testing framework** for unit tests
- App target is intentionally minimal -- all logic lives in CardPhysicsKit
- Landscape-only orientation, locked at app launch

## Architecture
- `CardPhysicsKit` is the framework with all substance (41 files organized in modular folders): 3D scene management, physics simulation, procedural texture generation, card entities, curved mesh generation, animation triggers, and the interactive SwiftUI control panel
- **Modular organization**: Feature-based folders (Scene/, Animations/, UI/, Rendering/) replace flat structure. Large files split: CardPhysicsView (1,797→328 lines), CardPhysicsScene (1,466→217 lines)
- **Extension-based splitting**: CardPhysicsScene methods distributed across 6 files via Swift extensions (Setup, Environment, Wear, Dealing, PickUp, InHands)
- `CardPhysicsApp` is a thin shell: `@main` entry point, orientation lock, `ContentView` wrapping `CardPhysicsView`
- `CardPhysics/CardPhysicsApp.swift` is a separate `@main` entry using the SwiftUI `App` protocol that imports CardPhysicsKit directly

## Open GitHub Issues (planned changes)
- #1 Deal button: add long-press menu with multiple deal modes
- #2 Remove Play Card button
- #3 Pick Up button: long-press menu to gather and pick up cards by corner
- #4 Remove Slide button
- #5 Settings panel: reorganize sliders grouped by animation type
