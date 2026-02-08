# CardPhysicsAppTests

## Overview
Unit test target for CardPhysicsApp using Apple's Testing framework.

## Files

### CardPhysicsAppTests.swift
**Purpose**: Main test suite for the app target

**Testing Framework**: Apple Testing framework (imported as `Testing`)
- Uses modern `@Test` macro instead of XCTest
- Supports async testing with `async throws`
- Uses `#expect(...)` for assertions instead of XCTAssert

**Current State**:
- Contains placeholder example test
- Ready for expansion with actual test cases

## Testing Strategy

### What to Test Here
Since the app target is minimal, focus tests on:
- App launch and initialization
- Orientation locking behavior
- ContentView instantiation
- Integration with CardPhysicsKit

### What NOT to Test Here
- 3D rendering logic (belongs in CardPhysicsKit tests)
- Physics simulation (belongs in CardPhysicsKit tests)
- Card animations (belongs in CardPhysicsKit tests)

## Writing Tests

### Example Test Structure
```swift
@Test func testAppLaunchesInLandscape() async throws {
    // Verify orientation is set to landscape
}

@Test func testContentViewLoads() async throws {
    // Verify ContentView can be instantiated
}
```

### Best Practices
- Use descriptive test names that explain what is being tested
- Use `async throws` for tests that need async/await
- Use `#expect(...)` for assertions
- Import with `@testable import CardPhysicsApp` to access internal members

## Dependencies
- Testing framework (Apple's modern testing)
- CardPhysicsApp module (testable import)

## Running Tests
- Run via Xcode Test Navigator
- Command: Cmd + U
- Individual tests can be run from the test diamond in the gutter
