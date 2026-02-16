import RealityKit

@MainActor
enum CollisionUtils {
    /// Calculate minimum safe Y position for a card accounting for rotation and curvature
    /// - Parameters:
    ///   - rotation: Card's rotation quaternion
    ///   - curvature: Card's parabolic curvature value (meters)
    ///   - cardHeight: Card thickness (meters)
    /// - Returns: Minimum Y position to keep card above origin plane
    static func minimumCardY(
        rotation: simd_quatf,
        curvature: Float,
        cardHeight: Float
    ) -> Float {
        // Base clearance is half the card thickness
        var minY = cardHeight / 2.0

        // Add curvature displacement (maximum bow height)
        if curvature != 0 {
            minY += abs(curvature)
        }

        // Account for rotation: if card is tilted, need more clearance
        // Extract rotation around X and Z axes
        let rotationMatrix = simd_float3x3(rotation)
        let upVector = rotationMatrix.columns.1  // Y-axis after rotation

        // If card is tilted (Y component < 1), add clearance
        // proportional to the tilt angle
        let tiltFactor = abs(1.0 - upVector.y)
        if tiltFactor > 0.01 {
            // Add extra clearance based on card dimensions and tilt
            let maxDimension = max(CardEntity3D.cardWidth, CardEntity3D.cardDepth)
            minY += maxDimension * tiltFactor * 0.5
        }

        return minY
    }

    /// Validate transform against table collision, return corrected transform if needed
    /// - Parameters:
    ///   - transform: Desired card transform
    ///   - cardWidth: Card width in meters
    ///   - cardHeight: Card thickness in meters
    ///   - cardDepth: Card depth in meters
    ///   - curvature: Card curvature value
    ///   - scene: RealityKit scene for ray casting (optional, for future enhancement)
    /// - Returns: Validated transform that won't penetrate the table
    static func validateCardTransform(
        _ transform: Transform,
        cardWidth: Float,
        cardHeight: Float,
        cardDepth: Float,
        curvature: Float,
        scene: Scene? = nil
    ) -> Transform {
        var validatedTransform = transform

        // Calculate minimum safe Y position
        let minY = minimumCardY(
            rotation: transform.rotation,
            curvature: curvature,
            cardHeight: cardHeight
        )

        // Table surface is at Y=0, ensure card stays above it
        let tableY: Float = 0.0
        let requiredY = tableY + minY

        // If card would penetrate table, raise it to safe height
        if validatedTransform.translation.y < requiredY {
            validatedTransform.translation.y = requiredY
        }

        return validatedTransform
    }

    /// Find table surface height below a given position using ray casting
    /// - Parameters:
    ///   - position: Position to cast ray from
    ///   - scene: RealityKit scene to query
    /// - Returns: Y coordinate of table surface, or nil if not found
    static func findTableSurfaceBelow(
        position: SIMD3<Float>,
        scene: Scene
    ) -> Float? {
        // Ray cast downward from position
        let rayOrigin = position
        let rayDirection = SIMD3<Float>(0, -1, 0)  // Downward

        // Perform ray cast query
        // Note: RealityKit's scene.raycast is available but requires proper collision layers
        // For now, we'll use a fixed table height assumption
        // This can be enhanced with actual raycasting when needed

        // Table surface is at Y=0 in our scene
        return 0.0
    }

    /// Validate that a card's position doesn't penetrate table rails or boundaries
    /// - Parameters:
    ///   - position: Card position to validate
    ///   - tableWidth: Table width (X dimension)
    ///   - tableDepth: Table depth (Z dimension)
    ///   - railHeight: Height of table rails
    ///   - cardRadius: Approximate card radius for boundary checking
    /// - Returns: Corrected position if needed
    static func validateTableBoundaries(
        position: SIMD3<Float>,
        tableWidth: Float,
        tableDepth: Float,
        railHeight: Float,
        cardRadius: Float
    ) -> SIMD3<Float> {
        var validatedPosition = position

        // Keep cards within table boundaries (with some margin)
        let halfWidth = tableWidth / 2.0 - cardRadius
        let halfDepth = tableDepth / 2.0 - cardRadius

        // Clamp X position
        validatedPosition.x = max(-halfWidth, min(halfWidth, validatedPosition.x))

        // Clamp Z position
        validatedPosition.z = max(-halfDepth, min(halfDepth, validatedPosition.z))

        // Ensure card stays above table surface and below reasonable height
        let minY: Float = 0.001  // Just above table
        let maxY: Float = 0.5    // Reasonable max height
        validatedPosition.y = max(minY, min(maxY, validatedPosition.y))

        return validatedPosition
    }
}
