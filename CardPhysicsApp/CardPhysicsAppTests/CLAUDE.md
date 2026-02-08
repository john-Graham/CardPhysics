# CardPhysicsAppTests

Unit test target using Apple's Testing framework.

## Files

### CardPhysicsAppTests.swift
- Uses `import Testing` (not XCTest)
- Uses `@Test` macro and `#expect(...)` assertions
- Supports `async throws` test methods
- Currently contains placeholder test

## What to Test Here
Since the app target is minimal, focus on:
- App launch and initialization
- Orientation locking behavior
- ContentView instantiation
- Integration with CardPhysicsKit

Physics simulation and 3D rendering tests belong in CardPhysicsKit's test target.

## Running
- Xcode: Cmd+U or Test Navigator (Cmd+6)
- `@testable import CardPhysicsApp` provides access to internal members
