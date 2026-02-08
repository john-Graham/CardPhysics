# CardPhysicsApp/CardPhysicsApp

## Overview
This folder contains the main application target files for the CardPhysicsApp iOS application.

## Files

### CardPhysicsAppApp.swift
**Purpose**: App entry point and configuration

**Key Responsibilities**:
- Defines the `@main` app structure
- Locks device orientation to landscape right on app launch
- Creates the root WindowGroup with ContentView

**Implementation Details**:
```swift
@main
struct CardPhysicsAppApp: App
```
- Uses `UIDevice.current.setValue()` to force landscape orientation
- This ensures optimal viewing of the 3D card table

### ContentView.swift
**Purpose**: Root view of the application

**Key Responsibilities**:
- Wraps CardPhysicsView from CardPhysicsKit
- Hides the status bar for immersive experience

**Dependencies**:
- SwiftUI
- CardPhysicsKit

**Implementation Details**:
- Minimal wrapper that instantiates CardPhysicsView
- `.statusBarHidden()` modifier for full-screen 3D experience
- Includes #Preview for SwiftUI canvas

### Assets.xcassets
**Purpose**: Asset catalog

**Contents**:
- App icons
- Launch screen assets
- Color assets

## Architecture Notes
This folder follows the principle of separation of concerns:
- The app target is kept minimal
- All business logic, 3D rendering, and physics are delegated to CardPhysicsKit
- This makes the core functionality reusable across different app targets

## Dependencies
- CardPhysicsKit (imports in ContentView.swift)
- SwiftUI framework
- UIKit (for orientation locking)

## Modification Guidelines
- Keep this layer thin - business logic belongs in CardPhysicsKit
- Maintain the landscape orientation lock for optimal UX
- Don't add complex view logic here - extend CardPhysicsView instead
