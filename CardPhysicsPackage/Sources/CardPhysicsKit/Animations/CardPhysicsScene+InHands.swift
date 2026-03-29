import Foundation
import RealityKit

extension CardPhysicsScene {

// MARK: - Safe Movement Wrapper

/// Safely move a card to a target transform, validating against table collision
private func moveCardSafely(
    _ card: Entity,
    to transform: Transform,
    duration: TimeInterval = 0.3,
    timingFunction: AnimationTimingFunction = .easeInOut,
    curvature: Float = 0.0
) {
    let safeTransform = CollisionUtils.validateCardTransform(
        transform,
        cardWidth: CardEntity3D.cardWidth,
        cardHeight: CardEntity3D.cardHeight,
        cardDepth: CardEntity3D.cardDepth,
        curvature: curvature,
        scene: nil
    )

    card.move(to: safeTransform, relativeTo: nil, duration: duration, timingFunction: timingFunction)
}

/// Validate a position against table collision
private func validateCardPosition(
    _ position: SIMD3<Float>,
    rotation: simd_quatf,
    curvature: Float = 0.0
) -> SIMD3<Float> {
    let transform = Transform(rotation: rotation, translation: position)

    let safeTransform = CollisionUtils.validateCardTransform(
        transform,
        cardWidth: CardEntity3D.cardWidth,
        cardHeight: CardEntity3D.cardHeight,
        cardDepth: CardEntity3D.cardDepth,
        curvature: curvature,
        scene: nil
    )

    return safeTransform.translation
}

/// Apply curvature to a card's mesh for the in-hand look
private func applyCardCurvature(_ card: Entity, curvature: Float) {
    guard let modelEntity = card as? ModelEntity,
          var modelComponent = modelEntity.model else { return }
    modelComponent.mesh = CurvedCardMesh.mesh(curvature: curvature)
    modelEntity.model = modelComponent
}

// MARK: - Fan Cards

public func fanCardsInHands() async {
    guard !cards.isEmpty else { return }

    // Group cards by their assigned side
    var sideCards: [Int: [Entity]] = [:]
    for card in cards {
        let side = cardSideAssignments[ObjectIdentifier(card)] ?? 1
        sideCards[side, default: []].append(card)
    }

    let cardHeight: Float = 0.15 // How much to lift cards off table

    // Stack positions for each hand (at table edge, closer to player)
    let stackPositions: [Int: SIMD3<Float>] = [
        1: [0, cardHeight, 0.45],      // Bottom player (closest to viewer)
        2: [-0.65, cardHeight, 0],     // Left player
        3: [0, cardHeight, -0.45],     // Top player (farthest)
        4: [0.65, cardHeight, 0]       // Right player
    ]

    for (side, cardsInSide) in sideCards {
        guard let stackCenter = stackPositions[side] else { continue }

        let cardCount = cardsInSide.count
        guard cardCount > 0 else { continue }

        for (index, card) in cardsInSide.enumerated() {
            // Switch to kinematic for scripted animation
            if var physicsBody = card.components[PhysicsBodyComponent.self] {
                physicsBody.mode = .kinematic
                card.components[PhysicsBodyComponent.self] = physicsBody
            }
            card.components[PhysicsMotionComponent.self] = nil

            // STEP 1: Stack cards vertically (perpendicular to table)
            // - Cards stand STRAIGHT UP (perpendicular to table, no tilt)
            // - Face pointing outward toward player
            // - Cards stacked with thickness offset (0.0015m per card)

            // Base vertical orientation:
            // Rotate 90° around X to stand card up (was lying flat, now vertical)
            let standUpRotation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])

            // Rotate around Y to face the player position
            let faceOutwardRotation: simd_quatf
            let stackDirection: SIMD3<Float> // Direction to offset cards in stack

            switch side {
            case 1: // Bottom player - face toward camera (+Z)
                // After standing up, card faces -Z, so rotate 180° around Y to face +Z
                faceOutwardRotation = simd_quatf(angle: .pi, axis: [0, 1, 0])
                // Stack toward table center (backs point -Z)
                stackDirection = [0, 0, -1]

            case 2: // Left player - face toward left (-X)
                // After standing up, rotate 90° around Y to face left
                faceOutwardRotation = simd_quatf(angle: .pi / 2, axis: [0, 1, 0])
                // Stack toward table center (backs point +X)
                stackDirection = [1, 0, 0]

            case 3: // Top player - face away from camera (-Z)
                // After standing up, card already faces -Z, no additional rotation
                faceOutwardRotation = simd_quatf(angle: 0, axis: [0, 1, 0])
                // Stack toward camera (backs point +Z)
                stackDirection = [0, 0, 1]

            case 4: // Right player - face toward right (+X)
                // After standing up, rotate -90° around Y to face right
                faceOutwardRotation = simd_quatf(angle: -.pi / 2, axis: [0, 1, 0])
                // Stack toward table center (backs point -X)
                stackDirection = [-1, 0, 0]

            default:
                faceOutwardRotation = simd_quatf(angle: 0, axis: [0, 1, 0])
                stackDirection = [0, 0, 0]
            }

            // Combine: first stand up, then rotate to face outward (NO TILT)
            let stackedRotation = faceOutwardRotation * standUpRotation

            // Stack position with thickness offset (0.0015m per card for visibility)
            let cardThickness: Float = 0.0015
            let stackOffset = stackDirection * (Float(index) * cardThickness)
            let stackPosition = stackCenter + stackOffset

            // Animate card to stacked vertical position (with collision validation)
            moveCardSafely(
                card,
                to: Transform(
                    scale: card.scale,
                    rotation: stackedRotation,
                    translation: stackPosition
                ),
                duration: 0.6,
                timingFunction: .easeInOut
            )
        }
    }

    // Wait for stacking animation to complete
    try? await Task.sleep(for: .seconds(0.6))

    // STEP 2: Apply curvature and fan out from stacked position
    for card in cards {
        let side = cardSideAssignments[ObjectIdentifier(card)] ?? 1
        let sideSettings = settings.inHandsSettings(for: side)
        if sideSettings.curvature != 0 {
            applyCardCurvature(card, curvature: sideSettings.curvature)
        }
    }

    // Update positions to fan out with curvature applied
    updateInHandsCardPositions()
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

            // Fan from bottom of deck: first card at center, others spread outward
            // Cards fan symmetrically around center (middle card straight)
            let normalizedIndex = Float(cardIndex) / Float(max(cardsInSide.count - 1, 1))
            let fanProgress = normalizedIndex - 0.5  // -0.5 to 0.5 (centered)
            let arcAngle = fanProgress * fanAngle

            // Base vertical orientation (same as fanCardsInHands):
            // 1. Stand card up perpendicular to table
            let standUpRotation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])

            // 2. Rotate to face player position
            let faceOutwardRotation: simd_quatf
            let stackDirection: SIMD3<Float>

            switch side {
            case 1: // Bottom player - face toward camera (+Z)
                faceOutwardRotation = simd_quatf(angle: .pi, axis: [0, 1, 0])
                stackDirection = [0, 0, -1]

            case 2: // Left player - face toward left (-X)
                faceOutwardRotation = simd_quatf(angle: .pi / 2, axis: [0, 1, 0])
                stackDirection = [1, 0, 0]

            case 3: // Top player - face away from camera (-Z)
                faceOutwardRotation = simd_quatf(angle: 0, axis: [0, 1, 0])
                stackDirection = [0, 0, 1]

            case 4: // Right player - face toward right (+X)
                faceOutwardRotation = simd_quatf(angle: -.pi / 2, axis: [0, 1, 0])
                stackDirection = [-1, 0, 0]

            default:
                faceOutwardRotation = simd_quatf(angle: 0, axis: [0, 1, 0])
                stackDirection = [0, 0, 0]
            }

            // 3. Apply slider adjustments from vertical base
            let tiltQuat = simd_quatf(angle: sideSettings.tiltAngle, axis: [1, 0, 0])
            let fanQuat = simd_quatf(angle: arcAngle, axis: [0, 1, 0])
            let offsetQuat = simd_quatf(angle: sideSettings.rotationOffset, axis: [0, 1, 0])

            // Combine rotations: face outward, then fan, then tilt, then rotation offset, then stand up
            let cardRotation = offsetQuat * fanQuat * tiltQuat * faceOutwardRotation * standUpRotation

            // Calculate position: pivot from bottom center of deck
            // Bottom center is at fanCenter - cards fan out from there
            let cardThickness: Float = 0.0015

            // Start at pivot point (bottom center of deck)
            let pivotPoint = fanCenter

            // Calculate offset from pivot based on fan angle and arc radius
            // Each card rotates around the pivot and moves outward along the arc
            var cardPosition: SIMD3<Float>

            switch side {
            case 1: // Bottom - fan spreads left/right (+/-X), arc extends toward player (+Z)
                let fanX = sin(arcAngle) * arcRadius
                let fanZ = (1.0 - cos(arcAngle)) * arcRadius  // Arc toward player
                cardPosition = SIMD3(
                    pivotPoint.x + fanX,
                    pivotPoint.y + Float(cardIndex) * verticalOffset,
                    pivotPoint.z + fanZ
                )
                // Stack offset perpendicular to face
                cardPosition += stackDirection * (Float(cardIndex) * cardThickness)

            case 2: // Left - fan spreads up/down (+/-Z), arc extends toward player (-X)
                let fanZ = sin(arcAngle) * arcRadius
                let fanX = -(1.0 - cos(arcAngle)) * arcRadius  // Arc toward player (left)
                cardPosition = SIMD3(
                    pivotPoint.x + fanX,
                    pivotPoint.y + Float(cardIndex) * verticalOffset,
                    pivotPoint.z + fanZ
                )
                cardPosition += stackDirection * (Float(cardIndex) * cardThickness)

            case 3: // Top - fan spreads left/right (+/-X), arc extends toward player (-Z)
                let fanX = sin(arcAngle) * arcRadius
                let fanZ = -(1.0 - cos(arcAngle)) * arcRadius  // Arc toward player (away)
                cardPosition = SIMD3(
                    pivotPoint.x - fanX,  // Mirror X for top player
                    pivotPoint.y + Float(cardIndex) * verticalOffset,
                    pivotPoint.z + fanZ
                )
                cardPosition += stackDirection * (Float(cardIndex) * cardThickness)

            case 4: // Right - fan spreads up/down (+/-Z), arc extends toward player (+X)
                let fanZ = sin(arcAngle) * arcRadius
                let fanX = (1.0 - cos(arcAngle)) * arcRadius  // Arc toward player (right)
                cardPosition = SIMD3(
                    pivotPoint.x + fanX,
                    pivotPoint.y + Float(cardIndex) * verticalOffset,
                    pivotPoint.z - fanZ  // Mirror Z for right player
                )
                cardPosition += stackDirection * (Float(cardIndex) * cardThickness)

            default:
                cardPosition = pivotPoint
            }

            // Apply curvature to card mesh
            applyCardCurvature(card, curvature: sideSettings.curvature)

            // Update card transform instantly (no animation for real-time feedback)
            // Validate position to prevent table penetration
            let safePosition = validateCardPosition(cardPosition, rotation: cardRotation, curvature: sideSettings.curvature)
            card.position = safePosition
            card.orientation = cardRotation
        }
    }
}

}
