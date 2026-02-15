import SwiftUI

/// Preset felt colors for the table surface.
public enum FeltColor: String, CaseIterable, Sendable {
    case green = "Green"
    case blue = "Blue"
    case red = "Red"
    case black = "Black"
    case burgundy = "Burgundy"

    /// The base RGB values for texture generation.
    public var rgb: (r: CGFloat, g: CGFloat, b: CGFloat) {
        switch self {
        case .green:    return (0.02, 0.18, 0.06)
        case .blue:     return (0.04, 0.08, 0.22)
        case .red:      return (0.22, 0.04, 0.04)
        case .black:    return (0.06, 0.06, 0.06)
        case .burgundy: return (0.20, 0.04, 0.08)
        }
    }

    /// SwiftUI color for UI swatches.
    public var swatchColor: Color {
        let c = rgb
        return Color(red: c.r, green: c.g, blue: c.b)
    }
}

/// Preset wood finishes for the table frame.
public enum WoodFinish: String, CaseIterable, Sendable {
    case mahogany = "Mahogany"
    case oak = "Oak"
    case walnut = "Walnut"
    case ebony = "Ebony"
    case maple = "Maple"

    /// The base RGB values for texture generation.
    public var rgb: (r: CGFloat, g: CGFloat, b: CGFloat) {
        switch self {
        case .mahogany: return (0.40, 0.18, 0.08)
        case .oak:      return (0.45, 0.32, 0.18)
        case .walnut:   return (0.28, 0.16, 0.08)
        case .ebony:    return (0.10, 0.08, 0.06)
        case .maple:    return (0.55, 0.42, 0.28)
        }
    }

    /// SwiftUI color for UI swatches.
    public var swatchColor: Color {
        let c = rgb
        return Color(red: c.r, green: c.g, blue: c.b)
    }
}

/// Configuration for the table's visual theme.
@Observable
@MainActor
public final class TableThemeSettings: Sendable {
    public var feltColor: FeltColor = .green
    public var woodFinish: WoodFinish = .mahogany

    /// When true, uses customFeltRGB instead of the preset feltColor.
    public var useCustomFelt: Bool = false
    public var customFeltR: Double = 0.02
    public var customFeltG: Double = 0.18
    public var customFeltB: Double = 0.06

    /// When true, uses customWoodRGB instead of the preset woodFinish.
    public var useCustomWood: Bool = false
    public var customWoodR: Double = 0.40
    public var customWoodG: Double = 0.18
    public var customWoodB: Double = 0.08

    public init() {}

    /// The effective felt color values used for texture generation.
    public var effectiveFeltRGB: (r: CGFloat, g: CGFloat, b: CGFloat) {
        if useCustomFelt {
            return (CGFloat(customFeltR), CGFloat(customFeltG), CGFloat(customFeltB))
        }
        return feltColor.rgb
    }

    /// The effective wood color values used for texture generation.
    public var effectiveWoodRGB: (r: CGFloat, g: CGFloat, b: CGFloat) {
        if useCustomWood {
            return (CGFloat(customWoodR), CGFloat(customWoodG), CGFloat(customWoodB))
        }
        return woodFinish.rgb
    }

    /// A cache key string that uniquely identifies the current felt configuration.
    public var feltCacheKey: String {
        let c = effectiveFeltRGB
        return String(format: "felt_%.3f_%.3f_%.3f", c.r, c.g, c.b)
    }

    /// A cache key string that uniquely identifies the current wood configuration.
    public var woodCacheKey: String {
        let c = effectiveWoodRGB
        return String(format: "wood_%.3f_%.3f_%.3f", c.r, c.g, c.b)
    }
}
