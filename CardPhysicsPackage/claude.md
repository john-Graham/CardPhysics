# CardPhysicsPackage

## Overview
CardPhysicsPackage is a Swift Package that provides the CardPhysicsKit framework - a comprehensive 3D card physics and rendering system built on RealityKit. It encapsulates all the logic for realistic card animations, physics simulation, procedural materials, and 3D scene management.

## Package Structure
```
CardPhysicsPackage/
├── Package.swift              # Package manifest
├── Sources/
│   └── CardPhysicsKit/       # Main framework code
│       ├── Resources/        # HDRI environments, textures
│       └── *.swift          # Swift source files
└── Tests/
    └── CardPhysicsKitTests/  # Unit tests
```

## Package Configuration

### Package.swift
- **Swift Tools Version**: 6.0
- **Minimum iOS**: 18.0
- **Product**: CardPhysicsKit (library)
- **Swift Settings**:
  - `ExistentialAny` feature enabled
  - `StrictConcurrency` experimental feature enabled

### Resources
The package includes bundled resources:
- HDRI environment maps for realistic lighting
- Procedural texture generation assets

## Architecture

### Framework Design
CardPhysicsKit is designed as a self-contained, reusable framework that can be integrated into any iOS app requiring 3D card rendering and physics.

**Key Design Principles**:
- Separation of concerns (rendering, physics, data models)
- Procedural generation (textures, meshes)
- Coordinator pattern for external communication
- Observable state management
- SwiftUI-first API

## Core Components

### 1. Data Models
- `Card.swift` - Card data structure (suit, rank)
- `PhysicsSettings.swift` - Configurable physics parameters

### 2. 3D Entities
- `CardEntity3D.swift` - 3D card entity factory
- `CurvedCardMesh.swift` - Procedural curved card mesh generation

### 3. Scene Management
- `CardPhysicsScene.swift` - RealityKit scene with physics simulation
- `CardPhysicsView.swift` - SwiftUI view with controls

### 4. Visual Generation
- `CardTextureGenerator.swift` - Card face/back texture generation
- `ProceduralTextureGenerator.swift` - PBR materials for table
- `CardView.swift` - 2D SwiftUI card representation

## Features

### Physics Simulation
- Gravity-based physics using RealityKit's PhysicsBodyComponent
- Collision detection with table surface and rails
- Realistic friction and restitution values
- Dynamic card tossing with velocity and spin

### Rendering
- PBR (Physically Based Rendering) materials
- Procedural wood and felt textures
- HDRI-based image based lighting
- Clearcoat effects for polished surfaces
- Curved card mesh generation

### Animations
- Deal cards with physics-based tossing
- Play card to center
- Pick up card
- Slide cards
- Reset and respawn deck

### Interactive Controls
- Camera position and target adjustment
- Physics settings panel
- Animation trigger buttons
- Real-time parameter updates

## Dependencies

### System Frameworks
- SwiftUI - UI layer
- RealityKit - 3D rendering and physics
- CoreGraphics - Texture generation

### Internal Dependencies
- All components within CardPhysicsKit are interdependent
- No external third-party dependencies

## Usage

### Integration
```swift
import CardPhysicsKit

struct MyView: View {
    var body: some View {
        CardPhysicsView()
    }
}
```

### Custom Configuration
```swift
let settings = PhysicsSettings()
settings.dealDuration = 1.5

let scene = CardPhysicsScene(
    settings: settings,
    cameraPosition: [0, 0.55, 0.41],
    cameraTarget: [0, 0, 0]
)
```

## Testing
Unit tests are located in `Tests/CardPhysicsKitTests/`
- Uses Apple's Testing framework
- Tests should cover data models, calculations, and non-rendering logic

## Build Notes

### Building the Package
```bash
swift build
```

### Testing
```bash
swift test
```

### Xcode Integration
- Add as local package dependency
- Xcode automatically builds when needed
- Clean build folder if changes don't appear

## Camera Configuration
Default camera position: `[0, 0.55, 0.41]`
- X: 0 (centered over table)
- Y: 0.55 (elevated for seated POV)
- Z: 0.41 (distance from table center)

Camera looks at: `[0, 0, 0]` (table center)

## Performance Considerations
- Procedural texture generation happens once at startup
- Physics simulation runs at RealityKit's update rate
- HDRI fallback to simple lights if resource load fails
- Card entities reuse materials for efficiency

## Future Enhancements
Potential areas for expansion:
- Multi-player card synchronization
- More card animation presets
- Custom card designs
- Haptic feedback integration
- Sound effects
- AR mode support
