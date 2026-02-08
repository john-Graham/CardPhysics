# CardPhysics - Card Animation Sandbox

A focused iOS app for perfecting card animations and physics using RealityKit.

## What is This?

CardPhysics is a standalone sandbox app for developing and fine-tuning realistic card animations. It features:

- **3D RealityKit scene** with procedurally generated table and felt
- **HDRI lighting** for photorealistic card rendering
- **Floating control panel** with animation trigger buttons
- **Advanced physics settings panel** with real-time adjustment sliders
- **Multiple animation presets** (Realistic, Slow Motion, Fast)
- **Animation types**: Deal Cards, Play Card, Pick Up Card, Slide Cards

## Project Structure

```
CardPhysics/
├── CardPhysicsPackage/          # Swift Package with all features
│   ├── Package.swift
│   ├── Sources/
│   │   └── CardPhysicsKit/
│   │       ├── Card.swift                      # Card model
│   │       ├── CardView.swift                  # 2D SwiftUI card
│   │       ├── CardEntity3D.swift              # 3D card entity
│   │       ├── CardTextureGenerator.swift      # Card texture rendering
│   │       ├── CurvedCardMesh.swift            # Curved card geometry
│   │       ├── ProceduralTextureGenerator.swift # Table/felt textures
│   │       ├── PhysicsSettings.swift           # Animation parameters
│   │       ├── CardPhysicsScene.swift          # Main 3D scene
│   │       ├── CardPhysicsView.swift           # UI with controls
│   │       └── Resources/
│   │           └── room_bg.exr                 # HDRI environment
│   └── Tests/
│       └── CardPhysicsKitTests/
├── CardPhysics/                 # App wrapper (to be created)
│   └── CardPhysicsApp.swift    # @main entry point
├── README.md
└── create_project.sh            # Project setup helper
```

## Setup Instructions

### Option 1: Create Xcode Project Manually (Recommended)

1. Open Xcode
2. File > New > Project
3. Choose **iOS** > **App**
4. Configure:
   - Product Name: `CardPhysicsApp`
   - Organization Identifier: `com.yourname`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None**
5. Save location: Choose the `CardPhysics` folder
6. Add the Swift Package:
   - In Xcode project navigator, right-click on project
   - Add Packages > Add Local...
   - Navigate to and select: `CardPhysics/CardPhysicsPackage`
   - Click "Add Package"
7. Replace the generated `ContentView.swift` with:
   ```swift
   import SwiftUI
   import CardPhysicsKit

   @main
   struct CardPhysicsApp: App {
       var body: some Scene {
           WindowGroup {
               CardPhysicsView()
           }
       }
   }
   ```

### Option 2: Use Setup Script

```bash
cd CardPhysics
./create_project.sh
```

Then follow the printed instructions to complete setup in Xcode.

## Features

### Animation Controls

- **Deal Cards**: Animates cards being dealt from a deck to player positions with arc motion
- **Play Card**: Animates a card being played to the center of the table
- **Pick Up Card**: Animates picking up a card from the table
- **Slide Cards**: Slides all cards to the side of the table
- **Reset**: Resets the scene to initial state

### Physics Settings Panel

Adjust animation parameters in real-time:

- **Duration sliders**: Control speed of each animation type
- **Arc height sliders**: Adjust the height of card trajectories
- **Rotation sliders**: Control card rotation during animations
- **Card curvature slider**: Adjust physical card bend (flat to curved)

### Presets

- **Realistic**: Default balanced settings for natural-looking animations
- **Slow Motion**: Exaggerated slow animations for detailed observation
- **Fast**: Quick snappy animations for fast-paced gameplay

## Development Goals

This app is purpose-built for:

1. Perfecting card animation timings and physics
2. Testing different arc trajectories and rotations
3. Fine-tuning visual realism (lighting, textures, materials)
4. Developing reusable animation code for other card game apps

All animation code is isolated from game logic, making it easy to extract and reuse in production apps like the Euchre game.

## Requirements

- iOS 18.0+
- Xcode 16.3+
- Swift 6.1+
- Device or simulator with RealityKit support

## Next Steps

1. Build and run the app on an iOS simulator or device
2. Use the floating buttons to trigger animations
3. Open the Settings panel to adjust physics parameters
4. Try different presets to see animation variations
5. Fine-tune settings to achieve desired realism
6. Copy the perfected settings back to your game app
