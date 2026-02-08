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
        let mesh: MeshResource
        if curvature > 0 {
            mesh = CurvedCardMesh.mesh(curvature: curvature)
        } else {
            mesh = MeshResource.generateBox(
                width: cardWidth,
                height: cardHeight,
                depth: cardDepth,
                cornerRadius: cornerRadius
            )
        }

        var material = PhysicallyBasedMaterial()
        // Paper isn't purely rough, it has a sheen
        material.roughness = .init(floatLiteral: 0.5)
        material.metallic = .init(floatLiteral: 0.0)
        // Specular highlight for the plastic coating
        material.specular = .init(floatLiteral: 0.4)
        
        // PBR: Clearcoat for the plastic finish on cards
        material.clearcoat = .init(floatLiteral: 0.8)
        material.clearcoatRoughness = .init(floatLiteral: 0.1)

        material.opacityThreshold = 0.5

        let texGen = CardTextureGenerator.shared
        if faceUp, let tex = texGen.texture(for: card) {
            material.baseColor = .init(texture: .init(tex))
        } else if let backTex = texGen.backTexture() {
            material.baseColor = .init(texture: .init(backTex))
        } else {
            // Fallback tint: cream for face, maroon for back
            material.baseColor = .init(
                tint: faceUp
                    ? .init(red: 0.96, green: 0.94, blue: 0.90, alpha: 1.0)
                    : .init(red: 0.55, green: 0.08, blue: 0.10, alpha: 1.0)
            )
        }

        let entity = ModelEntity(mesh: mesh, materials: [material])
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
                staticFriction: 0.25,  // Reduced to help cards slide on each other
                dynamicFriction: 0.2,  // Reduced to help cards slide on each other
                restitution: 0.05  // Very low bounce for better stacking
            ),
            mode: .kinematic  // Start in kinematic mode for scripted animations
        )

        // Enable CCD (Continuous Collision Detection) to prevent thin cards from tunneling
        physicsBody.isContinuousCollisionDetectionEnabled = true

        // Set minimal damping to help cards settle when stacking
        physicsBody.linearDamping = 0.1  // Very slight linear damping
        physicsBody.angularDamping = 0.3  // Light angular damping to help cards settle flat

        entity.components.set(physicsBody)

        if enableTap {
            entity.components.set(InputTargetComponent())
        }

        return entity
    }
}