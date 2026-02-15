import RealityKit
import SwiftUI

extension CardPhysicsScene {
internal func createCamera() {
    let cameraEntity = Entity()
    // First-person seated POV, zoomed out to see full table
    cameraEntity.components.set(
        PerspectiveCameraComponent(near: 0.005, far: 25.0, fieldOfViewInDegrees: 72)
    )
    // Use provided camera position and target
    cameraEntity.position = cameraPosition
    cameraEntity.look(at: cameraTarget, from: cameraPosition, relativeTo: nil)
    cameraEntity.name = "camera"
    rootEntity.addChild(cameraEntity)
}

internal func createTable() {
    let tableRoot = Entity()
    tableRoot.name = "table"
    let texGen = ProceduralTextureGenerator.self

    // --- 1. The Main Wood Board (Base) ---
    // Rectangular table (wider than deep) matching Euchre render
    let tableWidth: Float = 1.4
    let tableDepth: Float = 1.0

    let baseMesh = MeshResource.generateBox(
        width: tableWidth,
        height: 0.04,
        depth: tableDepth,
        cornerRadius: 0.01
    )

    var woodMaterial = PhysicallyBasedMaterial()

    // Wood Albedo -- use theme color
    let woodRGB = settings.tableTheme.effectiveWoodRGB
    if let woodImg = texGen.woodAlbedo(baseR: woodRGB.r, baseG: woodRGB.g, baseB: woodRGB.b),
       let woodTex = texGen.colorTexture(from: woodImg) {
        woodMaterial.baseColor = .init(texture: .init(woodTex))
    } else {
        woodMaterial.baseColor = .init(tint: .init(red: CGFloat(woodRGB.r), green: CGFloat(woodRGB.g), blue: CGFloat(woodRGB.b), alpha: 1.0))
    }

    // Wood Roughness (Underlying grain texture)
    if let roughImg = texGen.woodRoughness(),
       let roughTex = texGen.dataTexture(from: roughImg) {
        woodMaterial.roughness = .init(texture: .init(roughTex))
    } else {
        woodMaterial.roughness = .init(floatLiteral: 0.6)
    }

    // Wood Normal (Grain depth)
    if let normImg = texGen.woodNormal(),
       let normTex = texGen.normalTexture(from: normImg) {
        woodMaterial.normal = .init(texture: .init(normTex))
    }

    // PBR: Clearcoat (The Varnish)
    // Adds a shiny layer on top of the wood grain
    woodMaterial.clearcoat = .init(floatLiteral: 1.0)
    woodMaterial.clearcoatRoughness = .init(floatLiteral: 0.02) // High gloss polished varnish
    woodMaterial.specular = .init(floatLiteral: 0.5)

    let base = ModelEntity(mesh: baseMesh, materials: [woodMaterial])
    base.position = [0, -0.02, 0]
    base.name = "woodBase"
    tableRoot.addChild(base)

    // --- 2. The Raised Lip/Frame (Edge) ---
    // Thicker rails for a more substantial furniture look

    let railThickness: Float = 0.07
    let railHeight: Float = 0.035

    // Top/Bottom Rails with collision
    let hRailMesh = MeshResource.generateBox(width: tableWidth, height: railHeight, depth: railThickness, cornerRadius: 0.005)
    let topRail = ModelEntity(mesh: hRailMesh, materials: [woodMaterial])
    topRail.position = [0, 0.015, -tableDepth/2 + railThickness/2]
    addRailPhysics(to: topRail, width: tableWidth, height: railHeight, depth: railThickness)
    tableRoot.addChild(topRail)

    let bottomRail = ModelEntity(mesh: hRailMesh, materials: [woodMaterial])
    bottomRail.position = [0, 0.015, tableDepth/2 - railThickness/2]
    addRailPhysics(to: bottomRail, width: tableWidth, height: railHeight, depth: railThickness)
    tableRoot.addChild(bottomRail)

    // Left/Right Rails with collision
    let vRailMesh = MeshResource.generateBox(width: railThickness, height: railHeight, depth: tableDepth - 2*railThickness, cornerRadius: 0.005)
    let leftRail = ModelEntity(mesh: vRailMesh, materials: [woodMaterial])
    leftRail.position = [-tableWidth/2 + railThickness/2, 0.015, 0]
    addRailPhysics(to: leftRail, width: railThickness, height: railHeight, depth: tableDepth - 2*railThickness)
    tableRoot.addChild(leftRail)

    let rightRail = ModelEntity(mesh: vRailMesh, materials: [woodMaterial])
    rightRail.position = [tableWidth/2 - railThickness/2, 0.015, 0]
    addRailPhysics(to: rightRail, width: railThickness, height: railHeight, depth: tableDepth - 2*railThickness)
    tableRoot.addChild(rightRail)

    // --- 3. The Felt Surface ---
    let feltMesh = MeshResource.generateBox(
        width: tableWidth - railThickness * 2,
        height: 0.005,
        depth: tableDepth - railThickness * 2,
        cornerRadius: 0.0
    )

    var feltMaterial = PhysicallyBasedMaterial()

    // Felt Albedo -- use theme color
    let feltRGB = settings.tableTheme.effectiveFeltRGB
    if let feltImg = texGen.feltAlbedo(baseR: feltRGB.r, baseG: feltRGB.g, baseB: feltRGB.b),
       let feltTex = texGen.colorTexture(from: feltImg) {
        feltMaterial.baseColor = .init(texture: .init(feltTex))
    } else {
        feltMaterial.baseColor = .init(tint: .init(red: CGFloat(feltRGB.r), green: CGFloat(feltRGB.g), blue: CGFloat(feltRGB.b), alpha: 1.0))
    }

    // Felt Roughness (Matte)
    if let feltRoughImg = texGen.feltRoughness(),
       let feltRoughTex = texGen.dataTexture(from: feltRoughImg) {
        feltMaterial.roughness = .init(texture: .init(feltRoughTex))
    } else {
        feltMaterial.roughness = .init(floatLiteral: 0.95)
    }

    // Felt Normal (Fiber bumps)
    if let feltNormImg = texGen.feltNormal(),
       let feltNormTex = texGen.normalTexture(from: feltNormImg) {
        feltMaterial.normal = .init(texture: .init(feltNormTex))
    }

    feltMaterial.metallic = .init(floatLiteral: 0.0)

    let felt = ModelEntity(mesh: feltMesh, materials: [feltMaterial])
    felt.position = [0, 0.0025, 0]
    felt.name = "feltSurface"

    // Add grounding shadow component so felt receives card shadows
    if settings.enableCardShadows {
        felt.components.set(GroundingShadowComponent(castsShadow: true))
    }

    // Add physics to the felt surface so cards can collide with it
    let feltShape = ShapeResource.generateBox(
        width: tableWidth - railThickness * 2,
        height: 0.005,
        depth: tableDepth - railThickness * 2
    )
    felt.components.set(CollisionComponent(shapes: [feltShape]))

    // Make table static (infinite mass, doesn't move)
    felt.components.set(PhysicsBodyComponent(
        massProperties: .default,
        material: .generate(
            staticFriction: 0.5,
            dynamicFriction: 0.4,
            restitution: 0.1
        ),
        mode: .static
    ))

    tableRoot.addChild(felt)

    rootEntity.addChild(tableRoot)

    // DEBUG: Add position labels to each side of the table
    addDebugLabels(to: tableRoot, tableWidth: tableWidth, tableDepth: tableDepth)

    // Set deck position marker past the bottom rail, closest to viewer
    deckPosition.position = SIMD3<Float>(0.0, 0.0052, 0.55)
    rootEntity.addChild(deckPosition)
}

internal func addRailPhysics(to rail: ModelEntity, width: Float, height: Float, depth: Float) {
    // Add collision to rails so cards can bounce off them
    let shape = ShapeResource.generateBox(width: width, height: height, depth: depth)
    rail.components.set(CollisionComponent(shapes: [shape]))

    // Make rails static with wood material properties
    rail.components.set(PhysicsBodyComponent(
        massProperties: .default,
        material: .generate(
            staticFriction: 0.3,
            dynamicFriction: 0.25,
            restitution: 0.4  // Some bounce off wood
        ),
        mode: .static
    ))
}

internal func addDebugLabels(to tableRoot: Entity, tableWidth: Float, tableDepth: Float) {
    let labelHeight: Float = 0.035  // Above the rail
    let labelSize: Float = 0.08

    // Position 1: Bottom (closest to viewer, +Z direction)
    if let label1 = createTextLabel("1", size: labelSize) {
        label1.position = [0, labelHeight, tableDepth/2]
        label1.orientation = simd_quatf(angle: -.pi/2, axis: [1, 0, 0]) // Lay flat
        tableRoot.addChild(label1)
    }

    // Position 2: Left (-X direction)
    if let label2 = createTextLabel("2", size: labelSize) {
        label2.position = [-tableWidth/2, labelHeight, 0]
        label2.orientation = simd_quatf(angle: -.pi/2, axis: [1, 0, 0]) // Lay flat
        tableRoot.addChild(label2)
    }

    // Position 3: Top (farthest from viewer, -Z direction)
    if let label3 = createTextLabel("3", size: labelSize) {
        label3.position = [0, labelHeight, -tableDepth/2]
        label3.orientation = simd_quatf(angle: -.pi/2, axis: [1, 0, 0]) // Lay flat
        tableRoot.addChild(label3)
    }

    // Position 4: Right (+X direction)
    if let label4 = createTextLabel("4", size: labelSize) {
        label4.position = [tableWidth/2, labelHeight, 0]
        label4.orientation = simd_quatf(angle: -.pi/2, axis: [1, 0, 0]) // Lay flat
        tableRoot.addChild(label4)
    }
}

internal func createTextLabel(_ text: String, size: Float) -> ModelEntity? {
    let mesh = MeshResource.generateText(
        text,
        extrusionDepth: 0.005,
        font: .systemFont(ofSize: CGFloat(size)),
        containerFrame: .zero,
        alignment: .center,
        lineBreakMode: .byWordWrapping
    )

    var material = UnlitMaterial()
    material.color = .init(tint: .white)

    let entity = ModelEntity(mesh: mesh, materials: [material])
    return entity
}


internal func createDeck(count: Int = 12) {
    // Build a pool of cards by cycling through the full Euchre deck
    let allCards: [Card] = Suit.allCases.flatMap { suit in
        Rank.allCases.map { rank in Card(suit: suit, rank: rank) }
    }
    var sampleCards: [Card] = []
    for i in 0..<count {
        let template = allCards[i % allCards.count]
        sampleCards.append(Card(suit: template.suit, rank: template.rank))
    }

    for (index, card) in sampleCards.enumerated() {
        let tapEnabled = settings.enableCardTapGesture
        let cardEntity = CardEntity3D.makeCard(
            card,
            faceUp: false,
            enableTap: tapEnabled,
            curvature: 0.0,
            enableShadows: settings.enableCardShadows
        )

        // When tap gesture is enabled, add GestureComponent for tap-to-flip
        if tapEnabled {
            let tapGesture = TapGesture().onEnded { _ in
                flipCard(cardEntity)
            }
            cardEntity.components.set(GestureComponent(tapGesture))
        }

        let stackOffset: Float = 0.0015
        let deckThickness: Float = Float(sampleCards.count - 1) * stackOffset
        let baseHeight: Float = max(0.015, deckThickness * 5.0)
        cardEntity.position = SIMD3<Float>(
            deckPosition.position.x,
            baseHeight + Float(index) * stackOffset,
            deckPosition.position.z
        )

        rootEntity.addChild(cardEntity)
        cards.append(cardEntity)

        // Track card data and wear component for wear system
        let entityId = ObjectIdentifier(cardEntity)
        cardDataMap[entityId] = card
        if settings.enableCardWear {
            cardWearComponents[entityId] = CardWearComponent()
        }
    }
}

// MARK: - Card Wear

/// Handles collision events between entities, incrementing wear on card entities.
}
