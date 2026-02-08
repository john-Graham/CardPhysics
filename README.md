# CardPhysics

A standalone iOS sandbox for developing and fine-tuning realistic card animations and physics using RealityKit.

## Overview

CardPhysics provides a 3D RealityKit scene with procedurally generated table and felt, HDRI lighting, and a floating control panel for triggering and tweaking card animations in real time. All animation code is isolated from game logic, making it easy to extract and reuse in production card-game apps.

## Project Structure

```
CardPhysics/
├── CardPhysicsPackage/              # Swift Package — all core logic
│   ├── Package.swift
│   └── Sources/CardPhysicsKit/
│       ├── Card.swift               # Card model
│       ├── CardView.swift           # 2D SwiftUI card view
│       ├── CardEntity3D.swift       # 3D RealityKit card entity
│       ├── CardTextureGenerator.swift
│       ├── CurvedCardMesh.swift     # Curved card geometry
│       ├── ProceduralTextureGenerator.swift  # Table/felt textures
│       ├── PhysicsSettings.swift    # Animation parameters & presets
│       ├── CardPhysicsScene.swift   # Main 3D scene
│       ├── CardPhysicsView.swift    # SwiftUI view with controls
│       └── Resources/room_bg.exr   # HDRI environment map
├── CardPhysicsApp/                  # Xcode project wrapper
│   └── CardPhysicsApp.xcodeproj
├── Package.swift                    # Root package (imports CardPhysicsKit)
└── Sources/CardPhysicsApp/
    └── CardPhysicsApp.swift         # @main entry point
```

## Getting Started

1. Open `CardPhysicsApp/CardPhysicsApp.xcodeproj` in Xcode.
2. Build and run on an iOS 18+ simulator or device.
3. Use the floating buttons to trigger animations.
4. Open the Settings panel to adjust physics parameters.

## Features

### Animations

| Action | Description |
|--------|-------------|
| Deal Cards | Cards arc from a deck to player positions |
| Play Card | A card moves to the center of the table |
| Pick Up Card | A card lifts from the table into the hand |
| Slide Cards | All cards slide to the side |
| Reset | Return the scene to its initial state |

### Physics Settings

Real-time sliders for duration, arc height, rotation, and card curvature.

### Presets

- **Realistic** — balanced, natural-looking defaults
- **Slow Motion** — exaggerated for detailed observation
- **Fast** — snappy for fast-paced gameplay

## Requirements

- iOS 18.0+
- Xcode 16.3+
- Swift 6.1+
