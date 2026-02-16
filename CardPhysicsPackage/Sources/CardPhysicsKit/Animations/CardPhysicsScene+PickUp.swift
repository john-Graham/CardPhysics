import Foundation
import RealityKit

extension CardPhysicsScene {

// MARK: - Safe Movement Wrapper

/// Safely move a card to a target transform, validating against table collision
private func moveCardSafely(
    _ card: Entity,
    to transform: Transform,
    duration: TimeInterval = 0.3,
    timingFunction: AnimationTimingFunction = .easeInOut
) {
    let curvature: Float = 0.0  // Cards in pickup are flat

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

// MARK: - Gather and Pick Up

public func gatherAndPickUp(corner: GatherCorner) async {
    guard !cards.isEmpty else { return }

    // Calculate corner position based on table dimensions
    // tableWidth=1.4, tableDepth=1.0, rail=0.07
    let cornerPosition: SIMD3<Float>
    switch corner {
    case .bottomLeft:
        cornerPosition = SIMD3<Float>(-0.55, 0.008, 0.38)
    case .topLeft:
        cornerPosition = SIMD3<Float>(-0.55, 0.008, -0.38)
    case .topRight:
        cornerPosition = SIMD3<Float>(0.55, 0.008, -0.38)
    case .bottomRight:
        cornerPosition = SIMD3<Float>(0.55, 0.008, 0.38)
    }

    // Phase 1 - Gather: slide all cards to the corner
    // Increment wear on each card during gathering
    for card in cards {
        incrementCardWear(card)
    }

    for (index, card) in cards.enumerated() {
        // Switch to kinematic mode for scripted animation
        if var physicsBody = card.components[PhysicsBodyComponent.self] {
            physicsBody.mode = .kinematic
            card.components[PhysicsBodyComponent.self] = physicsBody
        }
        // Remove any existing motion
        card.components[PhysicsMotionComponent.self] = nil

        let stackY = cornerPosition.y + Float(index) * 0.001
        let target = SIMD3<Float>(cornerPosition.x, stackY, cornerPosition.z)

        moveCardSafely(
            card,
            to: Transform(
                scale: card.scale,
                rotation: simd_quatf(angle: .pi, axis: [1, 0, 0]),
                translation: target
            ),
            duration: 0.4,
            timingFunction: .easeInOut
        )
    }

    // Wait for gather animation to complete
    try? await Task.sleep(for: .seconds(0.4))

    // Phase 2 - Visual pause
    try? await Task.sleep(for: .seconds(0.3))

    // Phase 3 - Pick up: lift the stack upward then remove
    for (index, card) in cards.enumerated() {
        let stackY = cornerPosition.y + Float(index) * 0.001 + 0.15
        let liftTarget = SIMD3<Float>(cornerPosition.x, stackY, cornerPosition.z)

        moveCardSafely(
            card,
            to: Transform(
                scale: card.scale,
                rotation: simd_quatf(angle: .pi, axis: [1, 0, 0]),
                translation: liftTarget
            ),
            duration: 0.3,
            timingFunction: .easeIn
        )
    }

    // Wait for lift animation to complete
    try? await Task.sleep(for: .seconds(0.3))

    // Remove cards from scene
    for card in cards {
        card.removeFromParent()
    }
    cards.removeAll()
    cardSideAssignments.removeAll()
}

/// Fans cards out in hands for each player position.
/// Cards are arranged in an arc pattern to simulate holding cards in hand.
}
