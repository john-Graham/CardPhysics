import Foundation
import RealityKit

extension CardPhysicsScene {

    /// Safely move a card to a target transform, validating against table collision.
    /// Shared by all animation files (Dealing, InHands, PickUp).
    internal func moveCardSafely(
        _ card: Entity,
        to transform: Transform,
        duration: TimeInterval = 0.3,
        timingFunction: AnimationTimingFunction = .easeInOut,
        curvature: Float = 0.0,
        clampToBounds: Bool = false
    ) {
        let safeTransform = CollisionUtils.validateCardTransform(
            transform,
            cardWidth: CardEntity3D.cardWidth,
            cardHeight: CardEntity3D.cardHeight,
            cardDepth: CardEntity3D.cardDepth,
            curvature: curvature,
            clampToBounds: clampToBounds
        )

        card.move(to: safeTransform, relativeTo: nil, duration: duration, timingFunction: timingFunction)
    }

    /// Validate a position against table collision, returning a corrected position.
    /// Used for real-time slider updates where position is set directly (no animation).
    internal func validateCardPosition(
        _ position: SIMD3<Float>,
        rotation: simd_quatf,
        curvature: Float = 0.0,
        clampToBounds: Bool = false
    ) -> SIMD3<Float> {
        let transform = Transform(rotation: rotation, translation: position)

        let safeTransform = CollisionUtils.validateCardTransform(
            transform,
            cardWidth: CardEntity3D.cardWidth,
            cardHeight: CardEntity3D.cardHeight,
            cardDepth: CardEntity3D.cardDepth,
            curvature: curvature,
            clampToBounds: clampToBounds
        )

        return safeTransform.translation
    }
}
