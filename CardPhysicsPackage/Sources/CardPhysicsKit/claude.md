# CardPhysicsKit

## Overview
CardPhysicsKit is the core framework module providing 3D card rendering, physics simulation, and animation capabilities using RealityKit. This is where all the business logic, 3D scene management, and visual generation resides.

## File Organization

### Data Models

#### Card.swift
**Purpose**: Core data structures for playing cards

**Key Types**:
- `Suit`: Enum with hearts ♥, diamonds ♦, clubs ♣, spades ♠
  - Conforms to: `CaseIterable`, `Codable`, `Sendable`
  - Properties: `color` (red/black), `name` (string)
- `SuitColor`: Enum for red or black suits
- `Rank`: Enum for card ranks (nine through ace)
  - Raw values: 9-14 (enables comparison)
  - Conforms to: `Comparable`, `Codable`, `Sendable`
  - Properties: `symbol` (display text), `name` (string)
- `Card`: Main card structure
  - Properties: `id` (UUID), `suit`, `rank`
  - Conforms to: `Identifiable`, `Equatable`, `Codable`, `Hashable`, `Sendable`
  - Computed: `displayName` (e.g., "A♠")

**Design Notes**:
- All types are `Sendable` for safe concurrent access
- UUIDs ensure unique identity even for identical cards
- Rank comparison enables game logic (e.g., trick taking)

#### PhysicsSettings.swift
**Purpose**: Configurable parameters for animations and physics

**Key Type**:
- `PhysicsSettings`: Observable settings class
  - Marked `@Observable` for SwiftUI reactivity
  - Marked `@MainActor` for UI thread safety
  - Conforms to `Sendable`

**Configuration Categories**:
1. **Animation Durations** (seconds)
   - `dealDuration`, `playDuration`, `pickUpDuration`, `slideDuration`
2. **Arc Heights** (meters)
   - `dealArcHeight`, `playArcHeight`, `pickUpArcHeight`
3. **Rotations** (degrees)
   - `dealRotation`, `playRotation`, `pickUpRotation`
4. **Visual**
   - `cardCurvature` (0.0 = flat, higher = more curve)

**Presets**:
- `applyRealisticPreset()` - Balanced, natural motion
- `applySlowMotionPreset()` - Exaggerated, slower animations
- `applyFastPreset()` - Quick, snappy animations

### 3D Entity Generation

#### CardEntity3D.swift
**Purpose**: Factory for creating 3D card entities with physics

**Key Features**:
- **Physical Dimensions** (in meters, 2x real card size):
  - Width: 0.126m (126mm)
  - Thickness: 0.0004m (0.4mm - realistic card stock)
  - Depth: 0.176m (176mm)
  - Corner radius: 0.002m (tight, realistic)

**Main Function**:
```swift
static func makeCard(
    _ card: Card,
    faceUp: Bool,
    enableTap: Bool = false,
    curvature: Float = 0.0
) -> ModelEntity
```

**Material Properties** (PBR):
- Roughness: 0.5 (paper sheen)
- Metallic: 0.0 (non-metallic)
- Specular: 0.4 (plastic coating highlight)
- Clearcoat: 0.8 with roughness 0.1 (plastic finish)

**Physics Configuration**:
- Static friction: 0.4
- Dynamic friction: 0.3
- Restitution: 0.1 (low bounce)
- Linear/Angular damping: 0.0 (natural sliding)
- Mode: `.kinematic` initially (switches to `.dynamic` during animations)
- CCD enabled (Continuous Collision Detection prevents tunneling)

**Mesh Generation**:
- Flat cards: `MeshResource.generateBox()`
- Curved cards: `CurvedCardMesh.mesh(curvature:)`

#### CurvedCardMesh.swift
**Purpose**: Procedural generation of curved card meshes

**Key Features**:
- Creates 3D mesh with realistic card curvature
- Uses subdivision for smooth curves
- Custom vertex positions and normals
- Texture coordinates properly mapped

**Use Case**: Cards held in hand appear naturally curved

### Scene Management

#### CardPhysicsScene.swift
**Purpose**: Main RealityKit scene with physics simulation

**Key Components**:
1. **Scene Setup**
   - Root entity with PhysicsSimulationComponent
   - Gravity: [0, -9.8, 0] (Earth standard)
   - Camera configuration
   - Table creation
   - Lighting (HDRI or fallback)

2. **Table Construction** (CardPhysicsScene.swift:88-238)
   - Dimensions: 1.4m wide × 1.0m deep
   - Components:
     - Wood base with PBR materials
     - Rails (0.07m thick) with collision
     - Felt surface (green, matte)
   - Physics: Static mode (infinite mass)
   - Materials: Procedural PBR textures

3. **Camera Configuration** (CardPhysicsScene.swift:75-86)
   - First-person seated POV
   - Default position: [0, 0.55, 0.41]
   - FOV: 72 degrees
   - Near/Far planes: 0.005 to 25.0

4. **Lighting** (CardPhysicsScene.swift:307-362)
   - Primary: HDRI environment (room_bg)
   - Fallback: Three-point lighting
     - Main light: Warm overhead spot (400 intensity)
     - Fill light: Cool side point (150 intensity)
     - Rim light: Back separation spot (300 intensity)

5. **Card Deck Creation** (CardPhysicsScene.swift:364-398)
   - Creates 8 sample cards
   - Stacked at deck position [0, 0.0052, 0.41]
   - Stack offset: 0.003m between cards
   - Base height: 0.025m (floating above table)

6. **Animation Methods**
   - `dealCards()` - Physics-based card tossing
   - `playCard(index:)` - Move card to center
   - `pickUpCard(index:)` - Lift card upward
   - `slideCards()` - Slide cards sideways
   - `resetCards()` - Clear and recreate deck

**Deal Animation Details** (CardPhysicsScene.swift:402-471):
- Cards flip face-up (180° rotation)
- Switch to dynamic physics mode
- Toss toward sides 2, 3, 4 (left, top, right)
- Horizontal velocity: 0.8 m/s
- Upward velocity: 0.4 m/s (arc)
- Angular velocity (spin): ±2.0 rad/s

**Coordinator Pattern**:
- `SceneCoordinator` bridges SwiftUI and RealityKit
- Async action closures for external triggers

#### CardPhysicsView.swift
**Purpose**: SwiftUI wrapper with UI controls

**Key Components**:
1. **State Management**
   - `@State` for camera, settings, UI visibility
   - `@Observable` coordinator for scene communication
   - Scene key for resetting (UUID-based)

2. **UI Structure**
   - ZStack with 3D scene and overlay controls
   - Floating control buttons (left side)
   - Settings panel (right slide-in)
   - Camera control panel (left slide-in)

3. **Control Buttons**
   - Deal, Play, Pick Up, Slide, Reset
   - Camera, Settings
   - Uses AnimationButton with async handlers

4. **Camera Control Panel** (CardPhysicsView.swift:176-326)
   - X/Y/Z sliders for position
   - X/Y/Z sliders for look-at target
   - Real-time updates to scene
   - Reset button to default values

5. **Settings Panel** (CardPhysicsView.swift:328-491)
   - Preset buttons (Realistic, Slow Motion, Fast)
   - Sliders for durations, arc heights, rotations
   - Card curvature adjustment
   - Bindable to PhysicsSettings

### Texture & Material Generation

#### CardTextureGenerator.swift
**Purpose**: Generate card face and back textures

**Key Features**:
- Singleton pattern (`shared`)
- Lazy texture generation (cached)
- Creates CGImage textures for all cards
- Generates card back pattern
- Converts to RealityKit TextureResource

**Design Pattern**:
- Textures generated once on first access
- Cached for performance
- Thread-safe with `@MainActor`

#### ProceduralTextureGenerator.swift
**Purpose**: Generate PBR textures for table materials

**Static Methods**:
- `woodAlbedo()` - Wood base color (warm mahogany)
- `woodRoughness()` - Wood grain roughness map
- `woodNormal()` - Wood grain normal map
- `feltAlbedo()` - Green felt base color
- `feltRoughness()` - Felt fiber roughness
- `feltNormal()` - Felt fiber normal map

**Texture Conversion**:
- `colorTexture(from:)` - sRGB color texture
- `dataTexture(from:)` - Linear data texture (roughness)
- `normalTexture(from:)` - Normal map texture

**PBR Pipeline**:
- Procedural generation using CoreGraphics
- Multiple octaves for natural variation
- Proper color space handling
- Optimized for RealityKit's PBR renderer

#### CardView.swift
**Purpose**: 2D SwiftUI representation of cards

**Use Case**:
- UI mockups, testing, 2D card games
- Not used in 3D scene (separate from CardEntity3D)

**Features**:
- SwiftUI View protocol
- Displays card face with suit and rank
- Styling with borders, shadows
- Can be used in standard SwiftUI layouts

### Resources

#### Resources/
**Contents**:
- HDRI environment maps (e.g., `room_bg.exr`)
- Any additional texture assets
- Bundled via Package.swift resource processing

## Architecture Patterns

### Separation of Concerns
- **Data**: Card, Suit, Rank (pure data models)
- **View**: CardPhysicsView, CardView (SwiftUI)
- **Scene**: CardPhysicsScene (RealityKit rendering)
- **Entities**: CardEntity3D (3D object creation)
- **Materials**: TextureGenerator classes (visual generation)

### Coordinator Pattern
- `SceneCoordinator` decouples UI events from scene actions
- Async closures bridge SwiftUI and RealityKit
- Allows multiple UI controllers for same scene

### Observable State
- `PhysicsSettings` uses `@Observable` macro
- SwiftUI automatically updates when settings change
- No need for manual Combine publishers

### Factory Pattern
- `CardEntity3D.makeCard()` centralizes entity creation
- Consistent physics and material properties
- Easy to modify all cards at once

## Physics Implementation

### Collision Groups
Cards collide with:
- Table surface (felt)
- Rails (wood borders)
- Other cards (implicit)

### Physics Modes
- **Kinematic**: Initial state, scripted animations
- **Dynamic**: During physics-based animations (dealing)
- **Static**: Table and rails (immovable)

### Friction & Restitution
- **Cards**: Medium friction (0.4/0.3), low bounce (0.1)
- **Felt**: Higher friction (0.5/0.4), low bounce (0.1)
- **Rails**: Lower friction (0.3/0.25), medium bounce (0.4)

### Continuous Collision Detection
- Essential for thin cards (0.4mm thick)
- Prevents tunneling through surfaces
- Enabled on all card entities

## Performance Optimization

### Texture Caching
- CardTextureGenerator singleton with lazy loading
- Textures generated once, reused for all cards
- Procedural textures generated at startup

### Material Reuse
- Same material configuration for all cards of same type
- Texture atlasing implicitly handled by RealityKit

### Physics Optimization
- Kinematic mode when not animating (no physics compute)
- Dynamic mode only during active animations
- Zero damping for natural motion (less computation)

## API Design

### Public Interface
All major types are public:
- Data models: `Card`, `Suit`, `Rank`
- Settings: `PhysicsSettings`
- Views: `CardPhysicsView`
- Scene: `CardPhysicsScene`

### Internal Implementation
- `CardEntity3D`: Internal enum (implementation detail)
- `CurvedCardMesh`: Internal (could be exposed if needed)
- Texture generators: Internal but available to module

## Testing Considerations

### Unit Testable
- Card data models (equality, comparison)
- PhysicsSettings presets
- Coordinate calculations

### Not Unit Testable (Requires Integration)
- 3D rendering
- Physics simulation
- Texture generation
- RealityKit scene behavior

### Recommended Test Coverage
- Card creation and properties
- Suit/Rank comparisons
- Settings preset application
- Coordinator action wiring

## Common Modifications

### Changing Camera Position
Update in three places:
1. `CardPhysicsScene.init()` default parameter
2. `CardPhysicsView` @State initial value
3. `CameraControlPanel` onReset closure

### Adjusting Physics
- Friction: `CardEntity3D.makeCard()` and `CardPhysicsScene.createTable()`
- Gravity: `CardPhysicsScene` PhysicsSimulationComponent
- Damping: `CardEntity3D` PhysicsBodyComponent

### Adding New Animations
1. Add action closure to `SceneCoordinator`
2. Implement animation method in `CardPhysicsScene`
3. Wire up in `CardPhysicsScene.body` RealityView
4. Add UI button in `CardPhysicsView`

### Customizing Materials
- Wood/Felt: Modify `ProceduralTextureGenerator` static methods
- Cards: Modify `CardEntity3D.makeCard()` material properties
- Table dimensions: `CardPhysicsScene.createTable()` constants
