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
