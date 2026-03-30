import Foundation
import RealityKit

extension CardPhysicsScene {

// MARK: - Deal Modes

public func dealCards(mode: DealMode) async {
    // Remove existing cards and hands
    for card in cards { card.removeFromParent() }
    cards.removeAll()
    cardSideAssignments.removeAll()
    cardWearComponents.removeAll()
    cardDataMap.removeAll()
    for hand in handEntities { hand.removeFromParent() }
    handEntities.removeAll()

    cardsInFanState = false

    createDeck(count: mode.cardCount)

    switch mode {
    case .euchre:
        await dealCardsEuchre()
    case .four, .twelve, .twenty:
        await dealCardsStandard()
    case .inHands:
        await dealCardsInHands()
    }

    // Wait for physics to settle, then stack cards neatly (except for inHands mode)
    if mode != .inHands {
        try? await Task.sleep(for: .seconds(2.0))
        await stackCardsBySide()
    }
}

internal func dealCardsStandard() async {
    // Deal cards one at a time, cycling through sides 2, 3, 4, 1
    for (dealIndex, cardIndex) in cards.indices.reversed().enumerated() {
        let card = cards[cardIndex]
        await dealSingleCard(card, toSide: [2, 3, 4, 1][dealIndex % 4], delay: dealIndex == 0 ? 0.0 : 0.3)
    }
}

internal func dealCardsEuchre() async {
    // Euchre dealing: 2 rounds, alternating bundles of 2 and 3
    // Round 1: 2 to side 2, 3 to side 3, 2 to side 4, 3 to side 1 (10 cards)
    // Round 2: 3 to side 2, 2 to side 3, 3 to side 4, 2 to side 1 (10 cards)
    let bundles: [(count: Int, side: Int)] = [
        // Round 1
        (2, 2), (3, 3), (2, 4), (3, 1),
        // Round 2
        (3, 2), (2, 3), (3, 4), (2, 1)
    ]

    var cardPointer = cards.count - 1  // Start from top of deck
    for bundle in bundles {
        guard cardPointer >= 0 else { break }
        let bundleCards = (0..<bundle.count).compactMap { offset -> Entity? in
            let idx = cardPointer - offset
            guard idx >= 0 else { return nil }
            return cards[idx]
        }
        cardPointer -= bundle.count

        // Throw all cards in the bundle nearly simultaneously with tight clustering
        for (offsetInBundle, card) in bundleCards.enumerated() {
            await dealSingleCard(
                card,
                toSide: bundle.side,
                delay: offsetInBundle == 0 ? 0.0 : 0.05,
                randomSpread: 0.025
            )
        }

        // Pause between bundles
        try? await Task.sleep(for: .seconds(0.3))
    }
}

internal func dealCardsInHands() async {
    // Create hands for all 4 sides
    for side in 1...4 {
        let handPosition = HandEntity3D.getHandPosition(side: side)
        let hand = HandEntity3D.makeHand(side: side, position: handPosition)
        handEntities.append(hand)
        rootEntity.addChild(hand)
    }

    // Distribute cards evenly to each side
    for (index, cardIndex) in cards.indices.reversed().enumerated() {
        let card = cards[cardIndex]
        let side = [1, 2, 3, 4][index % 4]
        cardSideAssignments[ObjectIdentifier(card)] = side
    }

    // Delegate to shared fan logic
    await fanCardsInHands()
}

internal func dealSingleCard(_ card: Entity, toSide sideIndex: Int, delay: Double, randomSpread: Float = 0.015) async {
    try? await Task.sleep(for: .seconds(delay))

    // Keep cards face-down (identity rotation) so camera sees backs
    card.orientation = simd_quatf(angle: 0, axis: [1, 0, 0])

    // Switch to dynamic mode so cards can interact with physics
    if var physicsBody = card.components[PhysicsBodyComponent.self] {
        physicsBody.mode = .dynamic
        card.components[PhysicsBodyComponent.self] = physicsBody
    }

    let randomX = Float.random(in: -randomSpread...randomSpread)
    let randomZ = Float.random(in: -randomSpread...randomSpread)

    let targetX: Float
    let targetZ: Float

    switch sideIndex {
    case 1:
        targetX = 0.0 + randomX
        targetZ = 0.35 + randomZ
    case 2:
        targetX = -0.55 + randomX
        targetZ = 0.0 + randomZ
    case 3:
        targetX = 0.0 + randomX
        targetZ = -0.35 + randomZ
    case 4:
        targetX = 0.55 + randomX
        targetZ = 0.0 + randomZ
    default:
        targetX = 0
        targetZ = 0
    }

    let startPos = card.position
    let targetPos = SIMD3<Float>(targetX, 0.008, targetZ)
    let horizontalDirection = SIMD3<Float>(
        targetPos.x - startPos.x,
        0,
        targetPos.z - startPos.z
    )
    let horizontalDistance = length(horizontalDirection)

    let horizontalSpeed: Float
    let upwardVelocity: Float
    let spinIntensity: Float

    switch sideIndex {
    case 1:
        horizontalSpeed = 0.5
        upwardVelocity = 0.0
        spinIntensity = 0.5
    case 2:
        horizontalSpeed = 1.1
        upwardVelocity = 0.4
        spinIntensity = 1.0
    case 3:
        horizontalSpeed = 1.4
        upwardVelocity = 0.35
        spinIntensity = 0.8
    case 4:
        horizontalSpeed = 1.1
        upwardVelocity = 0.4
        spinIntensity = 1.0
    default:
        horizontalSpeed = 0.0
        upwardVelocity = 0.0
        spinIntensity = 0.0
    }

    let horizontalVelocity = horizontalDistance > 0
        ? normalize(horizontalDirection) * horizontalSpeed
        : SIMD3<Float>(0, 0, 0)

    var motion = PhysicsMotionComponent()
    motion.linearVelocity = SIMD3<Float>(
        horizontalVelocity.x,
        upwardVelocity,
        horizontalVelocity.z
    )

    let ySpinAmount: Float = Float.random(in: 1.5...2.5) * spinIntensity
    let xTumbleAmount: Float = Float.random(in: -0.5...0.5) * spinIntensity
    let zTumbleAmount: Float = Float.random(in: -0.5...0.5) * spinIntensity
    let spinDirection: Float = (sideIndex == 2 || sideIndex == 1) ? -1.0 : 1.0

    motion.angularVelocity = [
        xTumbleAmount,
        ySpinAmount * spinDirection,
        zTumbleAmount
    ]

    card.components[PhysicsMotionComponent.self] = motion
    cardSideAssignments[ObjectIdentifier(card)] = sideIndex
}

internal func stackCardsBySide() async {
    guard !cards.isEmpty else { return }

    // Group cards by their assigned side
    var sideCards: [Int: [Entity]] = [:]
    for card in cards {
        let side = cardSideAssignments[ObjectIdentifier(card)] ?? 1
        sideCards[side, default: []].append(card)
    }

    // Stack center positions for each side
    let sidePositions: [Int: SIMD3<Float>] = [
        1: [0, 0.008, 0.35],
        2: [-0.55, 0.008, 0],
        3: [0, 0.008, -0.35],
        4: [0.55, 0.008, 0]
    ]

    // Y-axis rotation so cards face their player (face-down, backs visible)
    let sideRotations: [Int: simd_quatf] = [
        1: simd_quatf(angle: 0, axis: [1, 0, 0]),                                                           // face-down, backs up
        2: simd_quatf(angle: .pi / 2, axis: [0, 1, 0]),                                                     // face-down, rotated to face left
        3: simd_quatf(angle: .pi, axis: [0, 1, 0]),                                                         // face-down, rotated to face top
        4: simd_quatf(angle: -.pi / 2, axis: [0, 1, 0])                                                     // face-down, rotated to face right
    ]

    for (side, cardsInSide) in sideCards {
        guard let basePos = sidePositions[side],
              let rotation = sideRotations[side] else { continue }

        for (index, card) in cardsInSide.enumerated() {
            // Switch to kinematic for scripted animation
            if var physicsBody = card.components[PhysicsBodyComponent.self] {
                physicsBody.mode = .kinematic
                card.components[PhysicsBodyComponent.self] = physicsBody
            }
            card.components[PhysicsMotionComponent.self] = nil

            let stackY = basePos.y + Float(index) * 0.001
            let target = SIMD3<Float>(basePos.x, stackY, basePos.z)

            moveCardSafely(
                card,
                to: Transform(
                    scale: card.scale,
                    rotation: rotation,
                    translation: target
                ),
                duration: 0.4,
                timingFunction: .easeInOut
            )
        }
    }

    // Wait for stack animation to complete
    try? await Task.sleep(for: .seconds(0.4))
}

}
