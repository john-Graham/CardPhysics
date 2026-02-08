import SwiftUI
import RealityKit

@MainActor
public struct CardPhysicsScene: View {
    @State private var rootEntity = Entity()
    @State private var cards: [Entity] = []
    @State private var deckPosition = Entity()

    public let settings: PhysicsSettings
    public let cameraPosition: SIMD3<Float>
    public let cameraTarget: SIMD3<Float>
    let coordinator: SceneCoordinator?

    public init(settings: PhysicsSettings, cameraPosition: SIMD3<Float> = [0, 0.55, 0.41], cameraTarget: SIMD3<Float> = [0, 0, 0], coordinator: SceneCoordinator? = nil) {
        self.settings = settings
        self.cameraPosition = cameraPosition
        self.cameraTarget = cameraTarget
        self.coordinator = coordinator
    }

    public var body: some View {
        RealityView { content in
            // Set up the root entity
            content.add(rootEntity)

            // Configure physics simulation with gravity
            var physicsSimulation = PhysicsSimulationComponent()
            physicsSimulation.gravity = [0, -9.8, 0]  // Standard Earth gravity
            rootEntity.components.set(physicsSimulation)

            // Create camera with seated view angle
            createCamera()

            // Create table
            createTable()

            // Set up lighting with HDRI
            setupLighting()

            // Create initial deck of cards
            createDeck()

            // Set up coordinator actions
            coordinator?.dealCardsAction = { [self] in
                await self.dealCards()
            }
            coordinator?.pickUpCardAction = { [self] index in
                await self.pickUpCard(index: index)
            }
            coordinator?.resetCardsAction = { [self] in
                self.resetCards()
            }
        } update: { content in
            // Update camera position when parameters change
            if let cameraEntity = rootEntity.findEntity(named: "camera") {
                cameraEntity.position = cameraPosition
                cameraEntity.look(at: cameraTarget, from: cameraPosition, relativeTo: nil)
            }
        }
        .task {
            // Preload card textures
            _ = CardTextureGenerator.shared
        }
    }

    // MARK: - Scene Setup

    private func createCamera() {
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

    private func createTable() {
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

        // Wood Albedo (Warm Mahogany)
        if let woodImg = texGen.woodAlbedo(),
           let woodTex = texGen.colorTexture(from: woodImg) {
            woodMaterial.baseColor = .init(texture: .init(woodTex))
        } else {
            woodMaterial.baseColor = .init(tint: .init(red: 0.4, green: 0.15, blue: 0.05, alpha: 1.0))
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

        // Felt Albedo (Rich Green)
        if let feltImg = texGen.feltAlbedo(),
           let feltTex = texGen.colorTexture(from: feltImg) {
            feltMaterial.baseColor = .init(texture: .init(feltTex))
        } else {
            feltMaterial.baseColor = .init(tint: .init(red: 0.02, green: 0.18, blue: 0.06, alpha: 1.0))
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

        // Set deck position marker near position 1 (bottom of table, closest to viewer)
        // Position at z=0.41 - confirmed correct viewing position
        deckPosition.position = SIMD3<Float>(0.0, 0.0052, 0.41)
        rootEntity.addChild(deckPosition)
    }

    private func addRailPhysics(to rail: ModelEntity, width: Float, height: Float, depth: Float) {
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

    private func addDebugLabels(to tableRoot: Entity, tableWidth: Float, tableDepth: Float) {
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

    private func createTextLabel(_ text: String, size: Float) -> ModelEntity? {
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

    private func setupLighting() {
        // Try to load HDRI environment
        do {
            let environment = try EnvironmentResource.load(named: "room_bg", in: Bundle.module)
            rootEntity.components.set(ImageBasedLightComponent(source: .single(environment)))
            rootEntity.components.set(ImageBasedLightReceiverComponent(imageBasedLight: rootEntity))
        } catch {
            print("⚠️ Failed to load HDRI: \(error). Using fallback lighting.")
            setupFallbackLighting()
        }
    }

    private func setupFallbackLighting() {
        // Main Studio Light: Soft overhead spot (simulating a large softbox)
        let mainLight = Entity()
        let mainComponent = SpotLightComponent(
            color: .init(red: 1.0, green: 0.92, blue: 0.82, alpha: 1.0),
            intensity: 400,
            innerAngleInDegrees: 60,
            outerAngleInDegrees: 140,
            attenuationRadius: 9.0
        )
        mainLight.components.set(mainComponent)
        mainLight.position = [0.2, 1.8, 0.5]
        mainLight.look(at: [0, 0, 0], from: mainLight.position, relativeTo: nil)
        mainLight.name = "mainStudioLight"
        rootEntity.addChild(mainLight)

        // Fill Light: Cooler, subtle fill from the left/front
        let fillLight = Entity()
        fillLight.components.set(
            PointLightComponent(
                color: .init(red: 0.85, green: 0.9, blue: 1.0, alpha: 1.0),
                intensity: 150,
                attenuationRadius: 6.0
            )
        )
        fillLight.position = [-1.0, 0.8, 0.8]
        fillLight.name = "fillLight"
        rootEntity.addChild(fillLight)

        // Rim Light: Back/Rim light to separate cards from table
        let rimLight = Entity()
        let rimComponent = SpotLightComponent(
            color: .init(red: 1.0, green: 0.93, blue: 0.78, alpha: 1.0),
            intensity: 300,
            innerAngleInDegrees: 30,
            outerAngleInDegrees: 90,
            attenuationRadius: 5.0
        )
        rimLight.components.set(rimComponent)
        rimLight.position = [0, 0.8, -1.2]
        rimLight.look(at: [0, 0, 0], from: rimLight.position, relativeTo: nil)
        rimLight.name = "rimLight"
        rootEntity.addChild(rimLight)
    }

    private func createDeck() {
        // Create 12 cards for dealing (3 rounds to each of 4 sides)
        let sampleCards: [Card] = [
            Card(suit: .hearts, rank: .ace),
            Card(suit: .spades, rank: .king),
            Card(suit: .diamonds, rank: .queen),
            Card(suit: .clubs, rank: .jack),
            Card(suit: .hearts, rank: .ten),
            Card(suit: .spades, rank: .nine),
            Card(suit: .diamonds, rank: .king),
            Card(suit: .clubs, rank: .ace),
            Card(suit: .hearts, rank: .queen),
            Card(suit: .spades, rank: .jack),
            Card(suit: .diamonds, rank: .ten),
            Card(suit: .clubs, rank: .nine)
        ]

        for (index, card) in sampleCards.enumerated() {
            let cardEntity = CardEntity3D.makeCard(
                card,
                faceUp: false,  // Start face down, will flip during deal animation
                enableTap: false,
                curvature: 0.0  // Flat cards when dealing (no curve)
            )

            // Start cards at deck position, floating visibly above table
            // Table surface is at y=0.005, float cards higher for visibility
            let stackOffset: Float = 0.0015  // Thinner spacing (1.5mm between cards)
            let deckThickness: Float = Float(sampleCards.count - 1) * stackOffset  // Total deck thickness
            let baseHeight: Float = max(0.015, deckThickness * 5.0)  // At least 5x deck thickness
            cardEntity.position = SIMD3<Float>(
                deckPosition.position.x,
                baseHeight + Float(index) * stackOffset,
                deckPosition.position.z
            )

            rootEntity.addChild(cardEntity)
            cards.append(cardEntity)
        }
    }

    // MARK: - Animation Methods (to be called from parent view)

    public func dealCards() async {
        // Deal cards from top of deck (highest index) to bottom, tossing them toward sides 2, 3, 4 (left, top, right)
        for (dealIndex, cardIndex) in cards.indices.reversed().enumerated() {
            let card = cards[cardIndex]
            await dealCard(card, index: dealIndex, delay: Double(dealIndex) * 0.3)
        }
    }

    private func dealCard(_ card: Entity, index: Int, delay: Double) async {
        try? await Task.sleep(for: .seconds(delay))

        // Flip the card face-up first with rotation
        card.orientation = simd_quatf(angle: .pi, axis: [1, 0, 0])

        // Switch to dynamic mode so cards can interact with physics
        if var physicsBody = card.components[PhysicsBodyComponent.self] {
            physicsBody.mode = .dynamic
            card.components[PhysicsBodyComponent.self] = physicsBody
        }

        // Determine target side: cycle through 2 (left), 3 (top), 4 (right), 1 (bottom)
        // Pattern: 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1
        let sidePattern = [2, 3, 4, 1]
        let sideIndex = sidePattern[index % 4]

        // Deck is at position 1 (bottom, z=0.41)
        // Side 2 (left): medium distance (~0.7m left + 0.4m forward)
        // Side 3 (top): farthest distance (~0.8m forward)
        // Side 4 (right): medium distance (~0.7m right + 0.4m forward)
        // Side 1 (bottom): very close, just drop straight down

        // Target the CENTER of each side - cards will stack on the same spot
        let targetX: Float
        let targetZ: Float

        // Add very small random variation to encourage stacking/sliding
        let randomX = Float.random(in: -0.015...0.015)  // Reduced from 0.03
        let randomZ = Float.random(in: -0.015...0.015)  // Reduced from 0.03

        switch sideIndex {
        case 1: // Bottom side (closest to viewer) - near deck, just drop
            targetX = 0.0 + randomX
            targetZ = 0.35 + randomZ  // Very close to deck
        case 2: // Left side - medium distance
            targetX = -0.55 + randomX  // Left edge
            targetZ = 0.0 + randomZ  // Center vertically
        case 3: // Top side (far from viewer) - farthest distance
            targetX = 0.0 + randomX  // Center horizontally
            targetZ = -0.35 + randomZ  // Top edge (farthest)
        case 4: // Right side - medium distance
            targetX = 0.55 + randomX  // Right edge
            targetZ = 0.0 + randomZ  // Center vertically
        default:
            targetX = 0
            targetZ = 0
        }

        // Calculate toss velocity based on distance to target
        let startPos = card.position
        let targetPos = SIMD3<Float>(targetX, 0.008, targetZ)
        let horizontalDirection = SIMD3<Float>(
            targetPos.x - startPos.x,
            0,
            targetPos.z - startPos.z
        )
        let horizontalDistance = length(horizontalDirection)

        // Adjust speed based on target side
        let horizontalSpeed: Float
        let upwardVelocity: Float
        let spinIntensity: Float

        switch sideIndex {
        case 1: // Bottom - minimal slide off deck
            horizontalSpeed = 0.4  // Gentle push (minimal slide)
            upwardVelocity = 0.15  // Low arc, mostly slide
            spinIntensity = 0.5    // Less spin
        case 2: // Left - medium distance, moderate throw
            horizontalSpeed = 1.1  // Moderate-strong speed
            upwardVelocity = 0.4   // Medium arc
            spinIntensity = 1.0    // Moderate spin
        case 3: // Top - farthest, needs most speed
            horizontalSpeed = 1.4  // Strongest throw
            upwardVelocity = 0.5   // High arc
            spinIntensity = 1.5    // More spin
        case 4: // Right - same as left (medium distance)
            horizontalSpeed = 1.1  // Same as side 2
            upwardVelocity = 0.4   // Medium arc
            spinIntensity = 1.0    // Moderate spin
        default:
            horizontalSpeed = 0.0
            upwardVelocity = 0.0
            spinIntensity = 0.0
        }

        let horizontalVelocity = horizontalDistance > 0
            ? normalize(horizontalDirection) * horizontalSpeed
            : SIMD3<Float>(0, 0, 0)

        // Set initial velocity using PhysicsMotionComponent
        var motion = PhysicsMotionComponent()
        motion.linearVelocity = SIMD3<Float>(
            horizontalVelocity.x,
            upwardVelocity,
            horizontalVelocity.z
        )

        // Add rotation during flight - scaled by spin intensity
        let ySpinAmount: Float = Float.random(in: 1.5...2.5) * spinIntensity
        let xTumbleAmount: Float = Float.random(in: -0.5...0.5) * spinIntensity
        let zTumbleAmount: Float = Float.random(in: -0.5...0.5) * spinIntensity

        // Determine spin direction based on target side
        let spinDirection: Float = (sideIndex == 2 || sideIndex == 1) ? -1.0 : 1.0

        motion.angularVelocity = [
            xTumbleAmount,
            ySpinAmount * spinDirection,
            zTumbleAmount
        ]

        card.components[PhysicsMotionComponent.self] = motion
    }

    public func pickUpCard(index: Int) async {
        guard index < cards.count else { return }
        let card = cards[index]

        // Move card up slightly
        var newPos = card.position
        newPos.y += 0.05

        await withCheckedContinuation { continuation in
            card.move(
                to: Transform(
                    scale: card.scale,
                    rotation: card.orientation,
                    translation: newPos
                ),
                relativeTo: nil,
                duration: settings.pickUpDuration,
                timingFunction: .easeOut
            )
            continuation.resume()
        }
    }

    public func resetCards() {
        // Remove all cards and recreate deck
        for card in cards {
            card.removeFromParent()
        }
        cards.removeAll()
        createDeck()
    }
}
