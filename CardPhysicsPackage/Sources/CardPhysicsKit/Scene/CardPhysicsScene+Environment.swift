import RealityKit
import SwiftUI

extension CardPhysicsScene {
internal func setupLighting() {
    // Try to load HDRI environment
    do {
        let environment = try EnvironmentResource.load(named: "room_bg", in: Bundle.module)
        rootEntity.components.set(ImageBasedLightComponent(source: .single(environment)))
        rootEntity.components.set(ImageBasedLightReceiverComponent(imageBasedLight: rootEntity))
    } catch {
        print("⚠️ Failed to load HDRI: \(error). Using fallback lighting.")
        setupFallbackLighting()
    }

    // Add directional light for shadows if enabled
    if settings.enableCardShadows {
        setupShadowLight()
    }
    lastShadowsEnabled = settings.enableCardShadows
    lastShadowQuality = settings.shadowQuality
}

internal func setupShadowLight() {
    // Remove existing shadow light if any
    if let existing = rootEntity.findEntity(named: "shadowDirectionalLight") {
        existing.removeFromParent()
    }

    let shadowLight = Entity()
    var directionalLight = DirectionalLightComponent()
    directionalLight.color = .init(red: 1.0, green: 0.98, blue: 0.95, alpha: 1.0)
    directionalLight.intensity = 500
    // Note: Shadow casting is controlled by GroundingShadowComponent on entities,
    // not by DirectionalLightComponent configuration
    shadowLight.components.set(directionalLight)
    // Position above and slightly in front, angled down at the table
    shadowLight.position = [0.2, 1.5, 0.3]
    shadowLight.look(at: [0, 0, 0], from: shadowLight.position, relativeTo: nil)
    shadowLight.name = "shadowDirectionalLight"
    rootEntity.addChild(shadowLight)
}

internal func removeShadowLight() {
    if let existing = rootEntity.findEntity(named: "shadowDirectionalLight") {
        existing.removeFromParent()
    }
}

internal func setupFallbackLighting() {
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

internal func updateSkybox() {
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

/// Hot-swaps felt and wood materials on the existing table entities.
internal func updateTableMaterials() {
    let texGen = ProceduralTextureGenerator.self
    guard let tableRoot = rootEntity.findEntity(named: "table") else { return }

    // Regenerate wood material
    let woodRGB = settings.tableTheme.effectiveWoodRGB
    var woodMaterial = PhysicallyBasedMaterial()
    if let woodImg = texGen.woodAlbedo(baseR: woodRGB.r, baseG: woodRGB.g, baseB: woodRGB.b),
       let woodTex = texGen.colorTexture(from: woodImg) {
        woodMaterial.baseColor = .init(texture: .init(woodTex))
    } else {
        woodMaterial.baseColor = .init(tint: .init(red: CGFloat(woodRGB.r), green: CGFloat(woodRGB.g), blue: CGFloat(woodRGB.b), alpha: 1.0))
    }
    if let roughImg = texGen.woodRoughness(),
       let roughTex = texGen.dataTexture(from: roughImg) {
        woodMaterial.roughness = .init(texture: .init(roughTex))
    } else {
        woodMaterial.roughness = .init(floatLiteral: 0.6)
    }
    if let normImg = texGen.woodNormal(),
       let normTex = texGen.normalTexture(from: normImg) {
        woodMaterial.normal = .init(texture: .init(normTex))
    }
    woodMaterial.clearcoat = .init(floatLiteral: 1.0)
    woodMaterial.clearcoatRoughness = .init(floatLiteral: 0.02)
    woodMaterial.specular = .init(floatLiteral: 0.5)

    // Apply wood material to all ModelEntity children of table except felt
    for child in tableRoot.children {
        guard let model = child as? ModelEntity,
              model.name != "feltSurface",
              model.model != nil else { continue }
        model.model?.materials = [woodMaterial]
    }

    // Regenerate felt material
    let feltRGB = settings.tableTheme.effectiveFeltRGB
    var feltMaterial = PhysicallyBasedMaterial()
    if let feltImg = texGen.feltAlbedo(baseR: feltRGB.r, baseG: feltRGB.g, baseB: feltRGB.b),
       let feltTex = texGen.colorTexture(from: feltImg) {
        feltMaterial.baseColor = .init(texture: .init(feltTex))
    } else {
        feltMaterial.baseColor = .init(tint: .init(red: CGFloat(feltRGB.r), green: CGFloat(feltRGB.g), blue: CGFloat(feltRGB.b), alpha: 1.0))
    }
    if let feltRoughImg = texGen.feltRoughness(),
       let feltRoughTex = texGen.dataTexture(from: feltRoughImg) {
        feltMaterial.roughness = .init(texture: .init(feltRoughTex))
    } else {
        feltMaterial.roughness = .init(floatLiteral: 0.95)
    }
    if let feltNormImg = texGen.feltNormal(),
       let feltNormTex = texGen.normalTexture(from: feltNormImg) {
        feltMaterial.normal = .init(texture: .init(feltNormTex))
    }
    feltMaterial.metallic = .init(floatLiteral: 0.0)

    if let felt = tableRoot.findEntity(named: "feltSurface") as? ModelEntity {
        felt.model?.materials = [feltMaterial]
    }
}

}
