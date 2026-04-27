import Foundation
import RealityKit

// MARK: - Side Geometry

/// Describes the world-space geometry for a card fan on one side of the table.
/// All positions and directions are in world coordinates, derived from TableGeometry.
internal struct SideGeometry {
    let fanCenter: SIMD3<Float>    // world position at table edge (pivot at bottom of cards)
    let facing: SIMD3<Float>       // unit vector toward player
    let spread: SIMD3<Float>       // unit vector along table edge (perpendicular to facing)
    let baseYRotation: Float       // Y rotation so card face points toward player
}

extension CardPhysicsScene {

    /// Compute the side geometry for a given player side, using table constants.
    /// The pivot point sits well above the rail tops and inward from the rail edges
    /// so cards don't clip into the rail geometry.
    internal func sideGeometry(for side: Int, tiltAngle: Float) -> SideGeometry {
        // Keep the grip near the rail/hand instead of floating in the table center.
        let pivotY: Float = 0.075
        // Slightly outside the inner rail so the card bases read as held in hand.
        let inset: Float = -0.015

        // baseYRotation: after standUp (-π/2 around X), the card face points +Z.
        // Rotate around Y to aim the face toward the player on each side.
        switch side {
        case 1: // Bottom — face toward +Z (camera), no extra rotation
            return SideGeometry(
                fanCenter: SIMD3(0, pivotY, TableGeometry.innerMaxZ - inset),
                facing: SIMD3(0, 0, 1),
                spread: SIMD3(1, 0, 0),
                baseYRotation: 0
            )
        case 2: // Left — face toward -X
            return SideGeometry(
                fanCenter: SIMD3(TableGeometry.innerMinX + inset, pivotY, 0),
                facing: SIMD3(-1, 0, 0),
                spread: SIMD3(0, 0, 1),
                baseYRotation: -.pi / 2
            )
        case 3: // Top — face toward -Z
            return SideGeometry(
                fanCenter: SIMD3(0, pivotY, TableGeometry.innerMinZ + inset),
                facing: SIMD3(0, 0, -1),
                spread: SIMD3(-1, 0, 0),
                baseYRotation: .pi
            )
        case 4: // Right — face toward +X
            return SideGeometry(
                fanCenter: SIMD3(TableGeometry.innerMaxX - inset, pivotY, 0),
                facing: SIMD3(1, 0, 0),
                spread: SIMD3(0, 0, -1),
                baseYRotation: .pi / 2
            )
        default:
            return SideGeometry(
                fanCenter: SIMD3(0, pivotY, TableGeometry.innerMaxZ - inset),
                facing: SIMD3(0, 0, 1),
                spread: SIMD3(1, 0, 0),
                baseYRotation: 0
            )
        }
    }

    // MARK: - Physics Helpers

    /// Remove physics components from a card. Cards in the fan are positioned
    /// directly and don't need physics simulation.
    internal func stripPhysics(from card: Entity) {
        card.components.remove(PhysicsBodyComponent.self)
        card.components.remove(CollisionComponent.self)
        card.components.remove(PhysicsMotionComponent.self)
    }

    /// Restore physics components to a card (for returning to table).
    internal func restorePhysics(to card: Entity, mode: PhysicsBodyMode = .kinematic) {
        let shape = ShapeResource.generateBox(
            width: CardEntity3D.cardWidth,
            height: CardEntity3D.cardHeight,
            depth: CardEntity3D.cardDepth
        )
        card.components.set(CollisionComponent(shapes: [shape]))

        var physicsBody = PhysicsBodyComponent(
            massProperties: .default,
            material: .generate(
                staticFriction: 0.25,
                dynamicFriction: 0.2,
                restitution: 0.05
            ),
            mode: mode
        )
        physicsBody.isContinuousCollisionDetectionEnabled = true
        physicsBody.linearDamping = 0.1
        physicsBody.angularDamping = 0.3
        card.components.set(physicsBody)
    }

    /// Apply curvature to a card's mesh. Only updates the collision shape if the card
    /// has a physics body (cards in the fan have physics stripped).
    internal func applyCardCurvature(_ card: Entity, curvature: Float) {
        guard let modelEntity = card as? ModelEntity,
              var modelComponent = modelEntity.model else { return }
        modelComponent.mesh = CurvedCardMesh.mesh(curvature: curvature)
        modelEntity.model = modelComponent

        // Only update collision shape if the card has physics (not in fan state)
        if modelEntity.components[PhysicsBodyComponent.self] != nil {
            let collisionHeight = CardEntity3D.cardHeight + (abs(curvature) * 2.0)
            let shape = ShapeResource.generateBox(
                width: CardEntity3D.cardWidth,
                height: collisionHeight,
                depth: CardEntity3D.cardDepth
            )
            modelEntity.components.set(CollisionComponent(shapes: [shape]))
        }
    }

    // MARK: - Fan Cards

    public func fanCardsInHands() async {
        guard !cards.isEmpty else { return }

        removeHandEntities()

        // Strip physics from all cards — they stay as direct children of rootEntity
        for card in cards {
            stripPhysics(from: card)
        }

        cardsInFanState = true
        updateInHandsCardPositions()
    }

    /// Removes any legacy hand models before entering the fan view.
    internal func removeHandEntities() {
        for hand in handEntities {
            hand.removeFromParent()
        }
        handEntities.removeAll()
    }

    /// Flips a card 180 degrees with a short animation.
    /// Works both in fan state (no physics) and on table (with physics).
    internal func flipCard(_ card: Entity) {
        let hasPhysics = card.components[PhysicsBodyComponent.self] != nil

        guard hasPhysics || cardsInFanState else { return }

        // Increment wear on flip interaction
        incrementCardWear(card)

        if cardsInFanState {
            // In fan: flip around the card's local width axis (world-space animation)
            let currentOrientation = card.orientation
            let flipRotation = simd_quatf(angle: .pi, axis: currentOrientation.act(SIMD3<Float>(1, 0, 0)))
            let targetOrientation = flipRotation * currentOrientation

            card.move(
                to: Transform(
                    scale: card.scale,
                    rotation: targetOrientation,
                    translation: card.position
                ),
                relativeTo: nil,
                duration: 0.25,
                timingFunction: .easeInOut
            )
        } else {
            // On table: existing behavior
            let currentRotation = card.orientation
            let localUp = currentRotation.act(SIMD3<Float>(0, 1, 0))
            let isFaceUp = localUp.y < 0

            let targetOrientation = isFaceUp
                ? simd_quatf(angle: 0, axis: [1, 0, 0])
                : simd_quatf(angle: .pi, axis: [1, 0, 0])

            let previousMode = card.components[PhysicsBodyComponent.self]?.mode ?? .kinematic
            if previousMode == .dynamic {
                var body = card.components[PhysicsBodyComponent.self]!
                body.mode = .kinematic
                card.components[PhysicsBodyComponent.self] = body
                card.components[PhysicsMotionComponent.self] = nil
            }

            moveCardSafely(
                card,
                to: Transform(
                    scale: card.scale,
                    rotation: targetOrientation,
                    translation: card.position
                ),
                duration: 0.25,
                timingFunction: .easeInOut
            )

            if previousMode == .dynamic {
                Task {
                    try? await Task.sleep(for: .seconds(0.25))
                    if var body = card.components[PhysicsBodyComponent.self] {
                        body.mode = .dynamic
                        card.components[PhysicsBodyComponent.self] = body
                    }
                }
            }
        }
    }

    /// Updates card positions using fan-from-bottom world-space math.
    /// Cards are stacked together above the table and fanned out from a pivot
    /// at the bottom of the stack, like holding cards in a real hand.
    /// Called on every slider change for real-time feedback.
    internal func updateInHandsCardPositions() {
        guard !cards.isEmpty, cardsInFanState else { return }

        // Group cards by their assigned side
        var sideCards: [Int: [Entity]] = [:]
        for card in cards {
            let side = cardSideAssignments[ObjectIdentifier(card)] ?? 1
            sideCards[side, default: []].append(card)
        }

        for side in 1...4 {
            guard let cardsInSide = sideCards[side], !cardsInSide.isEmpty else { continue }

            let sideSettings = settings.inHandsSettings(for: side)
            let geo = sideGeometry(for: side, tiltAngle: sideSettings.tiltAngle)

            let cardCount = cardsInSide.count
            let pivotToCenter = max(
                CardEntity3D.cardDepth * 0.48,
                min(sideSettings.arcRadius, CardEntity3D.cardDepth * 0.82)
            )
            let overlapLift = max(0.0006, min(sideSettings.verticalSpacing, 0.004))
            let gripBias = CardEntity3D.cardWidth * 0.08

            for (index, card) in cardsInSide.enumerated() {
                // Fan progress: -0.5 to +0.5
                let t = cardCount > 1
                    ? (Float(index) / Float(cardCount - 1)) - 0.5
                    : 0.0
                let arcAngle = t * sideSettings.fanAngle

                // Fan rotation around the hand-facing direction. The pivot is biased
                // toward the thumb instead of the exact bottom center, which keeps
                // the lower corners gathered while the top edges open like real cards.
                let fanRotation = simd_quatf(angle: arcAngle, axis: geo.facing)
                let cardCenterFromGrip = geo.spread * gripBias + SIMD3<Float>(0, pivotToCenter, 0)

                // Apply fan rotation to the offset (rotates card around thumb pivot)
                let fannedOffset = fanRotation.act(cardCenterFromGrip)

                // Apply tilt (lean cards back to show faces to overhead camera)
                let tiltRotation = simd_quatf(angle: sideSettings.tiltAngle, axis: geo.spread)
                let tiltedOffset = tiltRotation.act(fannedOffset)

                // Depth ordering: tiny offsets prevent z-fighting while preserving
                // the tight paper stack. Later cards sit slightly forward and up,
                // matching the visible overlap in a held fan.
                let layer = Float(index)
                let depthOrder = layer * overlapLift * 0.35 * geo.facing
                let stackLift = layer * overlapLift * SIMD3<Float>(0, 1, 0)
                let naturalStagger = t * CardEntity3D.cardWidth * 0.025 * geo.spread

                let cardPosition = geo.fanCenter + tiltedOffset + depthOrder + stackLift + naturalStagger

                // Card orientation composed from clear, independent rotations:
                // 1. Stand card up (-π/2 around X): face points +Z, card stands vertical
                let standUp = simd_quatf(angle: -.pi / 2, axis: SIMD3<Float>(1, 0, 0))
                // 2. Face toward player (Y rotation for this side)
                let facePlayer = simd_quatf(angle: geo.baseYRotation + sideSettings.rotationOffset, axis: SIMD3<Float>(0, 1, 0))
                // 3. Fan spread (rotate around facing axis, same as position fan)
                // 4. Tilt back (lean toward player to show faces from overhead)
                let orientation = tiltRotation * fanRotation * facePlayer * standUp

                applyCardCurvature(card, curvature: sideSettings.curvature)

                card.move(
                    to: Transform(
                        scale: card.scale,
                        rotation: orientation,
                        translation: cardPosition
                    ),
                    relativeTo: nil,
                    duration: settings.inHandsAnimationDuration,
                    timingFunction: .easeInOut
                )
            }
        }
    }

}
