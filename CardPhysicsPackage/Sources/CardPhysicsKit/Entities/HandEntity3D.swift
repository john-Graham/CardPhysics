import RealityKit
import SwiftUI

/// Factory for creating 3D hand entities to hold cards
internal enum HandEntity3D {

    /// Creates a simple 3D hand model
    /// - Parameters:
    ///   - side: The player side (1-4)
    ///   - position: World position for the hand
    /// - Returns: A ModelEntity representing a hand
    static func makeHand(side: Int, position: SIMD3<Float>) -> ModelEntity {
        // Create a simple hand representation using basic shapes
        // For v1: palm + fingers using boxes/cylinders
        // TODO: Replace with realistic hand model in future iteration

        let handRoot = ModelEntity()
        handRoot.position = position
        handRoot.name = "hand_side_\(side)"

        // Palm dimensions (in meters)
        let palmWidth: Float = 0.09
        let palmLength: Float = 0.11
        let palmThickness: Float = 0.015

        // Create palm
        let palmMesh = MeshResource.generateBox(
            width: palmWidth,
            height: palmThickness,
            depth: palmLength
        )

        // Skin-tone material with subtle texture
        var palmMaterial = PhysicallyBasedMaterial()
        palmMaterial.baseColor = PhysicallyBasedMaterial.BaseColor(
            tint: UIColor(red: 0.95, green: 0.8, blue: 0.7, alpha: 1.0)
        )
        palmMaterial.roughness = 0.6
        palmMaterial.metallic = 0.0

        let palm = ModelEntity(mesh: palmMesh, materials: [palmMaterial])
        palm.name = "palm"
        handRoot.addChild(palm)

        // Create simplified fingers (5 cylinders)
        let fingerRadius: Float = 0.008
        let fingerLength: Float = 0.045

        let fingerPositions: [SIMD3<Float>] = [
            // Thumb (offset to side)
            SIMD3(-palmWidth / 2 - 0.012, 0, -palmLength / 2 + 0.02),
            // Index
            SIMD3(-palmWidth / 3, 0, -palmLength / 2 - fingerLength / 2),
            // Middle (slightly longer)
            SIMD3(0, 0, -palmLength / 2 - fingerLength / 2 - 0.005),
            // Ring
            SIMD3(palmWidth / 3, 0, -palmLength / 2 - fingerLength / 2),
            // Pinky
            SIMD3(palmWidth / 2 - 0.005, 0, -palmLength / 2 - fingerLength / 2 + 0.01)
        ]

        for (index, fingerPos) in fingerPositions.enumerated() {
            let length = index == 2 ? fingerLength + 0.005 : fingerLength // Middle finger slightly longer
            let fingerMesh = MeshResource.generateCylinder(
                height: length,
                radius: fingerRadius
            )

            var fingerMaterial = PhysicallyBasedMaterial()
            fingerMaterial.baseColor = PhysicallyBasedMaterial.BaseColor(
                tint: UIColor(red: 0.92, green: 0.77, blue: 0.67, alpha: 1.0)
            )
            fingerMaterial.roughness = 0.65
            fingerMaterial.metallic = 0.0

            let finger = ModelEntity(mesh: fingerMesh, materials: [fingerMaterial])
            finger.position = fingerPos
            finger.name = "finger_\(index)"

            // Rotate finger to point forward (cylinder default is Y-axis)
            if index == 0 { // Thumb at angle
                finger.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0]) *
                                   simd_quatf(angle: -.pi / 6, axis: [0, 1, 0])
            } else {
                finger.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
            }

            handRoot.addChild(finger)
        }

        // Orient hand based on side
        switch side {
        case 1: // Bottom - hand facing viewer, cards fan upward
            handRoot.orientation = simd_quatf(angle: 0, axis: [0, 1, 0])
        case 2: // Left - hand rotated 90° clockwise
            handRoot.orientation = simd_quatf(angle: .pi / 2, axis: [0, 1, 0])
        case 3: // Top - hand rotated 180°
            handRoot.orientation = simd_quatf(angle: .pi, axis: [0, 1, 0])
        case 4: // Right - hand rotated 90° counter-clockwise
            handRoot.orientation = simd_quatf(angle: -.pi / 2, axis: [0, 1, 0])
        default:
            break
        }

        return handRoot
    }

    /// Calculate the fan arc center position for a given side
    /// - Parameter side: The player side (1-4)
    /// - Returns: Center position of the card fan arc
    static func getFanCenterPosition(side: Int) -> SIMD3<Float> {
        switch side {
        case 1: // Bottom
            return SIMD3(0, 0.05, 0.38)
        case 2: // Left
            return SIMD3(-0.58, 0.05, 0)
        case 3: // Top
            return SIMD3(0, 0.05, -0.38)
        case 4: // Right
            return SIMD3(0.58, 0.05, 0)
        default:
            return SIMD3(0, 0.05, 0)
        }
    }

    /// Calculate hand position below the fan center
    /// - Parameter side: The player side (1-4)
    /// - Returns: Position for the hand entity
    static func getHandPosition(side: Int) -> SIMD3<Float> {
        let fanCenter = getFanCenterPosition(side: side)
        // Position hand slightly below and closer to table
        switch side {
        case 1: // Bottom
            return SIMD3(fanCenter.x, 0.025, fanCenter.z + 0.08)
        case 2: // Left
            return SIMD3(fanCenter.x + 0.08, 0.025, fanCenter.z)
        case 3: // Top
            return SIMD3(fanCenter.x, 0.025, fanCenter.z - 0.08)
        case 4: // Right
            return SIMD3(fanCenter.x - 0.08, 0.025, fanCenter.z)
        default:
            return SIMD3(0, 0.025, 0)
        }
    }
}
