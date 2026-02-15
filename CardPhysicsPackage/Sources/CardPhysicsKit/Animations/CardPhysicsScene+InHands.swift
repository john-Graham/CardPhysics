import RealityKit

extension CardPhysicsScene {
public func fanCardsInHands() async {
    guard !cards.isEmpty else { return }

    // Group cards by their assigned side
    var sideCards: [Int: [Entity]] = [:]
    for card in cards {
        let side = cardSideAssignments[ObjectIdentifier(card)] ?? 1
        sideCards[side, default: []].append(card)
    }

    // Fan parameters
    let fanRadius: Float = 0.35  // Radius of the arc
    let fanSpread: Float = 0.7   // Total angular spread in radians (~40 degrees)
    let cardHeight: Float = 0.15 // How much to lift cards
    let cardTilt: Float = 0.3    // Forward tilt of cards (radians)

    // Base positions for each hand (closer to player than stack positions)
    let handPositions: [Int: SIMD3<Float>] = [
        1: [0, cardHeight, 0.45],      // Bottom player (closest to viewer)
        2: [-0.65, cardHeight, 0],     // Left player
        3: [0, cardHeight, -0.45],     // Top player (farthest)
        4: [0.65, cardHeight, 0]       // Right player
    ]

    // Base rotations for each side (Y-axis rotation to face player)
    let baseYRotations: [Int: Float] = [
        1: 0,           // Bottom: facing viewer (0 degrees)
        2: .pi / 2,     // Left: rotated 90 degrees
        3: .pi,         // Top: rotated 180 degrees
        4: -.pi / 2     // Right: rotated -90 degrees
    ]

    for (side, cardsInSide) in sideCards {
        guard let centerPos = handPositions[side],
              let baseYRot = baseYRotations[side] else { continue }

        let cardCount = cardsInSide.count
        guard cardCount > 0 else { continue }

        for (index, card) in cardsInSide.enumerated() {
            // Switch to kinematic for scripted animation
            if var physicsBody = card.components[PhysicsBodyComponent.self] {
                physicsBody.mode = .kinematic
                card.components[PhysicsBodyComponent.self] = physicsBody
            }
            card.components[PhysicsMotionComponent.self] = nil

            // Calculate fan angle for this card
            // Center the fan around 0, spreading cards evenly
            let normalizedIndex = Float(index) - Float(cardCount - 1) / 2.0
            let fanAngle = (normalizedIndex / Float(max(cardCount - 1, 1))) * fanSpread

            // Calculate position on the arc
            // The arc is in the local XZ plane before rotation
            let localX = sin(fanAngle) * fanRadius
            let localZ = -cos(fanAngle) * fanRadius + fanRadius  // Offset so arc curves toward player

            // Transform to world coordinates based on side
            let position: SIMD3<Float>
            switch side {
            case 1: // Bottom
                position = SIMD3<Float>(
                    centerPos.x + localX,
                    centerPos.y,
                    centerPos.z + localZ
                )
            case 2: // Left
                position = SIMD3<Float>(
                    centerPos.x + localZ,
                    centerPos.y,
                    centerPos.z + localX
                )
            case 3: // Top
                position = SIMD3<Float>(
                    centerPos.x - localX,
                    centerPos.y,
                    centerPos.z - localZ
                )
            case 4: // Right
                position = SIMD3<Float>(
                    centerPos.x - localZ,
                    centerPos.y,
                    centerPos.z - localX
                )
            default:
                position = centerPos
            }

            // Calculate rotation
            // Start with face-up, then apply tilt, then apply fan rotation, then apply side rotation
            let faceUpQuat = simd_quatf(angle: .pi, axis: [1, 0, 0])  // Face-up
            let tiltQuat = simd_quatf(angle: cardTilt, axis: [1, 0, 0])  // Tilt cards back
            let fanQuat = simd_quatf(angle: fanAngle, axis: [0, 1, 0])  // Fan spread
            let sideQuat = simd_quatf(angle: baseYRot, axis: [0, 1, 0])  // Orient to side

            // Combine rotations: side * fan * tilt * faceUp
            let finalRotation = sideQuat * fanQuat * tiltQuat * faceUpQuat

            // Animate card to fanned position
            card.move(
                to: Transform(
                    scale: card.scale,
                    rotation: finalRotation,
                    translation: position
                ),
                relativeTo: nil,
                duration: 0.6,
                timingFunction: .easeInOut
            )
        }
    }

    // Wait for animation to complete
    try? await Task.sleep(for: .seconds(0.6))
}

/// Flips a card 180 degrees around the X axis with a short animation.
/// Only flips cards that are in dynamic or kinematic mode (not during active move animations).
internal func flipCard(_ card: Entity) {
    guard let physicsBody = card.components[PhysicsBodyComponent.self],
          physicsBody.mode == .dynamic || physicsBody.mode == .kinematic else {
        return
    }

    // Increment wear on flip interaction
    incrementCardWear(card)

    // Determine current face orientation: face-up has ~pi rotation around X
    let currentRotation = card.orientation
    // Check if the card's local Y axis is pointing down (face-up) or up (face-down)
    let localUp = currentRotation.act(SIMD3<Float>(0, 1, 0))
    let isFaceUp = localUp.y < 0

    // Target orientation: toggle between face-up (pi around X) and face-down (identity)
    let targetOrientation = isFaceUp
        ? simd_quatf(angle: 0, axis: [1, 0, 0])  // face-down (identity)
        : simd_quatf(angle: .pi, axis: [1, 0, 0]) // face-up

    // Temporarily switch to kinematic for the flip animation
    let previousMode = physicsBody.mode
    if previousMode == .dynamic {
        var body = physicsBody
        body.mode = .kinematic
        card.components[PhysicsBodyComponent.self] = body
        card.components[PhysicsMotionComponent.self] = nil
    }

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

    // Restore dynamic mode after flip completes
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

/// Updates the positions of cards already in hands based on current settings
/// without re-dealing them. Used for real-time slider adjustments.
internal func updateInHandsCardPositions() {
    guard !cards.isEmpty else { return }

    // Group cards by their assigned side
    var sideCards: [Int: [Entity]] = [:]
    for card in cards {
        let side = cardSideAssignments[ObjectIdentifier(card)] ?? 1
        sideCards[side, default: []].append(card)
    }

    // Update positions for each side
    for side in 1...4 {
        guard let cardsInSide = sideCards[side], !cardsInSide.isEmpty else { continue }

        let fanCenter = HandEntity3D.getFanCenterPosition(side: side)
        let sideSettings = settings.inHandsSettings(for: side)

        for (cardIndex, card) in cardsInSide.enumerated() {
            // Calculate fan arc parameters from per-side settings
            let fanAngle = sideSettings.fanAngle
            let verticalOffset = sideSettings.verticalSpacing
            let arcRadius = sideSettings.arcRadius

            // Calculate position in fan (centered around middle card)
            let normalizedIndex = Float(cardIndex) / Float(max(cardsInSide.count - 1, 1))
            let fanProgress = normalizedIndex - 0.5
            let arcAngle = fanProgress * fanAngle

            // Position based on side orientation
            var cardPosition: SIMD3<Float>
            var cardRotation: simd_quatf

            // Quaternion components for proper card orientation
            let faceUpQuat = simd_quatf(angle: .pi, axis: [1, 0, 0])
            let tiltQuat = simd_quatf(angle: sideSettings.tiltAngle, axis: [1, 0, 0])
            let fanQuat = simd_quatf(angle: arcAngle, axis: [0, 1, 0])
            let offsetQuat = simd_quatf(angle: sideSettings.rotationOffset, axis: [0, 1, 0])

            switch side {
            case 1: // Bottom
                cardPosition = SIMD3(
                    fanCenter.x + sin(arcAngle) * arcRadius,
                    fanCenter.y + Float(cardIndex) * verticalOffset,
                    fanCenter.z - cos(arcAngle) * arcRadius + arcRadius
                )
                cardRotation = offsetQuat * fanQuat * tiltQuat * faceUpQuat

            case 2: // Left
                cardPosition = SIMD3(
                    fanCenter.x + cos(arcAngle) * arcRadius - arcRadius,
                    fanCenter.y + Float(cardIndex) * verticalOffset,
                    fanCenter.z + sin(arcAngle) * arcRadius
                )
                let sideQuat2 = simd_quatf(angle: .pi / 2, axis: [0, 1, 0])
                cardRotation = sideQuat2 * offsetQuat * fanQuat * tiltQuat * faceUpQuat

            case 3: // Top
                cardPosition = SIMD3(
                    fanCenter.x - sin(arcAngle) * arcRadius,
                    fanCenter.y + Float(cardIndex) * verticalOffset,
                    fanCenter.z + cos(arcAngle) * arcRadius - arcRadius
                )
                let sideQuat3 = simd_quatf(angle: .pi, axis: [0, 1, 0])
                cardRotation = sideQuat3 * offsetQuat * fanQuat * tiltQuat * faceUpQuat

            case 4: // Right
                cardPosition = SIMD3(
                    fanCenter.x - cos(arcAngle) * arcRadius + arcRadius,
                    fanCenter.y + Float(cardIndex) * verticalOffset,
                    fanCenter.z - sin(arcAngle) * arcRadius
                )
                let sideQuat4 = simd_quatf(angle: -.pi / 2, axis: [0, 1, 0])
                cardRotation = sideQuat4 * offsetQuat * fanQuat * tiltQuat * faceUpQuat

            default:
                cardPosition = fanCenter
                cardRotation = offsetQuat * faceUpQuat
            }

            // Update card transform instantly (no animation for real-time feedback)
            card.position = cardPosition
            card.orientation = cardRotation
        }
    }
}

}
