//
//  CardPhysicsAppUITests.swift
//  CardPhysicsAppUITests
//
//  Created by John D Graham on 2/7/26.
//

import XCTest

// TODO: Add UI tests for CardPhysicsApp
final class CardPhysicsAppUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCaptureInHandsFan() throws {
        let app = XCUIApplication()
        app.launch()

        // Wait for app to fully load
        sleep(3)

        // Tap Deal button
        let dealButton = app.buttons["Deal"]
        XCTAssertTrue(dealButton.waitForExistence(timeout: 5), "Deal button not found")
        dealButton.tap()

        // Wait for dealing animation to complete (12 cards × 0.3s = 3.6s + settling)
        sleep(6)

        // Take screenshot after dealing
        let dealScreenshot = app.windows.firstMatch.screenshot()
        let dealAttachment = XCTAttachment(screenshot: dealScreenshot)
        dealAttachment.name = "AfterDeal"
        dealAttachment.lifetime = .keepAlways
        add(dealAttachment)

        // Go directly to Fan in Hands (skip Pick Up — it removes cards!)
        let fanButton = app.buttons["Fan in Hands"]
        XCTAssertTrue(fanButton.waitForExistence(timeout: 5), "Fan in Hands button not found")
        fanButton.tap()

        // Wait for fan animation to complete
        sleep(4)

        // Take screenshot of fanned cards
        let fanScreenshot = app.windows.firstMatch.screenshot()
        let fanAttachment = XCTAttachment(screenshot: fanScreenshot)
        fanAttachment.name = "InHandsFan"
        fanAttachment.lifetime = .keepAlways
        add(fanAttachment)
    }
}
