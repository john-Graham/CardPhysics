import RealityKit
import SwiftUI

@MainActor
enum CardEntity3D {
    // Enlarged playing card proportions in meters (2x standard ~126mm x 176mm)
    static let cardWidth: Float = 0.126
    // Visible edge thickness: 2mm (exaggerated from realistic 0.4mm for better visibility)
    static let cardHeight: Float = 0.002
    static let cardDepth: Float = 0.176
    // Corner radius for rounded 3D corners (will be used in mesh generation)
    static let cornerRadius: Float = 0.002

    static func makeCard(
        _ card: Card,
        faceUp: Bool,
        enableTap: Bool = false,
        curvature: Float = 0.0,
        enableShadows: Bool = false
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
            material.blending = .transparent(opacity: .init(floatLiteral: 1.0))
            return material
        }

        let texGen = CardTextureGenerator.shared

        // Material 0 → descriptor 0 = +Y surface (visible when card is face-down)
        var backMaterial = makeBaseMaterial()
        if let backTex = texGen.backTexture() {
            backMaterial.baseColor = .init(texture: .init(backTex))
        } else {
            backMaterial.baseColor = .init(
                tint: .init(red: 0.55, green: 0.08, blue: 0.10, alpha: 1.0)
            )
        }

        // Material 1 → descriptor 1 = -Y surface (visible when card is face-up)
        var faceMaterial = makeBaseMaterial()
        if let faceTex = texGen.texture(for: card) {
            faceMaterial.baseColor = .init(texture: .init(faceTex))
        } else {
            faceMaterial.baseColor = .init(
                tint: .init(red: 0.96, green: 0.94, blue: 0.90, alpha: 1.0)
            )
        }

        let entity = ModelEntity(mesh: mesh, materials: [backMaterial, faceMaterial])
        entity.name = "card_\(card.suit.name)_\(card.rank.name)"

        // Always add collision component for cards
        // Collision height accounts for card thickness plus curvature displacement
        let collisionHeight = cardHeight + (abs(curvature) * 2.0)
        let shape = ShapeResource.generateBox(
            width: cardWidth,
            height: collisionHeight,
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

        if enableShadows {
            entity.components.set(GroundingShadowComponent(castsShadow: true))
        }

        return entity
    }
}
