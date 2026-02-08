import Testing
import RealityKit
import SwiftUI
@testable import CardPhysicsKit

@Test func cardCreation() {
    let card = Card(suit: .hearts, rank: .ace)
    #expect(card.suit == .hearts)
    #expect(card.rank == .ace)
    #expect(card.displayName == "A♥")
}

@Test func physicsSettingsPresets() {
    let settings = PhysicsSettings()

    settings.applyRealisticPreset()
    #expect(settings.dealDuration == 0.5)

    settings.applySlowMotionPreset()
    #expect(settings.dealDuration == 2.0)

    settings.applyFastPreset()
    #expect(settings.dealDuration == 0.2)
}

// MARK: - iOS 26 API Availability Audit

/// Verifies that GestureComponent is available and constructible on iOS 26 simulator.
/// GestureComponent requires a gesture argument — it wraps a SwiftUI gesture for use on entities.
@Test @MainActor func gestureComponentAvailableOniOS26() throws {
    let tap = TapGesture()
    let component = GestureComponent(tap)
    #expect(type(of: component) == GestureComponent.self)
}

/// Verifies that InputTargetComponent and GestureComponent can coexist on the same entity,
/// which is the pattern needed for tap-to-flip cards (Step 4).
@Test @MainActor func inputTargetAndGestureComponentCoexist() throws {
    let entity = Entity()
    entity.components.set(InputTargetComponent())
    let tap = TapGesture()
    entity.components.set(GestureComponent(tap))
    #expect(entity.components[InputTargetComponent.self] != nil)
    #expect(entity.components[GestureComponent.self] != nil)
}
