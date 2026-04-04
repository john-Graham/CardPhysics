import Foundation

public enum GravityPreset: String, CaseIterable, Sendable {
    case moon = "Moon"
    case mars = "Mars"
    case earth = "Earth"
    case jupiter = "Jupiter"
    case custom = "Custom"

    public static let earthGravity: Float = 9.8

    public var metersPerSecondSquared: Float {
        switch self {
        case .moon: 1.6
        case .mars: 3.7
        case .earth: Self.earthGravity
        case .jupiter: 24.8
        case .custom: Self.earthGravity
        }
    }

    public var multiplier: Float {
        metersPerSecondSquared / Self.earthGravity
    }
}
