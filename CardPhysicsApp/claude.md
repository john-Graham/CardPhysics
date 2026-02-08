# CardPhysicsApp

## Overview
CardPhysicsApp is an iOS application that demonstrates realistic 3D card physics and animations using RealityKit. It serves as a demonstration app for the CardPhysicsKit framework.

## Project Structure
- `CardPhysicsApp/` - Main app target with UI and entry point
- `CardPhysicsAppTests/` - Unit tests
- `CardPhysicsAppUITests/` - UI automation tests
- `Products/` - Build artifacts

## Dependencies
- iOS 18.0+
- CardPhysicsKit (local Swift package)
- SwiftUI
- RealityKit

## Architecture
The app follows a minimal architecture pattern:
- App entry point locks to landscape orientation
- ContentView acts as a thin wrapper around CardPhysicsView from CardPhysicsKit
- All 3D rendering, physics, and animation logic is contained in CardPhysicsKit

## Key Features
- 3D card rendering with realistic physics
- Interactive camera controls
- Physics simulation with gravity
- Card dealing, playing, picking up, and sliding animations
- Configurable physics settings
- Procedural PBR materials for table and cards

## Configuration
- Target: iOS
- Minimum iOS Version: 18.0
- Orientation: Landscape only (locked at app launch)

## Build Notes
- Clean build folder if camera position changes don't appear
- The app depends on the CardPhysicsPackage being built first
- Resources (HDRI, textures) are bundled in CardPhysicsKit

## Camera Configuration
Default camera position: `[0, 0.55, 0.41]`
- X: 0 (centered)
- Y: 0.55 (elevated view)
- Z: 0.41 (closer to table, moved from original 0.65)

Camera target: `[0, 0, 0]` (center of table)

## Card Dealing Physics

### Deck Configuration
- **12 cards total** - 3 rounds to each of 4 sides
- **Deck position**: Bottom of table (side 1) at z=0.41, x=0
- **Initial height**: 5x deck thickness (82.5mm above table)
  - Stack offset: 1.5mm between cards
  - Base height: max(15mm, deck_thickness × 5)
- **Dealing order**: Top to bottom (cards 11→0)
- **Deal pattern**: Side 2 (left) → 3 (top) → 4 (right) → 1 (bottom), repeating

### Distance-Based Velocity
Cards are thrown with varying speeds based on target distance:

**Side 1 (Bottom)** - Near deck, minimal slide:
- Horizontal: 0.4 m/s
- Upward: 0.15 m/s
- Spin intensity: 0.5

**Side 2 (Left)** - Medium distance:
- Horizontal: 1.1 m/s
- Upward: 0.4 m/s
- Spin intensity: 1.0

**Side 3 (Top)** - Farthest distance:
- Horizontal: 1.4 m/s (strongest throw)
- Upward: 0.5 m/s (highest arc)
- Spin intensity: 1.5 (most rotation)

**Side 4 (Right)** - Medium distance:
- Horizontal: 1.1 m/s
- Upward: 0.4 m/s
- Spin intensity: 1.0

### Rotation During Flight
Cards tumble realistically with random variation:
- **Y-axis spin**: 1.5–2.5 rad/s (scaled by spin intensity)
- **X-axis tumble**: ±0.5 rad/s (forward/backward flip)
- **Z-axis tumble**: ±0.5 rad/s (side-to-side roll)
- Direction-dependent spin (left/bottom counter-clockwise, top/right clockwise)

### Target Positioning & Stacking
Cards aim for the center of each side with tight clustering:
- **Random variation**: ±15mm (reduced from 30mm for better stacking)
- **Target positions**:
  - Side 1: (0, 0.35z)
  - Side 2: (-0.55x, 0)
  - Side 3: (0, -0.35z)
  - Side 4: (0.55x, 0)

### Card Physics Properties (CardEntity3D)
Optimized for realistic sliding and stacking:

**Friction** (reduced for sliding):
- Static friction: 0.25 (down from 0.4)
- Dynamic friction: 0.2 (down from 0.3)

**Bounce** (minimal for stacking):
- Restitution: 0.05 (down from 0.1)

**Damping** (for settling):
- Linear damping: 0.1 (was 0.0)
- Angular damping: 0.3 (was 0.0)

**Other**:
- Continuous collision detection: Enabled
- Mode: Kinematic → Dynamic on deal

### Physics Behavior
The combination of settings creates realistic card dealing:
1. **Varied throw strength** - Cards reach different distances appropriately
2. **Visible rotation** - Cards tumble and spin during flight
3. **Minimal bounce** - Low restitution prevents excessive bouncing
4. **Easy sliding** - Low friction allows cards to slide on each other
5. **Quick settling** - Light damping helps cards settle into stable piles
6. **Natural stacking** - Tight targeting + low friction = cards pile on top of each other
7. **Realistic arcs** - Upward velocity creates parabolic trajectories
8. **Deck elevation** - High initial position makes dealing motion clearly visible

### Delay Between Cards
- 0.3 seconds between each card
- Total dealing time: 3.6 seconds (12 cards)
