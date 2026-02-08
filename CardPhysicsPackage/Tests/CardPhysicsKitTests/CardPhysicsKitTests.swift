import Testing
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
