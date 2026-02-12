import SwiftUI
import RealityKit

@MainActor
public struct CardPhysicsScene: View {
    @State private var rootEntity = Entity()
    @State private var cards: [Entity] = []
    @State private var cardSideAssignments: [ObjectIdentifier: Int] = [:]
    @State private var deckPosition = Entity()
    @State private var lastRoomEnvironment: RoomEnvironment = .none
    @State private var lastCustomRoomImageFilename: String = ""
    @State private var lastRoomRotation: Double = 0.0

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

            // Create skybox if room environment is enabled
            if settings.roomEnvironment != .none {
                if let skybox = SkyboxEntity.makeSkybox(
                    environment: settings.roomEnvironment,
                    customImageFilename: settings.customRoomImageFilename,
                    rotation: settings.roomRotation
                ) {
                    skybox.name = "skybox"
                    rootEntity.addChild(skybox)
                }
            }

            // Create initial deck of cards
            createDeck()

            // Set up coordinator actions
            coordinator?.dealCardsAction = { [self] mode in
                await self.dealCards(mode: mode)
            }
            coordinator?.pickUpCardAction = { [self] corner in
                await self.gatherAndPickUp(corner: corner)
            }
            coordinator?.fanInHandsAction = { [self] in
                await self.fanCardsInHands()
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

            // Update skybox if room settings changed
            if settings.roomEnvironment != lastRoomEnvironment ||
               settings.customRoomImageFilename != lastCustomRoomImageFilename ||
               settings.roomRotation != lastRoomRotation {
                updateSkybox()
                lastRoomEnvironment = settings.roomEnvironment
                lastCustomRoomImageFilename = settings.customRoomImageFilename
                lastRoomRotation = settings.roomRotation
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

        // Set deck position marker past the bottom rail, closest to viewer
        deckPosition.position = SIMD3<Float>(0.0, 0.0052, 0.55)
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

    private func updateSkybox() {
        // Remove existing skybox
        if let existingSkybox = rootEntity.findEntity(named: "skybox") {
            existingSkybox.removeFromParent()
        }

        // Create and add new skybox if environment is not .none
        if settings.roomEnvironment != .none {
            if let skybox = SkyboxEntity.makeSkybox(
                environment: settings.roomEnvironment,
                customImageFilename: settings.customRoomImageFilename,
                rotation: settings.roomRotation
            ) {
                skybox.name = "skybox"
                rootEntity.addChild(skybox)
            }
        }
    }

    private func createDeck(count: Int = 12) {
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
                curvature: 0.0
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
        }
    }

    // MARK: - Animation Methods (to be called from parent view)

    public func dealCards(mode: DealMode) async {
        // Remove existing cards and create correct count for this mode
        for card in cards { card.removeFromParent() }
        cards.removeAll()
        cardSideAssignments.removeAll()
        createDeck(count: mode.cardCount)

        switch mode {
        case .euchre:
            await dealCardsEuchre()
        case .four, .twelve, .twenty:
            await dealCardsStandard()
        }

        // Wait for physics to settle, then stack cards neatly
        try? await Task.sleep(for: .seconds(2.0))
        await stackCardsBySide()
    }

    private func dealCardsStandard() async {
        // Deal cards one at a time, cycling through sides 2, 3, 4, 1
        for (dealIndex, cardIndex) in cards.indices.reversed().enumerated() {
            let card = cards[cardIndex]
            await dealSingleCard(card, toSide: [2, 3, 4, 1][dealIndex % 4], delay: dealIndex == 0 ? 0.0 : 0.3)
        }
    }

    private func dealCardsEuchre() async {
        // Euchre dealing: 2 rounds, alternating bundles of 2 and 3
        // Round 1: 2 to side 2, 3 to side 3, 2 to side 4, 3 to side 1 (10 cards)
        // Round 2: 3 to side 2, 2 to side 3, 3 to side 4, 2 to side 1 (10 cards)
        let bundles: [(count: Int, side: Int)] = [
            // Round 1
            (2, 2), (3, 3), (2, 4), (3, 1),
            // Round 2
            (3, 2), (2, 3), (3, 4), (2, 1)
        ]

        var cardPointer = cards.count - 1  // Start from top of deck
        for bundle in bundles {
            guard cardPointer >= 0 else { break }
            let bundleCards = (0..<bundle.count).compactMap { offset -> Entity? in
                let idx = cardPointer - offset
                guard idx >= 0 else { return nil }
                return cards[idx]
            }
            cardPointer -= bundle.count

            // Throw all cards in the bundle nearly simultaneously with tight clustering
            for (offsetInBundle, card) in bundleCards.enumerated() {
                await dealSingleCard(
                    card,
                    toSide: bundle.side,
                    delay: offsetInBundle == 0 ? 0.0 : 0.05,
                    randomSpread: 0.025
                )
            }

            // Pause between bundles
            try? await Task.sleep(for: .seconds(0.3))
        }
    }

    private func dealSingleCard(_ card: Entity, toSide sideIndex: Int, delay: Double, randomSpread: Float = 0.015) async {
        try? await Task.sleep(for: .seconds(delay))

        // Flip the card face-up
        card.orientation = simd_quatf(angle: .pi, axis: [1, 0, 0])

        // Switch to dynamic mode so cards can interact with physics
        if var physicsBody = card.components[PhysicsBodyComponent.self] {
            physicsBody.mode = .dynamic
            card.components[PhysicsBodyComponent.self] = physicsBody
        }

        let randomX = Float.random(in: -randomSpread...randomSpread)
        let randomZ = Float.random(in: -randomSpread...randomSpread)

        let targetX: Float
        let targetZ: Float

        switch sideIndex {
        case 1:
            targetX = 0.0 + randomX
            targetZ = 0.35 + randomZ
        case 2:
            targetX = -0.55 + randomX
            targetZ = 0.0 + randomZ
        case 3:
            targetX = 0.0 + randomX
            targetZ = -0.35 + randomZ
        case 4:
            targetX = 0.55 + randomX
            targetZ = 0.0 + randomZ
        default:
            targetX = 0
            targetZ = 0
        }

        let startPos = card.position
        let targetPos = SIMD3<Float>(targetX, 0.008, targetZ)
        let horizontalDirection = SIMD3<Float>(
            targetPos.x - startPos.x,
            0,
            targetPos.z - startPos.z
        )
        let horizontalDistance = length(horizontalDirection)

        let horizontalSpeed: Float
        let upwardVelocity: Float
        let spinIntensity: Float

        switch sideIndex {
        case 1:
            horizontalSpeed = 0.5
            upwardVelocity = 0.0
            spinIntensity = 0.5
        case 2:
            horizontalSpeed = 1.1
            upwardVelocity = 0.4
            spinIntensity = 1.0
        case 3:
            horizontalSpeed = 1.4
            upwardVelocity = 0.35
            spinIntensity = 0.8
        case 4:
            horizontalSpeed = 1.1
            upwardVelocity = 0.4
            spinIntensity = 1.0
        default:
            horizontalSpeed = 0.0
            upwardVelocity = 0.0
            spinIntensity = 0.0
        }

        let horizontalVelocity = horizontalDistance > 0
            ? normalize(horizontalDirection) * horizontalSpeed
            : SIMD3<Float>(0, 0, 0)

        var motion = PhysicsMotionComponent()
        motion.linearVelocity = SIMD3<Float>(
            horizontalVelocity.x,
            upwardVelocity,
            horizontalVelocity.z
        )

        let ySpinAmount: Float = Float.random(in: 1.5...2.5) * spinIntensity
        let xTumbleAmount: Float = Float.random(in: -0.5...0.5) * spinIntensity
        let zTumbleAmount: Float = Float.random(in: -0.5...0.5) * spinIntensity
        let spinDirection: Float = (sideIndex == 2 || sideIndex == 1) ? -1.0 : 1.0

        motion.angularVelocity = [
            xTumbleAmount,
            ySpinAmount * spinDirection,
            zTumbleAmount
        ]

        card.components[PhysicsMotionComponent.self] = motion
        cardSideAssignments[ObjectIdentifier(card)] = sideIndex
    }

    private func stackCardsBySide() async {
        guard !cards.isEmpty else { return }

        // Group cards by their assigned side
        var sideCards: [Int: [Entity]] = [:]
        for card in cards {
            let side = cardSideAssignments[ObjectIdentifier(card)] ?? 1
            sideCards[side, default: []].append(card)
        }

        // Stack center positions for each side
        let sidePositions: [Int: SIMD3<Float>] = [
            1: [0, 0.008, 0.35],
            2: [-0.55, 0.008, 0],
            3: [0, 0.008, -0.35],
            4: [0.55, 0.008, 0]
        ]

        // Y-axis rotation so cards face their player
        let sideRotations: [Int: simd_quatf] = [
            1: simd_quatf(angle: .pi, axis: [1, 0, 0]),                                                          // face-up, facing bottom
            2: simd_quatf(angle: .pi, axis: [1, 0, 0]) * simd_quatf(angle: .pi / 2, axis: [0, 1, 0]),           // face-up, rotated to face left
            3: simd_quatf(angle: .pi, axis: [1, 0, 0]) * simd_quatf(angle: .pi, axis: [0, 1, 0]),               // face-up, facing top
            4: simd_quatf(angle: .pi, axis: [1, 0, 0]) * simd_quatf(angle: -.pi / 2, axis: [0, 1, 0])          // face-up, rotated to face right
        ]

        for (side, cardsInSide) in sideCards {
            guard let basePos = sidePositions[side],
                  let rotation = sideRotations[side] else { continue }

            for (index, card) in cardsInSide.enumerated() {
                // Switch to kinematic for scripted animation
                if var physicsBody = card.components[PhysicsBodyComponent.self] {
                    physicsBody.mode = .kinematic
                    card.components[PhysicsBodyComponent.self] = physicsBody
                }
                card.components[PhysicsMotionComponent.self] = nil

                let stackY = basePos.y + Float(index) * 0.001
                let target = SIMD3<Float>(basePos.x, stackY, basePos.z)

                card.move(
                    to: Transform(
                        scale: card.scale,
                        rotation: rotation,
                        translation: target
                    ),
                    relativeTo: nil,
                    duration: 0.4,
                    timingFunction: .easeInOut
                )
            }
        }

        // Wait for stack animation to complete
        try? await Task.sleep(for: .seconds(0.4))
    }

    public func gatherAndPickUp(corner: GatherCorner) async {
        guard !cards.isEmpty else { return }

        // Calculate corner position based on table dimensions
        // tableWidth=1.4, tableDepth=1.0, rail=0.07
        let cornerPosition: SIMD3<Float>
        switch corner {
        case .bottomLeft:
            cornerPosition = SIMD3<Float>(-0.55, 0.008, 0.38)
        case .topLeft:
            cornerPosition = SIMD3<Float>(-0.55, 0.008, -0.38)
        case .topRight:
            cornerPosition = SIMD3<Float>(0.55, 0.008, -0.38)
        case .bottomRight:
            cornerPosition = SIMD3<Float>(0.55, 0.008, 0.38)
        }

        // Phase 1 - Gather: slide all cards to the corner
        for (index, card) in cards.enumerated() {
            // Switch to kinematic mode for scripted animation
            if var physicsBody = card.components[PhysicsBodyComponent.self] {
                physicsBody.mode = .kinematic
                card.components[PhysicsBodyComponent.self] = physicsBody
            }
            // Remove any existing motion
            card.components[PhysicsMotionComponent.self] = nil

            let stackY = cornerPosition.y + Float(index) * 0.001
            let target = SIMD3<Float>(cornerPosition.x, stackY, cornerPosition.z)

            card.move(
                to: Transform(
                    scale: card.scale,
                    rotation: simd_quatf(angle: .pi, axis: [1, 0, 0]),
                    translation: target
                ),
                relativeTo: nil,
                duration: 0.4,
                timingFunction: .easeInOut
            )
        }

        // Wait for gather animation to complete
        try? await Task.sleep(for: .seconds(0.4))

        // Phase 2 - Visual pause
        try? await Task.sleep(for: .seconds(0.3))

        // Phase 3 - Pick up: lift the stack upward then remove
        for (index, card) in cards.enumerated() {
            let stackY = cornerPosition.y + Float(index) * 0.001 + 0.15
            let liftTarget = SIMD3<Float>(cornerPosition.x, stackY, cornerPosition.z)

            card.move(
                to: Transform(
                    scale: card.scale,
                    rotation: simd_quatf(angle: .pi, axis: [1, 0, 0]),
                    translation: liftTarget
                ),
                relativeTo: nil,
                duration: 0.3,
                timingFunction: .easeIn
            )
        }

        // Wait for lift animation to complete
        try? await Task.sleep(for: .seconds(0.3))

        // Remove cards from scene
        for card in cards {
            card.removeFromParent()
        }
        cards.removeAll()
        cardSideAssignments.removeAll()
    }

    /// Fans cards out in hands for each player position.
    /// Cards are arranged in an arc pattern to simulate holding cards in hand.
    public func fanCardsInHands() async {
        guard !cards.isEmpty else { return }

        // Group cards by their assigned side
        var sideCards: [Int: [Entity]] = [:]
        for card in cards {
            let side = cardSideAssignments[ObjectIdentifier(card)] ?? 1
            sideCards[side, default: []].append(card)
        }

        // Fan parameters
        let fanRadius: Float = 0.35  // Radius of the arc
        let fanSpread: Float = 0.7   // Total angular spread in radians (~40 degrees)
        let cardHeight: Float = 0.15 // How much to lift cards
        let cardTilt: Float = 0.3    // Forward tilt of cards (radians)

        // Base positions for each hand (closer to player than stack positions)
        let handPositions: [Int: SIMD3<Float>] = [
            1: [0, cardHeight, 0.45],      // Bottom player (closest to viewer)
            2: [-0.65, cardHeight, 0],     // Left player
            3: [0, cardHeight, -0.45],     // Top player (farthest)
            4: [0.65, cardHeight, 0]       // Right player
        ]

        // Base rotations for each side (Y-axis rotation to face player)
        let baseYRotations: [Int: Float] = [
            1: 0,           // Bottom: facing viewer (0 degrees)
            2: .pi / 2,     // Left: rotated 90 degrees
            3: .pi,         // Top: rotated 180 degrees
            4: -.pi / 2     // Right: rotated -90 degrees
        ]

        for (side, cardsInSide) in sideCards {
            guard let centerPos = handPositions[side],
                  let baseYRot = baseYRotations[side] else { continue }

            let cardCount = cardsInSide.count
            guard cardCount > 0 else { continue }

            for (index, card) in cardsInSide.enumerated() {
                // Switch to kinematic for scripted animation
                if var physicsBody = card.components[PhysicsBodyComponent.self] {
                    physicsBody.mode = .kinematic
                    card.components[PhysicsBodyComponent.self] = physicsBody
                }
                card.components[PhysicsMotionComponent.self] = nil

                // Calculate fan angle for this card
                // Center the fan around 0, spreading cards evenly
                let normalizedIndex = Float(index) - Float(cardCount - 1) / 2.0
                let fanAngle = (normalizedIndex / Float(max(cardCount - 1, 1))) * fanSpread

                // Calculate position on the arc
                // The arc is in the local XZ plane before rotation
                let localX = sin(fanAngle) * fanRadius
                let localZ = -cos(fanAngle) * fanRadius + fanRadius  // Offset so arc curves toward player

                // Transform to world coordinates based on side
                let position: SIMD3<Float>
                switch side {
                case 1: // Bottom
                    position = SIMD3<Float>(
                        centerPos.x + localX,
                        centerPos.y,
                        centerPos.z + localZ
                    )
                case 2: // Left
                    position = SIMD3<Float>(
                        centerPos.x + localZ,
                        centerPos.y,
                        centerPos.z + localX
                    )
                case 3: // Top
                    position = SIMD3<Float>(
                        centerPos.x - localX,
                        centerPos.y,
                        centerPos.z - localZ
                    )
                case 4: // Right
                    position = SIMD3<Float>(
                        centerPos.x - localZ,
                        centerPos.y,
                        centerPos.z - localX
                    )
                default:
                    position = centerPos
                }

                // Calculate rotation
                // Start with face-up, then apply tilt, then apply fan rotation, then apply side rotation
                let faceUpQuat = simd_quatf(angle: .pi, axis: [1, 0, 0])  // Face-up
                let tiltQuat = simd_quatf(angle: cardTilt, axis: [1, 0, 0])  // Tilt cards back
                let fanQuat = simd_quatf(angle: fanAngle, axis: [0, 1, 0])  // Fan spread
                let sideQuat = simd_quatf(angle: baseYRot, axis: [0, 1, 0])  // Orient to side

                // Combine rotations: side * fan * tilt * faceUp
                let finalRotation = sideQuat * fanQuat * tiltQuat * faceUpQuat

                // Animate card to fanned position
                card.move(
                    to: Transform(
                        scale: card.scale,
                        rotation: finalRotation,
                        translation: position
                    ),
                    relativeTo: nil,
                    duration: 0.6,
                    timingFunction: .easeInOut
                )
            }
        }

        // Wait for animation to complete
        try? await Task.sleep(for: .seconds(0.6))
    }

    /// Flips a card 180 degrees around the X axis with a short animation.
    /// Only flips cards that are in dynamic or kinematic mode (not during active move animations).
    private func flipCard(_ card: Entity) {
        guard let physicsBody = card.components[PhysicsBodyComponent.self],
              physicsBody.mode == .dynamic || physicsBody.mode == .kinematic else {
            return
        }

        // Determine current face orientation: face-up has ~pi rotation around X
        let currentRotation = card.orientation
        // Check if the card's local Y axis is pointing down (face-up) or up (face-down)
        let localUp = currentRotation.act(SIMD3<Float>(0, 1, 0))
        let isFaceUp = localUp.y < 0

        // Target orientation: toggle between face-up (pi around X) and face-down (identity)
        let targetOrientation = isFaceUp
            ? simd_quatf(angle: 0, axis: [1, 0, 0])  // face-down (identity)
            : simd_quatf(angle: .pi, axis: [1, 0, 0]) // face-up

        // Temporarily switch to kinematic for the flip animation
        let previousMode = physicsBody.mode
        if previousMode == .dynamic {
            var body = physicsBody
            body.mode = .kinematic
            card.components[PhysicsBodyComponent.self] = body
            card.components[PhysicsMotionComponent.self] = nil
        }

        card.move(
            to: Transform(
                scale: card.scale,
                rotation: targetOrientation,
                translation: card.position
            ),
            relativeTo: nil,
            duration: 0.25,
            timingFunction: .easeInOut
        )

        // Restore dynamic mode after flip completes
        if previousMode == .dynamic {
            Task {
                try? await Task.sleep(for: .seconds(0.25))
                if var body = card.components[PhysicsBodyComponent.self] {
                    body.mode = .dynamic
                    card.components[PhysicsBodyComponent.self] = body
                }
            }
        }
    }

    public func resetCards() {
        // Remove all cards and recreate deck
        for card in cards {
            card.removeFromParent()
        }
        cards.removeAll()
        cardSideAssignments.removeAll()
        createDeck()
    }
}
