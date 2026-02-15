# CardPhysicsKit Source

## Folder Structure

```
CardPhysicsKit/
├── Core/Models/              # Foundational data types
│   ├── Card.swift            # Card, Suit, Rank, SuitColor enums
│   └── CardWearComponent.swift  # Wear tracking component
├── Configuration/            # Settings and coordinator
│   ├── PhysicsSettings.swift    # Animation parameters and presets
│   ├── CardDesignConfiguration.swift  # Card appearance settings
│   ├── TableThemeSettings.swift     # Table materials and shadows
│   ├── RoomEnvironment.swift        # Skybox environments
│   └── SceneCoordinator.swift       # SwiftUI ↔ RealityKit bridge (DealMode, GatherCorner enums)
├── Scene/                    # Main 3D scene and setup
│   ├── CardPhysicsScene.swift       # Core scene struct with RealityView
│   ├── CardPhysicsScene+Setup.swift # Camera, table, deck creation
│   └── CardPhysicsScene+Environment.swift  # Lighting, skybox, materials
├── Entities/                 # 3D entity factories
│   ├── CardEntity3D.swift    # Card mesh generation with PBR materials
│   └── HandEntity3D.swift    # In-hands card positioning
├── Geometry/                 # Procedural mesh generation
│   └── CurvedCardMesh.swift  # Parabolic card curvature
├── Rendering/                # Textures and 2D views
│   ├── CardTextureGenerator.swift      # Card face/back textures with caching
│   ├── ProceduralTextureGenerator.swift # Felt and wood PBR materials
│   └── CardView.swift                  # 2D SwiftUI card rendering
├── Animations/               # Scene animation extensions
│   ├── CardPhysicsScene+Wear.swift    # Collision tracking and wear application
│   ├── CardPhysicsScene+Dealing.swift # Deal modes and card distribution
│   ├── CardPhysicsScene+PickUp.swift  # Gather and pickup animations
│   └── CardPhysicsScene+InHands.swift # Fanning, flipping, position updates
├── Effects/                  # Visual effects
│   ├── ParticleEffects.swift # Dust and felt disturbance particles
│   └── SkyboxEntity.swift    # 360° room backgrounds
├── UI/                       # SwiftUI interface
│   ├── CardPhysicsView.swift         # Main view wrapper (328 lines)
│   ├── Components/                   # Reusable UI elements
│   │   ├── AnimationButton.swift     # Async action button with glass effect
│   │   ├── PresetButton.swift        # Settings preset button
│   │   ├── SliderSetting.swift       # Labeled slider with value display
│   └── RoomThumbnail.swift       # Environment selector thumbnail
│   └── Panels/                       # Settings panels (11 total)
│       ├── CameraControlPanel.swift  # Camera position and target sliders
│       ├── DealSettingsPanel.swift   # Deal animation parameters
│       ├── PickUpSettingsPanel.swift # Pickup animation parameters
│       ├── InHandsSettingsPanel.swift # Per-player hand settings
│       ├── CardDesignPanel.swift     # Card appearance and custom images
│       ├── RoomBackgroundPanel.swift # Skybox selection and rotation
│       ├── TableThemePanel.swift     # Felt/wood colors and shadows
│       ├── LightingPanel.swift       # HDRI and fallback lighting
│       ├── CardEffectsPanel.swift    # Card curvature and wear
│       ├── EnvironmentalEffectsPanel.swift # Particles and effects
│       └── RoomPhotoPicker.swift     # Custom room image picker
├── Storage/                  # Image persistence
│   ├── CardImageStorage.swift  # Card face/back image storage
│   ├── RoomImageStorage.swift  # Custom skybox image storage
│   └── CardImagePicker.swift   # PhotosPicker and camera wrappers
└── Resources/                # Assets
    └── room_bg.exr           # Default HDRI environment
```

## Key Files Reference

### Core/Models/Card.swift
Foundational card data types. All types are `Sendable`, `Codable`.

- **`Suit`** enum: `.hearts`, `.diamonds`, `.clubs`, `.spades`. Raw values are Unicode symbols. Properties: `color` -> `SuitColor` (red/black), `name` -> String.
- **`Rank`** enum: `.nine`(9) through `.ace`(14). Int raw values enable `Comparable`. Properties: `symbol`, `name`.
- **`Card`** struct: `id: UUID`, `suit: Suit`, `rank: Rank`. Conforms to `Identifiable`, `Equatable`, `Hashable`. Computed `displayName` e.g. "A♥".

Note: This is a Euchre deck (9 through Ace only, no 2-8).

### Configuration/PhysicsSettings.swift
`@Observable @MainActor public final class PhysicsSettings: Sendable`

Animation parameters: durations (seconds), arc heights (meters), rotations (degrees), card curvature (meters), interaction toggles.

Three presets: `applyRealisticPreset()`, `applySlowMotionPreset()`, `applyFastPreset()`.

### Configuration/SceneCoordinator.swift
`@Observable @MainActor public class SceneCoordinator`

Bridges SwiftUI button presses to RealityKit scene actions via optional async closures. Also defines:
- **`DealMode`** enum: `.four`, `.twelve`, `.twenty`, `.euchre`, `.inHands`
- **`GatherCorner`** enum: `.bottomLeft`, `.topLeft`, `.topRight`, `.bottomRight`

### Scene/CardPhysicsScene.swift
`@MainActor public struct CardPhysicsScene: View`

Main 3D scene (217 lines, down from 1,466). Contains:
- RealityView setup with root entity, physics simulation, camera
- @State properties (now `internal` for extension access): cards, positions, materials cache, wear tracking
- Scene initialization and configuration wiring
- `resetCards()` method

Implementation methods split across 5 extension files (Setup, Environment, Wear, Dealing, PickUp, InHands).

### Scene/CardPhysicsScene+Setup.swift
Extension with scene setup methods:
- `createCamera()` - Perspective camera with FOV 72°
- `createTable()` - Wood base, 4 rails, felt surface with physics
- `createDeck(count:)` - Generate card entities with textures

### Scene/CardPhysicsScene+Environment.swift
Extension with environment methods:
- `setupLighting()` - HDRI or fallback 3-point lighting
- `updateSkybox()` - 360° panoramic backgrounds
- `updateTableMaterials()` - Felt and wood PBR textures

### Animations/CardPhysicsScene+Wear.swift
Extension with collision and wear tracking:
- `handleCollision(entityA:entityB:)` - Card-to-card collision detection
- `incrementCardWear(_:)` - Track wear progression
- `applyWearTexture(to:)` - Update card textures with wear

### Animations/CardPhysicsScene+Dealing.swift
Extension with dealing logic:
- `dealCards(mode:)` - Public entry point for all deal modes
- `dealCardsStandard()` - Cycle through 4 sides
- `dealCardsEuchre()` - Bundles of 2 and 3 in two rounds
- `dealCardsInHands()` - Direct to hand positions
- `dealSingleCard(_:toSide:delay:randomSpread:)` - Animated card distribution

### Animations/CardPhysicsScene+PickUp.swift
Extension with pickup animations:
- `gatherAndPickUp(corner:)` - 3-phase gather, pause, lift

### Animations/CardPhysicsScene+InHands.swift
Extension with in-hands animations:
- `fanCardsInHands()` - Spread cards in arc formations
- `flipCard(_:)` - Tap-to-flip with 180° rotation
- `updateInHandsCardPositions()` - Real-time slider updates

### Entities/CardEntity3D.swift
`@MainActor enum CardEntity3D`

Factory for creating card entities:
- Dimensions: 0.126m × 0.176m × 0.0004m, corner radius 0.002m
- `makeCard(_:faceUp:enableTap:curvature:)` - Returns ModelEntity with PBR material, physics, optional curved mesh
- Materials: roughness 0.5, metallic 0.0, specular 0.4, clearcoat 0.8

### UI/CardPhysicsView.swift
`@MainActor public struct CardPhysicsView: View`

Top-level wrapper (328 lines, down from 1,797). Contains:
- @State for settings, panel visibility, camera, coordinator
- Full-screen CardPhysicsScene
- Left-side floating button stack (Deal, Pick Up, Reset, Camera, Settings)
- Slide-in panels for settings
- Liquid Glass design with `.glassEffect()` modifiers

All embedded types extracted to Components/ and Panels/ subdirectories.

## Architecture Patterns

**Modular Folder Structure**: Feature-based top-level organization (Scene/, Animations/, UI/, Rendering/) with clear architectural layers.

**Extensions for Code Splitting**: CardPhysicsScene split into 6 files via Swift extensions. Extensions use `internal` access to shared @State properties.

**Coordinator Pattern**: SceneCoordinator decouples SwiftUI controls from RealityKit scene actions via optional async closures.

**Factory Pattern**: CardEntity3D.makeCard() centralizes entity creation with consistent physics/materials.

**Singleton + Cache**: CardTextureGenerator.shared generates textures once, caches by card key.

**Observable State**: PhysicsSettings, SceneCoordinator, TableThemeSettings use @Observable for automatic SwiftUI reactivity.

## iOS 26 Features

**Liquid Glass**: All UI uses `.glassEffect()` modifier. Containers use `.glassEffect(.regular, in: shape)`. Interactive buttons use `.glassEffect(.regular.tint(color).interactive(), in: shape)`.

**GestureComponent**: iOS 26 RealityKit API for entity-level tap gestures. Gated behind `PhysicsSettings.enableCardTapGesture` flag (default false).

## Common Modifications

**Add new animation**: 1) Add closure to SceneCoordinator, 2) Implement method in appropriate CardPhysicsScene extension, 3) Wire in RealityView content, 4) Add button in CardPhysicsView or panel.

**Add new panel**: 1) Create file in UI/Panels/, 2) Add @State bool for visibility in CardPhysicsView, 3) Add panel to body with `.offset()` for slide-in animation.

**Add new setting**: 1) Add property to appropriate Configuration/ file (PhysicsSettings, TableThemeSettings, etc.), 2) Add slider to relevant panel, 3) Wire to scene via coordinator if needed.
