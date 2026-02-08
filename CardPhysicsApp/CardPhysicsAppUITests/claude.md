# CardPhysicsAppUITests

## Overview
UI automation test target for CardPhysicsApp using XCUITest framework.

## Files

### CardPhysicsAppUITests.swift
**Purpose**: Main UI test suite for user interactions and workflows

**Testing Framework**: XCTest + XCUITest
- Uses `XCUIApplication` for app automation
- Requires `@MainActor` for UI test methods
- Inherits from `XCTestCase`

**Key Features**:
- `setUpWithError()`: Configures test environment, sets `continueAfterFailure = false`
- `testExample()`: Placeholder for UI interaction tests
- `testLaunchPerformance()`: Measures app launch time using `XCTApplicationLaunchMetric`

### CardPhysicsAppUITestsLaunchTests.swift
**Purpose**: Screenshot and launch validation tests

**Key Features**:
- `runsForEachTargetApplicationUIConfiguration`: Tests run for each UI configuration (light/dark mode, etc.)
- `testLaunch()`: Captures launch screen screenshot
- Screenshots are kept permanently with `lifetime = .keepAlways`

## UI Testing Strategy

### What to Test
- App launches successfully in landscape orientation
- Control buttons are visible and tappable (Deal, Play, Pick Up, Slide, Reset)
- Settings panel can be opened and closed
- Camera control panel can be opened and closed
- Physics animations complete without crashing
- UI remains responsive during animations

### Example Test Scenarios
```swift
@MainActor
func testDealButtonTapsSuccessfully() throws {
    let app = XCUIApplication()
    app.launch()

    let dealButton = app.buttons["Deal"]
    XCTAssertTrue(dealButton.exists)
    dealButton.tap()
    // Wait for animation to complete
}

@MainActor
func testSettingsPanelOpensAndCloses() throws {
    let app = XCUIApplication()
    app.launch()

    let settingsButton = app.buttons["Settings"]
    settingsButton.tap()
    XCTAssertTrue(app.staticTexts["Physics Settings"].exists)

    let doneButton = app.buttons["Done"]
    doneButton.tap()
    XCTAssertFalse(app.staticTexts["Physics Settings"].exists)
}
```

## Best Practices

### Test Setup
- Always set `continueAfterFailure = false` to stop on first failure
- Use `@MainActor` annotation for UI test methods
- Launch app with `XCUIApplication().launch()`

### Assertions
- Use `XCTAssertTrue/False` for boolean conditions
- Use `exists` property to check element presence
- Use `isHittable` to verify elements are interactive

### Waiting for Elements
```swift
let element = app.buttons["MyButton"]
XCTAssertTrue(element.waitForExistence(timeout: 5))
```

### Taking Screenshots
```swift
let screenshot = app.screenshot()
let attachment = XCTAttachment(screenshot: screenshot)
attachment.name = "My Screenshot"
attachment.lifetime = .keepAlways
add(attachment)
```

## Running UI Tests

### From Xcode
- Test Navigator (Cmd + 6)
- Click test diamond next to test method
- Or run all with Cmd + U

### From Command Line
```bash
xcodebuild test -scheme CardPhysicsApp -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Accessibility Identifiers
To make UI tests more robust, consider adding accessibility identifiers to buttons and views in CardPhysicsView:

```swift
.accessibilityIdentifier("dealButton")
.accessibilityIdentifier("settingsPanel")
```

## Performance Testing
- Use `measure(metrics:)` for performance tests
- `XCTApplicationLaunchMetric()` measures launch time
- Consider testing animation performance with custom metrics

## Dependencies
- XCTest framework
- XCUITest framework (UI automation)
- CardPhysicsApp (app under test)
