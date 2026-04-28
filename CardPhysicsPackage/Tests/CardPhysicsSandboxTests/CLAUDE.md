# CardPhysicsKitTests

## Overview
Unit tests for CardPhysicsKit using Apple's Testing framework (`import Testing`).

## Current Tests (CardPhysicsKitTests.swift)

### `cardCreation()`
Tests Card struct creation and `displayName` formatting.
- Verifies suit, rank properties set correctly
- Verifies `displayName` == "A♥" for ace of hearts

### `physicsSettingsPresets()`
Tests all three PhysicsSettings presets by checking `dealDuration`:
- Realistic: 0.5s
- Slow Motion: 2.0s
- Fast: 0.2s

### `gestureComponentAvailableOniOS26()` (iOS 26 API audit)
Verifies `GestureComponent(TapGesture())` compiles and constructs on iOS 26 simulator. Confirms the RealityKit GestureComponent API is available on iOS (not visionOS-only). `@MainActor` isolated.

### `inputTargetAndGestureComponentCoexist()` (iOS 26 API audit)
Verifies `InputTargetComponent` and `GestureComponent` can coexist on the same `Entity`. This is the pattern used for tap-to-flip cards. `@MainActor` isolated.

## Running Tests

**Xcode**: Cmd+U or Test Navigator (Cmd+6)
**CLI**: `cd CardPhysicsPackage && swift test`

## Testing Framework Notes
- Uses `@Test` macro (not XCTestCase classes)
- Uses `#expect(...)` for assertions (not XCTAssert)
- Top-level functions, no class wrapper needed
- Supports `async throws` for async tests
- `@testable import CardPhysicsKit` for internal access

## What Is Testable
Data models and settings -- pure logic with no RealityKit dependency:
- Card, Suit, Rank properties and comparisons
- PhysicsSettings presets and mutations
- SuitColor mapping

RealityKit component construction (requires `@MainActor`, `import RealityKit`):
- GestureComponent availability and construction
- InputTargetComponent + GestureComponent coexistence on entities

## What Requires Integration Testing
Anything touching RealityKit or CoreGraphics at runtime:
- 3D entity creation (CardEntity3D)
- Mesh generation (CurvedCardMesh)
- Texture generation (CardTextureGenerator, ProceduralTextureGenerator)
- Physics simulation, animations, scene rendering
- Tap-to-flip gesture behavior (requires running simulator)
