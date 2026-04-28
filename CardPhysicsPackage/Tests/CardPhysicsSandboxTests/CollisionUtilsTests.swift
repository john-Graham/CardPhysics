import Testing
import RealityKit
import CardEngine
@testable import CardPhysicsSandbox

// MARK: - TableGeometry Tests

@Test @MainActor func tableGeometrySymmetry() {
    #expect(TableGeometry.feltSurfaceY > 0)
    #expect(TableGeometry.innerMinX < 0)
    #expect(TableGeometry.innerMaxX > 0)
    #expect(TableGeometry.innerMinX == -TableGeometry.innerMaxX)
    #expect(TableGeometry.innerMinZ == -TableGeometry.innerMaxZ)
}

@Test @MainActor func sideCardCentersLeaveMarginInsideRails() {
    for side in 1...4 {
        let transform = Transform(
            rotation: TableGeometry.cardRotation(for: side),
            translation: TableGeometry.cardCenter(for: side)
        )

        let (c0, c1, c2, c3) = CollisionUtils.cardCornerPositions(
            transform: transform,
            cardWidth: CardEntity3D.cardWidth,
            cardDepth: CardEntity3D.cardDepth
        )
        let minX = min(min(c0.x, c1.x), min(c2.x, c3.x))
        let maxX = max(max(c0.x, c1.x), max(c2.x, c3.x))
        let minZ = min(min(c0.z, c1.z), min(c2.z, c3.z))
        let maxZ = max(max(c0.z, c1.z), max(c2.z, c3.z))

        #expect(minX >= TableGeometry.innerMinX)
        #expect(maxX <= TableGeometry.innerMaxX)
        #expect(minZ >= TableGeometry.innerMinZ)
        #expect(maxZ <= TableGeometry.innerMaxZ)
    }
}

// MARK: - Y Validation Tests

@Test @MainActor func flatCardAtOriginIsRaisedAboveFelt() {
    let transform = Transform(translation: [0, 0, 0])
    let safe = CollisionUtils.validateCardTransform(
        transform,
        cardWidth: CardEntity3D.cardWidth,
        cardHeight: CardEntity3D.cardHeight,
        cardDepth: CardEntity3D.cardDepth,
        curvature: 0.0
    )
    #expect(safe.translation.y >= TableGeometry.feltSurfaceY)
}

@Test @MainActor func cardAboveTableIsNotMoved() {
    let transform = Transform(translation: [0, 0.2, 0])
    let safe = CollisionUtils.validateCardTransform(
        transform,
        cardWidth: CardEntity3D.cardWidth,
        cardHeight: CardEntity3D.cardHeight,
        cardDepth: CardEntity3D.cardDepth,
        curvature: 0.0
    )
    #expect(safe.translation.y == 0.2)
}

@Test @MainActor func tiltedCardNeedsMoreClearanceThanFlat() {
    let flatTransform = Transform(translation: [0, 0, 0])
    let flatSafe = CollisionUtils.validateCardTransform(
        flatTransform,
        cardWidth: CardEntity3D.cardWidth,
        cardHeight: CardEntity3D.cardHeight,
        cardDepth: CardEntity3D.cardDepth,
        curvature: 0.0
    )

    let tiltedRotation = simd_quatf(angle: .pi / 4, axis: [1, 0, 0])
    let tiltedTransform = Transform(rotation: tiltedRotation, translation: [0, 0, 0])
    let tiltedSafe = CollisionUtils.validateCardTransform(
        tiltedTransform,
        cardWidth: CardEntity3D.cardWidth,
        cardHeight: CardEntity3D.cardHeight,
        cardDepth: CardEntity3D.cardDepth,
        curvature: 0.0
    )

    #expect(tiltedSafe.translation.y > flatSafe.translation.y)
}

@Test @MainActor func curvedCardCenterIsValidated() {
    // A curved card low to the table should be raised because curvature
    // pushes the center downward
    let transform = Transform(translation: [0, 0.01, 0])
    let safe = CollisionUtils.validateCardTransform(
        transform,
        cardWidth: CardEntity3D.cardWidth,
        cardHeight: CardEntity3D.cardHeight,
        cardDepth: CardEntity3D.cardDepth,
        curvature: -0.015
    )
    #expect(safe.translation.y > transform.translation.y)
}

// MARK: - Boundary Clamping Tests

@Test @MainActor func cardPastLeftRailIsClampedInward() {
    let transform = Transform(translation: [-0.7, 0.05, 0])
    let safe = CollisionUtils.validateCardTransform(
        transform,
        cardWidth: CardEntity3D.cardWidth,
        cardHeight: CardEntity3D.cardHeight,
        cardDepth: CardEntity3D.cardDepth,
        curvature: 0.0,
        clampToBounds: true
    )

    let (c0, c1, c2, c3) = CollisionUtils.cardCornerPositions(
        transform: safe,
        cardWidth: CardEntity3D.cardWidth,
        cardDepth: CardEntity3D.cardDepth
    )
    let minX = min(min(c0.x, c1.x), min(c2.x, c3.x))
    #expect(minX >= TableGeometry.innerMinX)
}

@Test @MainActor func cardPastBottomRailIsClampedInward() {
    let transform = Transform(translation: [0, 0.05, 0.6])
    let safe = CollisionUtils.validateCardTransform(
        transform,
        cardWidth: CardEntity3D.cardWidth,
        cardHeight: CardEntity3D.cardHeight,
        cardDepth: CardEntity3D.cardDepth,
        curvature: 0.0,
        clampToBounds: true
    )

    let (c0, c1, c2, c3) = CollisionUtils.cardCornerPositions(
        transform: safe,
        cardWidth: CardEntity3D.cardWidth,
        cardDepth: CardEntity3D.cardDepth
    )
    let maxZ = max(max(c0.z, c1.z), max(c2.z, c3.z))
    #expect(maxZ <= TableGeometry.innerMaxZ)
}

@Test @MainActor func cardInsideBoundsIsNotClamped() {
    let transform = Transform(translation: [0.1, 0.05, -0.1])
    let safe = CollisionUtils.validateCardTransform(
        transform,
        cardWidth: CardEntity3D.cardWidth,
        cardHeight: CardEntity3D.cardHeight,
        cardDepth: CardEntity3D.cardDepth,
        curvature: 0.0,
        clampToBounds: true
    )
    #expect(safe.translation.x == transform.translation.x)
    #expect(safe.translation.z == transform.translation.z)
}

@Test @MainActor func clampToBoundsDefaultsToFalse() {
    // Without clampToBounds, card past rail should NOT be clamped
    let transform = Transform(translation: [-0.7, 0.05, 0])
    let safe = CollisionUtils.validateCardTransform(
        transform,
        cardWidth: CardEntity3D.cardWidth,
        cardHeight: CardEntity3D.cardHeight,
        cardDepth: CardEntity3D.cardDepth,
        curvature: 0.0
    )
    #expect(safe.translation.x == transform.translation.x)
}

@Test @MainActor func worstCaseDealSpreadIsClampedInsideRails() {
    let randomSpread: Float = 0.025

    for side in 1...4 {
        for offsetX in [-randomSpread, randomSpread] {
            for offsetZ in [-randomSpread, randomSpread] {
                let base = TableGeometry.cardCenter(for: side)
                let transform = Transform(
                    rotation: TableGeometry.cardRotation(for: side),
                    translation: [base.x + offsetX, base.y, base.z + offsetZ]
                )
                let safe = CollisionUtils.validateCardTransform(
                    transform,
                    cardWidth: CardEntity3D.cardWidth,
                    cardHeight: CardEntity3D.cardHeight,
                    cardDepth: CardEntity3D.cardDepth,
                    curvature: 0.0,
                    clampToBounds: true
                )

                let (c0, c1, c2, c3) = CollisionUtils.cardCornerPositions(
                    transform: safe,
                    cardWidth: CardEntity3D.cardWidth,
                    cardDepth: CardEntity3D.cardDepth
                )
                let minX = min(min(c0.x, c1.x), min(c2.x, c3.x))
                let maxX = max(max(c0.x, c1.x), max(c2.x, c3.x))
                let minZ = min(min(c0.z, c1.z), min(c2.z, c3.z))
                let maxZ = max(max(c0.z, c1.z), max(c2.z, c3.z))

                #expect(minX >= TableGeometry.innerMinX)
                #expect(maxX <= TableGeometry.innerMaxX)
                #expect(minZ >= TableGeometry.innerMinZ)
                #expect(maxZ <= TableGeometry.innerMaxZ)
            }
        }
    }
}
