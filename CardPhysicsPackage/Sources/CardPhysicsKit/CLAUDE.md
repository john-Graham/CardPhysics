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

Configurable parameters in three categories:
- **Durations** (seconds): `dealDuration`(0.5), `playDuration`(0.4), `pickUpDuration`(0.3), `slideDuration`(0.6)
- **Arc heights** (meters): `dealArcHeight`(0.15), `playArcHeight`(0.12), `pickUpArcHeight`(0.08)
- **Rotations** (degrees): `dealRotation`(15), `playRotation`(10), `pickUpRotation`(5)
- **Visual**: `cardCurvature`(0.002) -- 0.0=flat, higher=more curve

Three presets: `applyRealisticPreset()`, `applySlowMotionPreset()`, `applyFastPreset()`.

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
5. Deck: 12 cards (Euchre deck sample) stacked face-down at position [0, y, 0.41]
6. Coordinator action wiring (dealCardsAction, playCardAction, pickUpCardAction, slideCardsAction, resetCardsAction)

**Also defines `SceneCoordinator`**: `@MainActor @Observable public class` with optional async action closures that bridge SwiftUI button presses to scene methods.

**Animation methods**:
- `dealCards()` -- iterates cards top-to-bottom, delays 0.3s each, flips face-up, switches to dynamic physics, tosses toward sides 2/3/4/1 with velocity/spin based on distance
- `playCard(index:)` -- moves card to center [0, 0.002, 0] using `entity.move()`
- `pickUpCard(index:)` -- lifts card 0.05m upward
- `slideCards()` -- shifts all cards +0.3m on X axis
- `resetCards()` -- removes all cards, recreates deck

**Deal pattern**: cycles sides [2, 3, 4, 1] (left, top, right, bottom). Side-dependent speed: side 1 gentle (0.4 horizontal, 0.15 up), sides 2/4 moderate (1.1, 0.4), side 3 strongest (1.4, 0.5).

### CardPhysicsView.swift -- SwiftUI Wrapper
`@MainActor public struct CardPhysicsView: View`

Top-level view that wraps `CardPhysicsScene` with UI controls.

**State**: `settings` (PhysicsSettings), `showSettings`/`showCameraControls` bools, `sceneKey` UUID (for reset), `cameraPosition`/`cameraTarget` SIMD3, `coordinator` SceneCoordinator.

**UI layout** (ZStack):
- Full-screen `CardPhysicsScene` (ignores safe area)
- Left-side floating VStack of `AnimationButton`s: Deal, Play, Pick Up, Slide, Reset, Camera, Settings
- `CameraControlPanel` (slide-in from left): X/Y/Z sliders for position and look-at target
- `SettingsPanel` (slide-in from right): preset buttons, sliders for durations/arcs/rotations/curvature

**Reset**: assigns new `sceneKey` UUID and new `SceneCoordinator` to force scene recreation via `.id()`.

**Internal views** (all in this file):
- `AnimationButton` -- async action button with disabled state during animation
- `CameraControlPanel` -- slider-based camera adjustment
- `SettingsPanel` -- physics parameter adjustment with presets
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
