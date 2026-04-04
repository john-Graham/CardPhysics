import Foundation

/// Settings for in-hands fan animation for a specific player side
@Observable
@MainActor
public final class InHandsSideSettings {
    public var fanAngle: Float = -0.85      // Total fan angle (~-49° natural fan)
    public var tiltAngle: Float = -0.38     // Tilt back angle in radians (~-22°, shows face from overhead cam)
    public var arcRadius: Float = 0.20      // Radius of the fan arc (~35% card face visible)
    public var verticalSpacing: Float = 0.002  // Vertical spacing between cards (very tight)
    public var rotationOffset: Float = 0.035  // Additional Y-axis rotation offset (~2°)
    public var curvature: Float = -0.015     // Card curvature away from player (meters, 0 = flat)

    public init() {}

    public init(fanAngle: Float, tiltAngle: Float, arcRadius: Float, verticalSpacing: Float, rotationOffset: Float = 0.0, curvature: Float = -0.012) {
        self.fanAngle = fanAngle
        self.tiltAngle = tiltAngle
        self.arcRadius = arcRadius
        self.verticalSpacing = verticalSpacing
        self.rotationOffset = rotationOffset
        self.curvature = curvature
    }
}

public enum ShadowQuality: String, CaseIterable, Sendable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    public var mapResolution: Int {
        switch self {
        case .low: 256
        case .medium: 512
        case .high: 1024
        }
    }
}

@Observable
@MainActor
public final class PhysicsSettings {

    // MARK: - Deal Animation
    public var dealDuration: Double = 0.5
    public var dealArcHeight: Float = 0.15
    public var dealRotation: Double = 15.0

    // MARK: - Pick Up Animation
    public var pickUpDuration: Double = 0.3
    public var pickUpArcHeight: Float = 0.08
    public var pickUpRotation: Double = 5.0

    // MARK: - In Hands Animation
    public var inHandsSide1: InHandsSideSettings = InHandsSideSettings()  // Bottom (closest to viewer)
    public var inHandsSide2: InHandsSideSettings = InHandsSideSettings()  // Left
    public var inHandsSide3: InHandsSideSettings = InHandsSideSettings()  // Top (farthest from viewer)
    public var inHandsSide4: InHandsSideSettings = InHandsSideSettings()  // Right
    public var inHandsAnimationDuration: Double = 0.4  // Animation duration per card

    public func inHandsSettings(for side: Int) -> InHandsSideSettings {
        switch side {
        case 1: inHandsSide1
        case 2: inHandsSide2
        case 3: inHandsSide3
        case 4: inHandsSide4
        default: inHandsSide1
        }
    }

    // MARK: - Card Appearance
    public var cardCurvature: Float = 0.002

    // MARK: - Interaction
    public var enableCardTapGesture: Bool = false

    // MARK: - Feature Flags
    public var enableGravityFeature: Bool = true
    public var enablePlayerCameraPresets: Bool = true
    public var enableOverheadCameraPreset: Bool = true

    // MARK: - Physics Experimentation
    public var gravityMultiplier: Float = GravityPreset.earth.multiplier
    public var gravityPreset: GravityPreset = .earth

    public var gravityMetersPerSecondSquared: Float {
        get {
            gravityMultiplier * GravityPreset.earthGravity
        }
        set {
            let clamped = min(
                max(newValue, GravityPreset.moon.metersPerSecondSquared),
                GravityPreset.jupiter.metersPerSecondSquared
            )
            gravityMultiplier = clamped / GravityPreset.earthGravity
            gravityPreset = .custom
        }
    }

    public func applyGravityPreset(_ preset: GravityPreset) {
        gravityPreset = preset
        gravityMultiplier = preset.multiplier
    }

    // MARK: - Table Theme
    public var tableTheme: TableThemeSettings = TableThemeSettings()

    // MARK: - Card Wear
    public var enableCardWear: Bool = false
    public var wearIntensity: Double = 1.0  // 0.5 to 2.0

    // MARK: - Particle Effects
    public var enableDustMotes: Bool = false
    public var enableFeltDisturbance: Bool = false
    public var dustDensity: Double = 1.0    // 0.5 to 2.0
    public var burstIntensity: Double = 1.0  // 0.5 to 2.0

    // MARK: - Shadows
    public var enableCardShadows: Bool = false
    public var shadowQuality: ShadowQuality = .medium

    // MARK: - Room Environment
    public var roomEnvironment: RoomEnvironment = .none
    public var customRoomImageFilename: String = ""
    public var roomRotation: Double = 0.0  // 0-360 degrees

    public init() {}

    // MARK: - Presets
    public func applyRealisticPreset() {
        dealDuration = 0.5
        pickUpDuration = 0.3

        dealArcHeight = 0.15
        pickUpArcHeight = 0.08

        dealRotation = 15.0
        pickUpRotation = 5.0

        // Set same values for all sides
        for side in [inHandsSide1, inHandsSide2, inHandsSide3, inHandsSide4] {
            side.fanAngle = .pi / 6
            side.tiltAngle = 0.3
            side.arcRadius = 0.3
            side.verticalSpacing = 0.015
        }
        inHandsAnimationDuration = 0.4

        cardCurvature = 0.002
    }

    public func applySlowMotionPreset() {
        dealDuration = 2.0
        pickUpDuration = 1.0

        dealArcHeight = 0.20
        pickUpArcHeight = 0.10

        dealRotation = 20.0
        pickUpRotation = 8.0

        // Set same values for all sides
        for side in [inHandsSide1, inHandsSide2, inHandsSide3, inHandsSide4] {
            side.fanAngle = .pi / 5
            side.tiltAngle = 0.35
            side.arcRadius = 0.35
            side.verticalSpacing = 0.02
        }
        inHandsAnimationDuration = 0.8

        cardCurvature = 0.003
    }

    public func applyFastPreset() {
        dealDuration = 0.2
        pickUpDuration = 0.1

        dealArcHeight = 0.10
        pickUpArcHeight = 0.05

        dealRotation = 10.0
        pickUpRotation = 3.0

        // Set same values for all sides
        for side in [inHandsSide1, inHandsSide2, inHandsSide3, inHandsSide4] {
            side.fanAngle = .pi / 7
            side.tiltAngle = 0.25
            side.arcRadius = 0.25
            side.verticalSpacing = 0.01
        }
        inHandsAnimationDuration = 0.2

        cardCurvature = 0.001
    }
}
