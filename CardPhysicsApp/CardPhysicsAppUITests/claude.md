# CardPhysicsAppUITests

UI automation test target using XCUITest.

## Files

### CardPhysicsAppUITests.swift
- XCTest-based UI tests with `XCUIApplication`
- `continueAfterFailure = false` in setup
- Includes `testLaunchPerformance()` using `XCTApplicationLaunchMetric`
- All UI test methods require `@MainActor`

### CardPhysicsAppUITestsLaunchTests.swift
- Launch screenshot capture tests
- `runsForEachTargetApplicationUIConfiguration = true` (runs for light/dark mode, etc.)
- Captures and stores launch screenshots with `lifetime = .keepAlways`

## What to Test
- App launches in landscape orientation
- Control buttons visible and tappable (Deal, Play, Pick Up, Slide, Reset)
- Settings/camera panels open and close
- Animations complete without crashing
- UI responsiveness during physics simulation

## Running
- Xcode: Cmd+U or Test Navigator (Cmd+6)
- CLI: `xcodebuild test -scheme CardPhysicsApp -destination 'platform=iOS Simulator,name=iPhone 16'`

## Tips
- Use `element.waitForExistence(timeout: 5)` for async UI
- Add `.accessibilityIdentifier()` to views in CardPhysicsKit for reliable element queries
