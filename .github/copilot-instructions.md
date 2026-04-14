# CardPhysics Copilot Instructions

## Build, test, and lint commands

Run from the repository root unless noted.

```bash
# Discover valid simulator destinations first
xcodebuild -showdestinations -project CardPhysicsApp/CardPhysicsApp.xcodeproj -scheme CardPhysicsApp

# Build app shell + package integration
xcodebuild build \
  -project CardPhysicsApp/CardPhysicsApp.xcodeproj \
  -scheme CardPhysicsApp \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4'

# Build CardPhysicsKit scheme directly
xcodebuild build \
  -project CardPhysicsApp/CardPhysicsApp.xcodeproj \
  -scheme CardPhysicsKit \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4'

# Run full project tests configured in CardPhysicsApp scheme
xcodebuild test \
  -project CardPhysicsApp/CardPhysicsApp.xcodeproj \
  -scheme CardPhysicsApp \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4'

# Run a single UI test
xcodebuild test \
  -project CardPhysicsApp/CardPhysicsApp.xcodeproj \
  -scheme CardPhysicsApp \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4' \
  -only-testing:CardPhysicsAppUITests/CardPhysicsAppUITests/testCaptureInHandsFan
```

Package-level docs also reference:

```bash
cd CardPhysicsPackage && swift test
cd CardPhysicsPackage && swift test --filter tableGeometrySymmetry
```

`CardPhysicsKit` uses iOS frameworks (RealityKit/SwiftUI/UIKit), so prefer `xcodebuild` simulator commands for reliable CLI builds/tests.

No dedicated lint command is configured (no SwiftLint/SwiftFormat config or lint workflow in this repo).

## High-level architecture

- `CardPhysicsApp` is intentionally a thin shell: `CardPhysicsAppApp` only handles app startup/orientation lock, and `ContentView` hosts `CardPhysicsView`.
- The main control flow is **SwiftUI controls -> coordinator closures -> scene actions**:
  - `UI/CardPhysicsView.swift` owns `PhysicsSettings`, `PanelState`, and `SceneCoordinator`, and triggers actions (`deal`, `pick up`, `fan in hands`) through coordinator async closures.
  - `Configuration/SceneCoordinator.swift` is the bridge layer between the UI and RealityKit scene methods.
  - `Scene/CardPhysicsScene.swift` owns `RealityView` lifecycle/state and wires coordinator closures to scene methods.
- Scene responsibilities are intentionally split:
  - `Scene/CardPhysicsScene+Setup.swift`: camera, table, rails/felt physics, initial deck creation.
  - `Scene/CardPhysicsScene+Environment.swift`: HDRI/fallback lighting, skybox updates, table material hot-swaps.
  - `Animations/CardPhysicsScene+*.swift`: dealing, pickup, in-hands fan/flip, wear, and safe movement utilities.
- 3D card/rendering pipeline:
  - `Entities/CardEntity3D.makeCard(...)` is the canonical factory for card mesh + materials + collision/physics setup.
  - `Rendering/CardTextureGenerator.shared` handles face/back generation and caching, including wear overlays and custom-image composition.
  - `Core/CollisionUtils` (used via `moveCardSafely`) is the shared transform validation layer to prevent table/rail penetration during scripted movement.

## Key conventions

- Keep app target minimal; add behavior in `CardPhysicsKit` instead of `CardPhysicsApp` whenever possible.
- `CardPhysicsScene` functionality is split by extension file responsibility (`+Setup`, `+Environment`, `+Dealing`, `+PickUp`, `+InHands`, `+Wear`, `+SafeMovement`) rather than growing the base file.
- Shared mutable UI/scene settings use `@Observable` + `@MainActor` (`PhysicsSettings`, `SceneCoordinator`, `PanelState`).
- Side indexing is consistent across dealing, fanning, and UI labels: **1=bottom, 2=left, 3=top, 4=right**.
- Physics mode transitions are intentional: cards start kinematic, become dynamic for thrown/dealt motion, and have physics stripped/restored during in-hands fan mode.
- Scripted repositioning paths (stacking, pickup, flip-on-table) move cards in kinematic mode and clear `PhysicsMotionComponent`; impulse-style dealing uses dynamic bodies.
- Use `moveCardSafely`/`CollisionUtils.validateCardTransform` for scripted movement to avoid table/rail penetration.
- Card domain uses a Euchre-style deck model (`Rank` is 9 through Ace), and `createDeck(count:)` cycles those cards when generating sample decks.
- Visual style follows iOS 26 Liquid Glass patterns (`.glassEffect(...)`) for control groups, buttons, and settings panels.
- Test style split is intentional: package/app unit tests use Apple Testing (`@Test`, `#expect`), while UI automation remains XCTest (`XCTestCase`).
