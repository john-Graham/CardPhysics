import RealityKit

// MARK: - Table Geometry Constants

@MainActor
enum TableGeometry {
    static let tableWidth: Float = 1.4
    static let tableDepth: Float = 1.0
    static let railThickness: Float = 0.07
    static let railHeight: Float = 0.035
    static let cardPlacementMargin: Float = 0.015

    /// Top of the felt box (5mm box centered at Y=0.0025)
    static let feltSurfaceY: Float = 0.005

    /// Inner playable area (inside rail inner edges)
    static let innerMinX: Float = -(tableWidth / 2 - railThickness)   // -0.63
    static let innerMaxX: Float = tableWidth / 2 - railThickness      //  0.63
    static let innerMinZ: Float = -(tableDepth / 2 - railThickness)   // -0.43
    static let innerMaxZ: Float = tableDepth / 2 - railThickness      //  0.43

    static func cardCenter(for side: Int, y: Float = 0.008) -> SIMD3<Float> {
        let xLimit = innerMaxX - CardEntity3D.cardDepth / 2 - cardPlacementMargin
        let zLimit = innerMaxZ - CardEntity3D.cardDepth / 2 - cardPlacementMargin

        switch side {
        case 1:
            return [0, y, zLimit]
        case 2:
            return [-xLimit, y, 0]
        case 3:
            return [0, y, -zLimit]
        case 4:
            return [xLimit, y, 0]
        default:
            return [0, y, 0]
        }
    }

    static func cardRotation(for side: Int) -> simd_quatf {
        switch side {
        case 1:
            return simd_quatf(angle: 0, axis: [1, 0, 0])
        case 2:
            return simd_quatf(angle: .pi / 2, axis: [0, 1, 0])
        case 3:
            return simd_quatf(angle: .pi, axis: [0, 1, 0])
        case 4:
            return simd_quatf(angle: -.pi / 2, axis: [0, 1, 0])
        default:
            return simd_quatf(angle: 0, axis: [1, 0, 0])
        }
    }
}

// MARK: - Collision Utilities

@MainActor
enum CollisionUtils {

    /// Compute the 4 card corners in world space after applying rotation.
    /// Corners are at the card's mid-plane (Y=0 in local space).
    static func cardCornerPositions(
        transform: Transform,
        cardWidth: Float,
        cardDepth: Float
    ) -> (SIMD3<Float>, SIMD3<Float>, SIMD3<Float>, SIMD3<Float>) {
        let halfW = cardWidth / 2
        let halfD = cardDepth / 2

        let rotation = transform.rotation
        let t = transform.translation

        let c0 = rotation.act(SIMD3(-halfW, 0, -halfD)) + t
        let c1 = rotation.act(SIMD3( halfW, 0, -halfD)) + t
        let c2 = rotation.act(SIMD3(-halfW, 0,  halfD)) + t
        let c3 = rotation.act(SIMD3( halfW, 0,  halfD)) + t

        return (c0, c1, c2, c3)
    }

    /// Calculate how much to raise a card so that no corner or the curved center
    /// penetrates the felt surface.
    /// - Returns: The Y offset to add (0 if no raise needed)
    static func minimumYRaise(
        transform: Transform,
        cardWidth: Float,
        cardHeight: Float,
        cardDepth: Float,
        curvature: Float
    ) -> Float {
        let (c0, c1, c2, c3) = cardCornerPositions(
            transform: transform,
            cardWidth: cardWidth,
            cardDepth: cardDepth
        )

        let halfThickness = cardHeight / 2

        // Lowest corner Y, offset by half card thickness below the mid-plane
        let lowestCornerY = min(min(c0.y, c1.y), min(c2.y, c3.y)) - halfThickness

        // Curvature pushes the center of the card downward (in local space)
        // by abs(curvature). Transform that point to world space.
        var lowestY = lowestCornerY
        if curvature != 0 {
            let centerBottom = transform.rotation.act(
                SIMD3(0, -halfThickness - abs(curvature), 0)
            ) + transform.translation
            lowestY = min(lowestY, centerBottom.y)
        }

        let gap = TableGeometry.feltSurfaceY - lowestY
        return gap > 0 ? gap : 0
    }

    /// Shift the card center so no corner extends past the inner rail edges.
    /// - Returns: Corrected translation
    static func clampToBoundaries(
        transform: Transform,
        cardWidth: Float,
        cardDepth: Float
    ) -> SIMD3<Float> {
        let (c0, c1, c2, c3) = cardCornerPositions(
            transform: transform,
            cardWidth: cardWidth,
            cardDepth: cardDepth
        )

        var translation = transform.translation

        let minCX = min(min(c0.x, c1.x), min(c2.x, c3.x))
        let maxCX = max(max(c0.x, c1.x), max(c2.x, c3.x))
        let minCZ = min(min(c0.z, c1.z), min(c2.z, c3.z))
        let maxCZ = max(max(c0.z, c1.z), max(c2.z, c3.z))

        if minCX < TableGeometry.innerMinX {
            translation.x += (TableGeometry.innerMinX - minCX)
        } else if maxCX > TableGeometry.innerMaxX {
            translation.x -= (maxCX - TableGeometry.innerMaxX)
        }

        if minCZ < TableGeometry.innerMinZ {
            translation.z += (TableGeometry.innerMinZ - minCZ)
        } else if maxCZ > TableGeometry.innerMaxZ {
            translation.z -= (maxCZ - TableGeometry.innerMaxZ)
        }

        return translation
    }

    /// Validate a card transform against table collision, returning a corrected transform.
    /// - Parameters:
    ///   - transform: Desired card transform
    ///   - cardWidth: Card width in meters
    ///   - cardHeight: Card thickness in meters
    ///   - cardDepth: Card depth in meters
    ///   - curvature: Card curvature value (meters of parabolic bow)
    ///   - clampToBounds: Whether to clamp X/Z within rail boundaries
    /// - Returns: Validated transform that won't penetrate the table or rails
    static func validateCardTransform(
        _ transform: Transform,
        cardWidth: Float,
        cardHeight: Float,
        cardDepth: Float,
        curvature: Float,
        clampToBounds: Bool = false
    ) -> Transform {
        var result = transform

        // Raise Y if any corner/center would penetrate the felt surface
        let raise = minimumYRaise(
            transform: result,
            cardWidth: cardWidth,
            cardHeight: cardHeight,
            cardDepth: cardDepth,
            curvature: curvature
        )
        if raise > 0 {
            result.translation.y += raise
        }

        // Optionally clamp X/Z to keep within rails
        if clampToBounds {
            result.translation = clampToBoundaries(
                transform: result,
                cardWidth: cardWidth,
                cardDepth: cardDepth
            )
        }

        return result
    }
}
