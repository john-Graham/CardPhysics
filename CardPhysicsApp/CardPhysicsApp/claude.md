# CardPhysicsApp/CardPhysicsApp

Main app target source files.

## Files

### CardPhysicsAppApp.swift
- `@main` entry point
- Creates `WindowGroup` with `ContentView`
- Locks orientation to landscape right via `UIDevice.current.setValue()`

### ContentView.swift
- Root view wrapping `CardPhysicsView` from CardPhysicsKit
- Hides status bar with `.statusBarHidden()`
- Includes `#Preview` macro

### Assets.xcassets
- App icons, launch screen assets, color assets

## Architecture
This target is intentionally minimal. All 3D rendering, physics simulation, and card logic is delegated to CardPhysicsKit. Keep this layer thin -- extend `CardPhysicsView` in CardPhysicsKit rather than adding complexity here.

## Dependencies
- SwiftUI, UIKit (orientation locking)
- CardPhysicsKit (`CardPhysicsView`)
