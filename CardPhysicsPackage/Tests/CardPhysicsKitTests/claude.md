# CardPhysicsKitTests

## Overview
Unit test suite for the CardPhysicsKit framework using Apple's modern Testing framework.

## Files

### CardPhysicsKitTests.swift
**Purpose**: Main test suite for CardPhysicsKit functionality

**Testing Framework**: Apple Testing framework
- Uses `@Test` macro for test functions
- Uses `#expect(...)` for assertions
- Supports `async throws` for async tests
- Top-level test functions (no class wrapper needed)

## Current Test Coverage

### cardCreation()
**What it Tests**: Card data model creation and properties

**Test Cases**:
- Card can be instantiated with suit and rank
- Suit property is correctly set
- Rank property is correctly set
- `displayName` computed property formats correctly (e.g., "A♥")

**Example**:
```swift
@Test func cardCreation() {
    let card = Card(suit: .hearts, rank: .ace)
    #expect(card.suit == .hearts)
    #expect(card.rank == .ace)
    #expect(card.displayName == "A♥")
}
```

### physicsSettingsPresets()
**What it Tests**: PhysicsSettings preset configurations

**Test Cases**:
- Realistic preset applies correct values
- Slow motion preset applies correct values
- Fast preset applies correct values
- Specifically validates `dealDuration` for each preset

**Example**:
```swift
@Test func physicsSettingsPresets() {
    let settings = PhysicsSettings()

    settings.applyRealisticPreset()
    #expect(settings.dealDuration == 0.5)

    settings.applySlowMotionPreset()
    #expect(settings.dealDuration == 2.0)

    settings.applyFastPreset()
    #expect(settings.dealDuration == 0.2)
}
```

## Testing Strategy

### What Should Be Tested
Since CardPhysicsKit contains both testable logic and RealityKit integration, focus tests on:

#### Data Models ✅ (Currently Tested)
- Card creation
- Suit and Rank properties
- Card equality and hashing
- Display name formatting

#### Settings ✅ (Currently Tested)
- Preset configurations
- Property value ranges
- Settings mutations

#### Should Add Tests For

##### Suit Logic
```swift
@Test func suitColors() {
    #expect(Suit.hearts.color == .red)
    #expect(Suit.diamonds.color == .red)
    #expect(Suit.clubs.color == .black)
    #expect(Suit.spades.color == .black)
}
```

##### Rank Comparison
```swift
@Test func rankComparison() {
    #expect(Rank.nine < Rank.ten)
    #expect(Rank.ace > Rank.king)
    #expect(Rank.jack < Rank.queen)
}
```

##### Card Equality
```swift
@Test func cardEquality() {
    let card1 = Card(suit: .hearts, rank: .ace)
    let card2 = Card(suit: .hearts, rank: .ace)
    // Different UUIDs, so not equal
    #expect(card1 != card2)

    // Same instance is equal to itself
    #expect(card1 == card1)
}
```

##### Card Identifiable
```swift
@Test func cardIdentity() {
    let card1 = Card(suit: .hearts, rank: .ace)
    let card2 = Card(suit: .hearts, rank: .ace)

    // Different cards have different IDs
    #expect(card1.id != card2.id)
}
```

##### All PhysicsSettings Properties
```swift
@Test func settingsRealisticPreset() {
    let settings = PhysicsSettings()
    settings.applyRealisticPreset()

    // Durations
    #expect(settings.dealDuration == 0.5)
    #expect(settings.playDuration == 0.4)
    #expect(settings.pickUpDuration == 0.3)
    #expect(settings.slideDuration == 0.6)

    // Arc heights
    #expect(settings.dealArcHeight == 0.15)
    #expect(settings.playArcHeight == 0.12)
    #expect(settings.pickUpArcHeight == 0.08)

    // Rotations
    #expect(settings.dealRotation == 15.0)
    #expect(settings.playRotation == 10.0)
    #expect(settings.pickUpRotation == 5.0)

    // Curvature
    #expect(settings.cardCurvature == 0.002)
}
```

### What Should NOT Be Tested Here
These require integration/visual testing:

- 3D entity creation (requires RealityKit runtime)
- Mesh generation (requires graphics context)
- Texture generation (requires CoreGraphics/RealityKit)
- Physics simulation (requires RealityKit scene)
- Camera positioning (visual validation)
- Material rendering (visual validation)
- Animation behavior (time-based, visual)

## Writing New Tests

### Test Function Structure
```swift
@Test func descriptiveTestName() {
    // Arrange: Set up test data
    let card = Card(suit: .hearts, rank: .ace)

    // Act: Perform operation
    let displayName = card.displayName

    // Assert: Verify results
    #expect(displayName == "A♥")
}
```

### Using #expect vs #require
```swift
// Use #expect for assertions that can fail without stopping test
@Test func multipleAssertions() {
    let card = Card(suit: .hearts, rank: .ace)
    #expect(card.suit == .hearts)  // Test continues even if this fails
    #expect(card.rank == .ace)
}

// Use #require for unwrapping optionals
@Test func optionalHandling() throws {
    let value: Int? = getSomeOptional()
    let unwrapped = try #require(value)  // Throws if nil
    #expect(unwrapped > 0)
}
```

### Async Tests
```swift
@Test func asyncOperation() async throws {
    let result = await someAsyncFunction()
    #expect(result.isValid)
}
```

### Parameterized Tests
```swift
@Test(arguments: [
    (Suit.hearts, SuitColor.red),
    (Suit.diamonds, SuitColor.red),
    (Suit.clubs, SuitColor.black),
    (Suit.spades, SuitColor.black)
])
func suitHasCorrectColor(suit: Suit, expectedColor: SuitColor) {
    #expect(suit.color == expectedColor)
}
```

## Running Tests

### From Xcode
1. Test Navigator (Cmd + 6)
2. Click diamond icon next to test
3. Or run all: Cmd + U

### From Command Line
```bash
cd CardPhysicsPackage
swift test
```

### Viewing Results
- Test results appear in Xcode's test navigator
- Failed tests show detailed error messages
- Test diamonds in gutter show pass/fail status

## Best Practices

### Test Naming
- Use descriptive names that explain what is being tested
- Start with the component name
- Include the scenario being tested
- Examples: `cardCreation`, `suitColors`, `rankComparison`

### Test Organization
- Group related tests together
- One test per logical unit
- Keep tests independent (no shared state)

### Assertions
- Use `#expect` for most assertions
- One primary assertion per test (with supporting assertions as needed)
- Clear, specific assertion messages

### Test Data
- Create test data inline (no fixtures needed for simple cases)
- Use all suit and rank combinations where relevant
- Test edge cases (min/max ranks, all suits)

## Dependencies
- Testing framework (Apple's modern testing)
- CardPhysicsKit (imported with `@testable`)

## Future Test Considerations

### Mock RealityKit Components
If testing entity creation becomes important:
- Create protocol wrappers for RealityKit types
- Mock implementations for testing
- Test logic without actual 3D rendering

### Snapshot Testing
For visual validation:
- Capture screenshots of rendered scenes
- Compare against reference images
- Requires running in simulator/device

### Integration Tests
- Separate test target for RealityKit integration
- Test full scene creation and animation flow
- May require XCUITest or manual validation
