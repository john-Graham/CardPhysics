import RealityKit
import SwiftUI

/// Factory for creating particle effect entities used in the card physics scene.
@MainActor
enum ParticleEffects {

    /// Creates a continuous dust motes emitter that hovers above the table.
    /// Simulates floating dust particles caught in light.
    /// - Parameter density: Multiplier for emission rate (1.0 = 20 particles/sec)
    static func createDustMotesEmitter(density: Float = 1.0) -> Entity {
        let emitterEntity = Entity()
        emitterEntity.name = "dustMotesEmitter"

        var emitter = ParticleEmitterComponent()

        // Emission
        emitter.emitterShape = .box
        emitter.emitterShapeSize = [1.2, 0.15, 0.85]  // Covers table area, thin vertical band
        emitter.mainEmitter.birthRate = 20.0 * density
        emitter.mainEmitter.lifeSpan = 10.0

        // Appearance
        emitter.mainEmitter.size = 0.001
        emitter.mainEmitter.color = .constant(.single(.init(
            red: 1.0, green: 0.98, blue: 0.90, alpha: 0.3
        )))
        emitter.mainEmitter.blendMode = .additive

        // Motion -- gentle drift
        emitter.speed = 0.003
        emitter.mainEmitter.dampingFactor = 0.98

        // Position above the table surface
        emitterEntity.position = [0, 0.12, 0]
        emitterEntity.components.set(emitter)

        return emitterEntity
    }

    /// Creates a short-lived burst of particles at an impact point,
    /// simulating felt fibers being disturbed by a card landing.
    /// - Parameters:
    ///   - position: World-space position of the impact
    ///   - intensity: Multiplier for particle count and speed
    static func createFeltDisturbanceBurst(at position: SIMD3<Float>, intensity: Float = 1.0) -> Entity {
        let burstEntity = Entity()
        burstEntity.name = "feltBurst"

        var emitter = ParticleEmitterComponent()

        // One-shot burst
        emitter.emitterShape = .point
        emitter.mainEmitter.birthRate = 0  // We use burst instead
        emitter.mainEmitter.lifeSpan = 0.5
        emitter.burstCount = Int(20.0 * intensity)
        emitter.isEmitting = true

        // Appearance -- tiny felt-colored specks
        emitter.mainEmitter.size = 0.0008
        emitter.mainEmitter.color = .constant(.single(.init(
            red: 0.15, green: 0.35, blue: 0.18, alpha: 0.6
        )))
        emitter.mainEmitter.blendMode = .alpha

        // Motion -- small upward puff
        emitter.speed = 0.04 * intensity
        emitter.mainEmitter.dampingFactor = 0.85

        burstEntity.position = position
        burstEntity.components.set(emitter)

        return burstEntity
    }
}
