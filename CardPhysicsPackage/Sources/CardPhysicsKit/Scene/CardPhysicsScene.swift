import SwiftUI
import RealityKit

@MainActor
public struct CardPhysicsScene: View {
    @State internal var rootEntity = Entity()
    @State internal var cards: [Entity] = []
    @State internal var cardSideAssignments: [ObjectIdentifier: Int] = [:]
    @State internal var deckPosition = Entity()
    @State internal var handEntities: [Entity] = []
    @State internal var lastRoomEnvironment: RoomEnvironment = .none
    @State internal var lastCustomRoomImageFilename: String = ""
    @State internal var lastRoomRotation: Double = 0.0
    @State internal var lastShadowsEnabled: Bool = false
    @State internal var lastShadowQuality: ShadowQuality = .medium
    @State internal var lastFeltCacheKey: String = ""
    @State internal var lastWoodCacheKey: String = ""
    @State internal var cardWearComponents: [ObjectIdentifier: CardWearComponent] = [:]
    @State internal var cardDataMap: [ObjectIdentifier: Card] = [:]
    @State internal var collisionSubscription: EventSubscription?
    @State internal var dustEmitterEntity: Entity?
    @State internal var activeBurstEntities: [Entity] = []
    @State internal var lastDustMotesEnabled: Bool = false
    @State internal var lastFeltDisturbanceEnabled: Bool = false

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
            coordinator?.updateInHandsPositionsAction = { [self] in
                self.updateInHandsCardPositions()
            }
            coordinator?.resetCardsAction = { [self] in
                self.resetCards()
            }
            coordinator?.updateTableMaterialsAction = { [self] in
                self.updateTableMaterials()
            }

            // Subscribe to collision events for wear tracking and felt disturbance
            if settings.enableCardWear || settings.enableFeltDisturbance {
                collisionSubscription = content.subscribe(to: CollisionEvents.Began.self) { event in
                    handleCollision(entityA: event.entityA, entityB: event.entityB)
                }
            }

            // Pre-generate wear overlay textures if wear is enabled
            if settings.enableCardWear {
                ProceduralTextureGenerator.preloadWearOverlays(intensity: CGFloat(settings.wearIntensity))
            }

            // Add dust motes emitter if enabled
            if settings.enableDustMotes {
                let emitter = ParticleEffects.createDustMotesEmitter(density: Float(settings.dustDensity))
                rootEntity.addChild(emitter)
                dustEmitterEntity = emitter
            }
            lastDustMotesEnabled = settings.enableDustMotes
            lastFeltDisturbanceEnabled = settings.enableFeltDisturbance

            // Store initial theme cache keys
            lastFeltCacheKey = settings.tableTheme.feltCacheKey
            lastWoodCacheKey = settings.tableTheme.woodCacheKey
        } update: { content in
            // Update camera position when parameters change
            if let cameraEntity = rootEntity.findEntity(named: "camera") {
                cameraEntity.position = cameraPosition
                cameraEntity.look(at: cameraTarget, from: cameraPosition, relativeTo: nil)
            }

            // Update shadow light if settings changed
            if settings.enableCardShadows != lastShadowsEnabled ||
               settings.shadowQuality != lastShadowQuality {
                if settings.enableCardShadows {
                    setupShadowLight()
                    // Add GroundingShadowComponent to felt if not already present
                    if let felt = rootEntity.findEntity(named: "feltSurface") as? ModelEntity {
                        felt.components.set(GroundingShadowComponent(castsShadow: true))
                    }
                    // Add shadow components to existing cards
                    for card in cards {
                        if let modelEntity = card as? ModelEntity {
                            modelEntity.components.set(GroundingShadowComponent(castsShadow: true))
                        }
                    }
                } else {
                    removeShadowLight()
                    // Remove shadow components from felt
                    if let felt = rootEntity.findEntity(named: "feltSurface") as? ModelEntity {
                        felt.components.remove(GroundingShadowComponent.self)
                    }
                    // Remove shadow components from cards
                    for card in cards {
                        if let modelEntity = card as? ModelEntity {
                            modelEntity.components.remove(GroundingShadowComponent.self)
                        }
                    }
                }
                lastShadowsEnabled = settings.enableCardShadows
                lastShadowQuality = settings.shadowQuality
            }

            // Update table materials if theme changed
            let currentFeltKey = settings.tableTheme.feltCacheKey
            let currentWoodKey = settings.tableTheme.woodCacheKey
            if currentFeltKey != lastFeltCacheKey || currentWoodKey != lastWoodCacheKey {
                updateTableMaterials()
                lastFeltCacheKey = currentFeltKey
                lastWoodCacheKey = currentWoodKey
            }

            // Update dust motes emitter if toggled
            if settings.enableDustMotes != lastDustMotesEnabled {
                if settings.enableDustMotes {
                    let emitter = ParticleEffects.createDustMotesEmitter(density: Float(settings.dustDensity))
                    rootEntity.addChild(emitter)
                    dustEmitterEntity = emitter
                } else {
                    dustEmitterEntity?.removeFromParent()
                    dustEmitterEntity = nil
                }
                lastDustMotesEnabled = settings.enableDustMotes
            }

            // Set up or tear down collision subscription for felt disturbance
            if settings.enableFeltDisturbance != lastFeltDisturbanceEnabled {
                if settings.enableFeltDisturbance && collisionSubscription == nil {
                    collisionSubscription = content.subscribe(to: CollisionEvents.Began.self) { event in
                        handleCollision(entityA: event.entityA, entityB: event.entityB)
                    }
                }
                lastFeltDisturbanceEnabled = settings.enableFeltDisturbance
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


    public func resetCards() {
        // Remove all cards and recreate deck
        for card in cards {
            card.removeFromParent()
        }
        cards.removeAll()
        cardSideAssignments.removeAll()
        cardWearComponents.removeAll()
        cardDataMap.removeAll()
        createDeck()
    }
}
