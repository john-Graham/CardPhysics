import RealityKit
import SwiftUI

@MainActor
enum CardEntity3D {
    // Enlarged playing card proportions in meters (2x standard ~126mm x 176mm)
    static let cardWidth: Float = 0.126
    // Reduced thickness to 0.4mm (approx real card stock)
    static let cardHeight: Float = 0.0004
    static let cardDepth: Float = 0.176
    // Tighter corners for more realistic cut
    static let cornerRadius: Float = 0.002

    static func makeCard(
        _ card: Card,
        faceUp: Bool,
        enableTap: Bool = false,
        curvature: Float = 0.0
    ) -> ModelEntity {
        // Always use CurvedCardMesh — at curvature 0 it produces a flat mesh
        let mesh = CurvedCardMesh.mesh(curvature: curvature)

        // Shared PBR properties for both materials
        func makeBaseMaterial() -> PhysicallyBasedMaterial {
            var material = PhysicallyBasedMaterial()
            material.roughness = .init(floatLiteral: 0.5)
            material.metallic = .init(floatLiteral: 0.0)
            material.specular = .init(floatLiteral: 0.4)
            material.clearcoat = .init(floatLiteral: 0.8)
            material.clearcoatRoughness = .init(floatLiteral: 0.1)
            material.opacityThreshold = 0.5
            return material
        }

        let texGen = CardTextureGenerator.shared

        // Material 0 → descriptor 0 = card FACE (mesh front)
        var faceMaterial = makeBaseMaterial()
        if let faceTex = texGen.texture(for: card) {
            faceMaterial.baseColor = .init(texture: .init(faceTex))
        } else {
            faceMaterial.baseColor = .init(
                tint: .init(red: 0.96, green: 0.94, blue: 0.90, alpha: 1.0)
            )
        }

        // Material 1 → descriptor 1 = card BACK (mesh back + edges)
        var backMaterial = makeBaseMaterial()
        // Temporarily use bright blue to verify back side is visible
        backMaterial.baseColor = .init(tint: .init(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0))

        let entity = ModelEntity(mesh: mesh, materials: [faceMaterial, backMaterial])
        entity.name = "card_\(card.suit.name)_\(card.rank.name)"

        // Always add collision component for cards
        let shape = ShapeResource.generateBox(
            width: cardWidth,
            height: cardHeight,
            depth: cardDepth
        )
        entity.components.set(CollisionComponent(shapes: [shape]))

        // Add physics body component for realistic card physics
        var physicsBody = PhysicsBodyComponent(
            massProperties: .default,
            material: .generate(
                staticFriction: 0.25,
                dynamicFriction: 0.2,
                restitution: 0.05
            ),
            mode: .kinematic
        )

        physicsBody.isContinuousCollisionDetectionEnabled = true
        physicsBody.linearDamping = 0.1
        physicsBody.angularDamping = 0.3

        entity.components.set(physicsBody)

        if enableTap {
            entity.components.set(InputTargetComponent())
        }

        return entity
    }
}
