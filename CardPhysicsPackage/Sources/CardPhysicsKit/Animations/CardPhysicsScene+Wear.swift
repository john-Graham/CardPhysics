import RealityKit
import SwiftUI

extension CardPhysicsScene {
internal func handleCollision(entityA: Entity, entityB: Entity) {
    let idA = ObjectIdentifier(entityA)
    let idB = ObjectIdentifier(entityB)

    // Wear tracking
    if settings.enableCardWear {
        if let wearA = cardWearComponents[idA] {
            let result = wearA.incrementWear()
            if result.previousLevel != result.newLevel {
                applyWearTexture(to: entityA)
            }
        }
        if let wearB = cardWearComponents[idB] {
            let result = wearB.incrementWear()
            if result.previousLevel != result.newLevel {
                applyWearTexture(to: entityB)
            }
        }
    }

    // Felt disturbance burst -- only for card-felt collisions
    if settings.enableFeltDisturbance {
        handleFeltCollision(entityA: entityA, entityB: entityB)
    }
}

/// Creates a felt disturbance burst if the collision is between a card and the felt surface.
/// Filters out card-card and card-rail collisions.
internal func handleFeltCollision(entityA: Entity, entityB: Entity) {
    let isFeltA = entityA.name == "feltSurface"
    let isFeltB = entityB.name == "feltSurface"
    let isCardA = cardDataMap[ObjectIdentifier(entityA)] != nil
    let isCardB = cardDataMap[ObjectIdentifier(entityB)] != nil

    // Only trigger on card-felt collisions
    guard (isFeltA && isCardB) || (isFeltB && isCardA) else { return }

    // Limit active bursts to prevent performance degradation
    guard activeBurstEntities.count < 15 else { return }

    // Use the card's position for the burst location
    let cardEntity = isCardA ? entityA : entityB
    let burstPosition = SIMD3<Float>(
        cardEntity.position.x,
        0.008,  // Just above felt surface
        cardEntity.position.z
    )

    let burst = ParticleEffects.createFeltDisturbanceBurst(
        at: burstPosition,
        intensity: Float(settings.burstIntensity)
    )
    rootEntity.addChild(burst)
    activeBurstEntities.append(burst)

    // Auto-remove burst after its lifespan
    Task {
        try? await Task.sleep(for: .seconds(0.6))
        burst.removeFromParent()
        activeBurstEntities.removeAll { $0 === burst }
    }
}

/// Increments wear on a specific card entity and updates its texture if the level changed.
internal func incrementCardWear(_ card: Entity) {
    guard settings.enableCardWear else { return }
    let entityId = ObjectIdentifier(card)
    guard let wear = cardWearComponents[entityId] else { return }

    let result = wear.incrementWear()
    if result.previousLevel != result.newLevel {
        applyWearTexture(to: card)
    }
}

/// Applies the wear overlay texture to a card entity based on its current wear level.
internal func applyWearTexture(to entity: Entity) {
    let entityId = ObjectIdentifier(entity)
    guard let wear = cardWearComponents[entityId],
          let cardData = cardDataMap[entityId],
          let modelEntity = entity as? ModelEntity,
          wear.currentWearLevel != .none else { return }

    let texGen = CardTextureGenerator.shared
    let intensity = CGFloat(settings.wearIntensity)

    if let wornTexture = texGen.textureWithWear(
        for: cardData,
        wearLevel: wear.currentWearLevel,
        intensity: intensity
    ) {
        // Update face material (index 0)
        if var materials = modelEntity.model?.materials as? [PhysicallyBasedMaterial],
           !materials.isEmpty {
            materials[0].baseColor = .init(texture: .init(wornTexture))
            modelEntity.model?.materials = materials
        }
    }
}

// MARK: - Animation Methods (to be called from parent view)

}
