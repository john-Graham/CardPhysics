import Foundation

@Observable
@MainActor
public final class PhysicsSettings: Sendable {
    // Animation speeds (seconds)
    public var dealDuration: Double = 0.5
    public var pickUpDuration: Double = 0.3

    // Arc heights (meters)
    public var dealArcHeight: Float = 0.15
    public var pickUpArcHeight: Float = 0.08

    // Rotation amounts (degrees)
    public var dealRotation: Double = 15.0
    public var pickUpRotation: Double = 5.0

    // Card curvature (0.0 = flat, higher = more curve)
    public var cardCurvature: Float = 0.002

    public init() {}

    // Preset configurations
    public func applyRealisticPreset() {
        dealDuration = 0.5
        pickUpDuration = 0.3

        dealArcHeight = 0.15
        pickUpArcHeight = 0.08

        dealRotation = 15.0
        pickUpRotation = 5.0

        cardCurvature = 0.002
    }

    public func applySlowMotionPreset() {
        dealDuration = 2.0
        pickUpDuration = 1.0

        dealArcHeight = 0.20
        pickUpArcHeight = 0.10

        dealRotation = 20.0
        pickUpRotation = 8.0

        cardCurvature = 0.003
    }

    public func applyFastPreset() {
        dealDuration = 0.2
        pickUpDuration = 0.1

        dealArcHeight = 0.10
        pickUpArcHeight = 0.05

        dealRotation = 10.0
        pickUpRotation = 3.0

        cardCurvature = 0.001
    }
}
