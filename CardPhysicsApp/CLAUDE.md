# CardPhysicsApp

## Overview
CardPhysicsApp is an iOS application that demonstrates realistic 3D card physics and animations using RealityKit. It serves as a thin wrapper around the CardPhysicsKit framework.

## Project Structure
- `CardPhysicsApp/` - Main app target (entry point + root view)
- `CardPhysicsAppTests/` - Unit tests (Apple Testing framework)
- `CardPhysicsAppUITests/` - UI automation tests (XCUITest)
- `card-physics.rtf` - Reference document on spatial card physics theory

## Dependencies
- iOS 26.0+ (currently 26.2)
- CardPhysicsKit (local Swift package at ../CardPhysicsPackage)
- SwiftUI, RealityKit, UIKit

## Architecture
- App entry point locks orientation to landscape right
- ContentView wraps `CardPhysicsView` from CardPhysicsKit with hidden status bar
- All 3D rendering, physics, and animation logic lives in CardPhysicsKit

## Build
- Scheme: CardPhysicsApp
- The app depends on CardPhysicsPackage being built first
- Clean build folder if camera position changes don't take effect
- Resources (HDRI, textures) are bundled in CardPhysicsKit

## Camera Configuration
- Default position: `[0, 0.55, 0.41]` (centered, elevated, close to table)
- Target: `[0, 0, 0]` (center of table)

## Card Dealing Physics

### Deck Configuration
- **12 cards total** -- 3 rounds to each of 4 sides
- **Deck position**: Bottom of table (side 1) at z=0.41, x=0
- **Initial height**: 5x deck thickness (82.5mm above table)
  - Stack offset: 1.5mm between cards
  - Base height: max(15mm, deck_thickness x 5)
- **Dealing order**: Top to bottom (cards 11 to 0)
- **Deal pattern**: Side 2 (left), 3 (top), 4 (right), 1 (bottom), repeating

### Distance-Based Velocity
Cards are thrown with varying speeds based on target distance:

| Side | Horizontal | Upward | Spin Intensity |
|------|-----------|--------|----------------|
| 1 (Bottom, near deck) | 0.4 m/s | 0.15 m/s | 0.5 |
| 2 (Left, medium) | 1.1 m/s | 0.4 m/s | 1.0 |
| 3 (Top, farthest) | 1.4 m/s | 0.5 m/s | 1.5 |
| 4 (Right, medium) | 1.1 m/s | 0.4 m/s | 1.0 |

### Rotation During Flight
- **Y-axis spin**: 1.5-2.5 rad/s (scaled by spin intensity)
- **X-axis tumble**: +/-0.5 rad/s (forward/backward flip)
- **Z-axis tumble**: +/-0.5 rad/s (side-to-side roll)
- Direction-dependent spin (left/bottom counter-clockwise, top/right clockwise)

### Target Positioning & Stacking
Cards aim for center of each side with tight clustering:
- **Random variation**: +/-15mm
- **Target positions**: Side 1: (0, 0.35z), Side 2: (-0.55x, 0), Side 3: (0, -0.35z), Side 4: (0.55x, 0)

### Card Physics Properties (CardEntity3D)
| Property | Value | Notes |
|----------|-------|-------|
| Static friction | 0.25 | Reduced from 0.4 for sliding |
| Dynamic friction | 0.2 | Reduced from 0.3 |
| Restitution | 0.05 | Minimal bounce for stacking |
| Linear damping | 0.1 | Was 0.0, helps settling |
| Angular damping | 0.3 | Was 0.0, helps settling |
| CCD | Enabled | Prevents tunneling through thin surfaces |
| Mode | Kinematic -> Dynamic on deal | |

### Physics Behavior Summary
1. Varied throw strength -- cards reach different distances appropriately
2. Visible rotation -- cards tumble and spin during flight
3. Minimal bounce -- low restitution prevents excessive bouncing
4. Easy sliding -- low friction allows cards to slide on each other
5. Quick settling -- light damping helps cards settle into stable piles
6. Natural stacking -- tight targeting + low friction = cards pile up
7. Realistic arcs -- upward velocity creates parabolic trajectories
8. Deck elevation -- high initial position makes dealing visible

### Timing
- 0.3 seconds between each card
- Total dealing time: 3.6 seconds (12 cards)

## Reference: RealityKit Card Physics Theory
The file `card-physics.rtf` contains an extensive reference on:
- Physics body modes (static/kinematic/dynamic) and state transitions
- Continuous Collision Detection (CCD) for thin objects
- Solving tiny object scale limitations with physicsOrigin scaling (0.1x)
- Linear/angular damping optimization (set to 0.0 for natural slide)
- Friction modeling: static vs dynamic friction coefficients for card-on-table and card-on-card
- Restitution tuning (0.1-0.2 for inelastic card collisions)
- Linear and angular impulse calculations for throw mechanics
- Solver iteration tuning (12-16 positionIterations for stack stability)
- CollisionGroup/CollisionFilter for performance optimization
- TabletopKit as alternative stacking solution
- Performance optimization for 52-card scenes
