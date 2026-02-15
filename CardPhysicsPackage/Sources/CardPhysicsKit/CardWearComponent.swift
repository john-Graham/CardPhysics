import RealityKit

/// Wear level progression based on interaction count thresholds.
public enum WearLevel: Int, CaseIterable, Sendable {
    case none = 0
    case light = 1
    case moderate = 2
    case heavy = 3
    case extreme = 4

    public var displayName: String {
        switch self {
        case .none: return "None"
        case .light: return "Light"
        case .moderate: return "Moderate"
        case .heavy: return "Heavy"
        case .extreme: return "Extreme"
        }
    }

    /// Determines wear level from interaction count.
    public static func from(interactionCount: Int) -> WearLevel {
        switch interactionCount {
        case 0..<3: return .none
        case 3..<8: return .light
        case 8..<15: return .moderate
        case 15..<25: return .heavy
        default: return .extreme
        }
    }
}

/// Component that tracks wear state for a card entity.
@MainActor
public final class CardWearComponent: Sendable {
    public var interactionCount: Int = 0
    public var currentWearLevel: WearLevel = .none

    public init() {}

    /// Increments interaction count and returns the new wear level.
    /// Returns the previous wear level for comparison.
    @discardableResult
    public func incrementWear() -> (previousLevel: WearLevel, newLevel: WearLevel) {
        let previousLevel = currentWearLevel
        interactionCount += 1
        currentWearLevel = WearLevel.from(interactionCount: interactionCount)
        return (previousLevel, currentWearLevel)
    }

    /// Resets wear state to pristine.
    public func reset() {
        interactionCount = 0
        currentWearLevel = .none
    }
}
