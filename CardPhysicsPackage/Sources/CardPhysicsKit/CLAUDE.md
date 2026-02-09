# CardPhysicsKit Source

## File-by-File Reference

### Card.swift -- Data Models
Defines the core card types. All types are `Sendable`, `Codable`.

- **`Suit`** enum: `.hearts`, `.diamonds`, `.clubs`, `.spades`. Raw values are Unicode symbols. Properties: `color` -> `SuitColor` (red/black), `name` -> String.
- **`SuitColor`** enum: `.red`, `.black`.
- **`Rank`** enum: `.nine`(9) through `.ace`(14). Int raw values enable `Comparable`. Properties: `symbol` (display: "9","10","J","Q","K","A"), `name`.
- **`Card`** struct: `id: UUID`, `suit: Suit`, `rank: Rank`. Conforms to `Identifiable`, `Equatable`, `Hashable`. Each instance gets a unique UUID (two cards with same suit/rank are NOT equal). Computed `displayName` e.g. "A♥".

Note: This is a Euchre deck (9 through Ace only, no 2-8).

### PhysicsSettings.swift -- Animation Configuration
`@Observable @MainActor public final class PhysicsSettings: Sendable`

Configurable parameters in four categories:
- **Durations** (seconds): `dealDuration`(0.5), `pickUpDuration`(0.3)
- **Arc heights** (meters): `dealArcHeight`(0.15), `pickUpArcHeight`(0.08)
- **Rotations** (degrees): `dealRotation`(15), `pickUpRotation`(5)
- **Visual**: `cardCurvature`(0.002) -- 0.0=flat, higher=more curve
- **Interaction**: `enableCardTapGesture`(false) -- when true, cards get `GestureComponent` with tap-to-flip

Three presets: `applyRealisticPreset()`, `applySlowMotionPreset()`, `applyFastPreset()`. Presets reset animation/appearance values but do not touch the `enableCardTapGesture` interaction flag.

### CardEntity3D.swift -- 3D Card Factory
`@MainActor enum CardEntity3D` (internal, not public)

Creates `ModelEntity` instances for 3D cards.

**Dimensions** (meters):
- Width: 0.126, Depth: 0.176, Thickness: 0.0004, Corner radius: 0.002

**`makeCard(_:faceUp:enableTap:curvature:) -> ModelEntity`**:
- Generates box mesh (flat) or `CurvedCardMesh` (when curvature > 0)
- Applies PBR material: roughness 0.5, metallic 0.0, specular 0.4, clearcoat 0.8, clearcoatRoughness 0.1
- Gets textures from `CardTextureGenerator.shared` (face or back), falls back to solid color tint
- Adds `CollisionComponent` (box shape)
- Adds `PhysicsBodyComponent`: static friction 0.25, dynamic friction 0.2, restitution 0.05, mode `.kinematic`, CCD enabled, linearDamping 0.1, angularDamping 0.3
- Optionally adds `InputTargetComponent` for tap

### CurvedCardMesh.swift -- Procedural Mesh
`@MainActor enum CurvedCardMesh` (internal)

Generates curved card meshes with parabolic displacement. Cached by curvature value.

- Front face: 17x2 vertex grid with parabolic bow `y = -curvature * (1 - nx^2)`
- Back face: mirrored, normals flipped, UVs mirrored horizontally
- Edge strips: connect front/back along perimeter (top/bottom curved, left/right flat quads)
- Falls back to flat plane if mesh generation fails

### CardPhysicsScene.swift -- RealityKit Scene
`@MainActor public struct CardPhysicsScene: View`

The main 3D scene. Uses `RealityView` to set up and manage the physics world.

**Init parameters**: `settings: PhysicsSettings`, `cameraPosition` (default [0, 0.55, 0.41]), `cameraTarget` (default [0, 0, 0]), `coordinator: SceneCoordinator?`

**Scene setup** (in RealityView content closure):
1. Root entity with `PhysicsSimulationComponent` (gravity [0, -9.8, 0])
2. Camera: `PerspectiveCameraComponent` (FOV 72, near 0.005, far 25.0)
3. Table: wood base (1.4m x 1.0m), 4 rails (0.07m thick, static physics), green felt surface (static physics, friction 0.5/0.4)
4. Lighting: HDRI `room_bg` from `Bundle.module`, fallback 3-point lighting (main spot 400, fill point 150, rim spot 300)
5. Deck: 12 cards (Euchre deck sample) stacked face-down at position [0, y, 0.55] (past the bottom rail)
6. Coordinator action wiring (dealCardsAction, pickUpCardAction, resetCardsAction)
7. When `settings.enableCardTapGesture` is true, each card gets `InputTargetComponent` + `GestureComponent(TapGesture)` for tap-to-flip

**Also defines `SceneCoordinator`**: `@MainActor @Observable public class` with optional async action closures that bridge SwiftUI button presses to scene methods.

**Animation methods**:
- `dealCards(mode:)` -- removes existing cards, recreates deck with correct count, deals via standard or Euchre pattern
- `dealCardsStandard()` -- deals one card at a time cycling sides 2/3/4/1
- `dealCardsEuchre()` -- Euchre dealing in bundles of 2 and 3 across two rounds
- `gatherAndPickUp(corner:)` -- 3-phase animation: gather all cards to corner, pause, lift and remove
- `flipCard(_:)` -- (iOS 26 GestureComponent) flips a card 180 degrees around X axis with 0.25s animation; detects current face via quaternion, temporarily switches to kinematic, restores dynamic after flip
- `resetCards()` -- removes all cards, recreates deck

**Deal pattern**: cycles sides [2, 3, 4, 1] (left, top, right, bottom). Side-dependent speed: side 1 flat and fast (0.5 horizontal, 0.0 up), sides 2/4 moderate (1.1, 0.4), side 3 strongest with reduced spin for stacking (1.4, 0.35, spin 0.8). Fixed 0.3s gap between each card.

### CardPhysicsView.swift -- SwiftUI Wrapper
`@MainActor public struct CardPhysicsView: View`

Top-level view that wraps `CardPhysicsScene` with UI controls.

**State**: `settings` (PhysicsSettings), `showSettings`/`showCameraControls` bools, `sceneKey` UUID (for reset), `cameraPosition`/`cameraTarget` SIMD3, `coordinator` SceneCoordinator.

**UI layout** (ZStack):
- Full-screen `CardPhysicsScene` (ignores safe area)
- Left-side floating VStack of `AnimationButton`s: Deal (context menu for deal modes), Pick Up (context menu for corners), Reset, Camera, Settings
- `CameraControlPanel` (slide-in from left): X/Y/Z sliders for position and look-at target
- `SettingsPanel` (slide-in from right): preset buttons, Deal/Pick Up sliders, Card Appearance curvature, Interaction toggle (Tap to Flip Cards)

**iOS 26 Liquid Glass**: All panels and buttons use `.glassEffect()` instead of `.ultraThinMaterial`/`.background(Color)`. Buttons use `.glassEffect(.regular.tint(color).interactive())` for color-coded glass with press feedback. Panels use `.glassEffect(.regular, in: .rect(cornerRadius:))` for translucent containers.

**Reset**: assigns new `sceneKey` UUID and new `SceneCoordinator` to force scene recreation via `.id()`.

**Internal views** (all in this file):
- `AnimationButton` -- async action button with disabled state during animation
- `CameraControlPanel` -- slider-based camera adjustment
- `SettingsPanel` -- physics parameter adjustment with presets, interaction toggles
- `PresetButton`, `SliderSetting` -- reusable UI components

### CardTextureGenerator.swift -- Card Textures
`@MainActor final class CardTextureGenerator` (internal singleton)

- `shared` singleton, lazily creates and caches textures
- `texture(for: Card) -> TextureResource?` -- renders `CardView` face at 90x126pt @ 5x scale, composites paper grain overlay (8% opacity multiply blend), applies rounded-corner alpha mask, converts to `TextureResource`
- `backTexture() -> TextureResource?` -- renders `CardView` back, applies rounded-corner mask
- Paper grain pre-generated once in init via `ProceduralTextureGenerator.paperGrain()`
- Rounded corner mask uses 50px radius (10pt corner at 5x scale) with CGContext clipping

### CardView.swift -- 2D SwiftUI Card
`public struct CardView: View`

2D card representation used for texture generation and potentially standalone 2D UI.

**Init parameters**: `card: Card`, `isFaceUp`(true), `isHighlighted`(false), `isPlayable`(true), `size: CardSize`(.medium)

**CardSize** enum: `.small`(50pt), `.medium`(70pt), `.large`(90pt). Height = width * 1.4.

**Face (isFaceUp=true)**: cream background, subtle border, center rank+suit, top-left and bottom-right (rotated 180) corner indices. Red for hearts/diamonds, near-black for clubs/spades.

**Back (isFaceUp=false)**: maroon gradient, white outer border, inner border rectangle, diamond center icon.

Accessibility: `accessibilityIdentifier("card_\(suit.name)_\(rank.name)")`

### ProceduralTextureGenerator.swift -- Table PBR Textures
`@MainActor enum ProceduralTextureGenerator` (internal)

Generates all procedural textures using CoreGraphics at 1024x1024 (table) or custom sizes (paper).

**Felt textures** (billiard green):
- `feltAlbedo()` -- base green + mottled patches + 80k fiber noise specs + lint highlights
- `feltRoughness()` -- high roughness (0.85 base) with slight wear variation
- `feltNormal()` -- flat normal base + 10k random micro-bumps

**Wood textures** (mahogany):
- `woodAlbedo()` -- base mahogany + 40k micro-grain pores + horizontal grain lines + 140 wavy growth ring streaks
- `woodRoughness()` -- medium roughness (0.6 base) + grain-aligned pore variations
- `woodNormal()` -- flat base + horizontal grain ridges

**Card texture**:
- `paperGrain(width:height:)` -- cream base + 12k fine speckle noise for paper fiber

**Conversion helpers** (CGImage -> TextureResource):
- `colorTexture(from:)` -- semantic: .color
- `normalTexture(from:)` -- semantic: .normal
- `dataTexture(from:)` -- semantic: .raw

## Architecture Patterns

**Coordinator**: `SceneCoordinator` decouples SwiftUI button presses from RealityKit scene actions via optional async closures. Set up in `RealityView` content closure.

**Factory**: `CardEntity3D.makeCard()` centralizes entity creation with consistent physics/materials.

**Singleton + Cache**: `CardTextureGenerator.shared` generates textures once, caches by card key. `CurvedCardMesh` caches by curvature float.

**Observable State**: `PhysicsSettings` is `@Observable`; SwiftUI views react to changes automatically.

## Physics Implementation

**Collision layers**: Cards collide with felt surface, wood rails, and each other. All use `ShapeResource.generateBox`.

**Physics modes**: Cards start `.kinematic` (scripted), switch to `.dynamic` during deal. Table/rails are `.static`.

**Friction/restitution values**:
| Surface | Static | Dynamic | Restitution |
|---------|--------|---------|-------------|
| Cards   | 0.25   | 0.2     | 0.05        |
| Felt    | 0.5    | 0.4     | 0.1         |
| Rails   | 0.3    | 0.25    | 0.4         |

**CCD** (Continuous Collision Detection) enabled on cards to prevent tunneling through the 0.4mm-thick geometry.

## Common Modifications

**Camera position** -- update in 3 places: `CardPhysicsScene.init()` default, `CardPhysicsView` @State initial, `CameraControlPanel` onReset closure.

**Physics tuning** -- card friction/damping in `CardEntity3D.makeCard()`, table/rail friction in `CardPhysicsScene.createTable()`, gravity in `CardPhysicsScene` body.

**New animation** -- 1) add closure to `SceneCoordinator`, 2) implement method in `CardPhysicsScene`, 3) wire in RealityView content, 4) add button in `CardPhysicsView`.

**Table materials** -- modify `ProceduralTextureGenerator` static methods. Card materials in `CardEntity3D.makeCard()`.

## iOS 26 Features

**Liquid Glass** -- All UI panels and buttons use `.glassEffect()` modifier. Containers use `.glassEffect(.regular, in: shape)`. Interactive buttons use `.glassEffect(.regular.tint(color).interactive(), in: shape)` for color-coded press feedback. Replaces the previous `.ultraThinMaterial` + `.cornerRadius()` + `.shadow()` pattern.

**GestureComponent** -- iOS 26 RealityKit API that attaches SwiftUI gestures directly to entities. Used for tap-to-flip cards. Requires both `InputTargetComponent` and `CollisionComponent` on the entity. Gated behind `PhysicsSettings.enableCardTapGesture` flag (default false). Cards must be dealt/reset after toggling the flag since components are attached at creation time in `createDeck()`.

**APIs investigated but not adopted**:
- ManipulationComponent, ViewAttachmentComponent, PresentationComponent -- visionOS 26 only
- Observable Entity / coordinator simplification -- deferred (current coordinator pattern works well)
