import Foundation
import SwiftUI

public enum CardFaceStyle: String, CaseIterable, Codable, Sendable {
    case classic
    case modern
    case minimal
    case bold
    case customImage
    case selfie

    public var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .modern: return "Modern"
        case .minimal: return "Minimal"
        case .bold: return "Bold"
        case .customImage: return "Photo"
        case .selfie: return "Selfie"
        }
    }

    public var icon: String {
        switch self {
        case .classic: return "rectangle.portrait"
        case .modern: return "rectangle.portrait.fill"
        case .minimal: return "square"
        case .bold: return "rectangle.portrait.inset.filled"
        case .customImage: return "photo"
        case .selfie: return "camera"
        }
    }

    /// Styles that appear in the preset picker (not photo/selfie)
    public static var presets: [CardFaceStyle] {
        [.classic, .modern, .minimal, .bold]
    }
}

public enum CardBackStyle: String, CaseIterable, Codable, Sendable {
    case classicMaroon
    case royalBlue
    case forestGreen
    case midnight
    case customImage
    case selfie

    public var displayName: String {
        switch self {
        case .classicMaroon: return "Maroon"
        case .royalBlue: return "Royal Blue"
        case .forestGreen: return "Forest Green"
        case .midnight: return "Midnight"
        case .customImage: return "Photo"
        case .selfie: return "Selfie"
        }
    }

    public var gradientColors: (primary: Color, secondary: Color) {
        switch self {
        case .classicMaroon:
            return (
                Color(red: 0.55, green: 0.08, blue: 0.10),
                Color(red: 0.40, green: 0.05, blue: 0.08)
            )
        case .royalBlue:
            return (
                Color(red: 0.10, green: 0.15, blue: 0.55),
                Color(red: 0.06, green: 0.08, blue: 0.40)
            )
        case .forestGreen:
            return (
                Color(red: 0.08, green: 0.40, blue: 0.15),
                Color(red: 0.05, green: 0.28, blue: 0.10)
            )
        case .midnight:
            return (
                Color(red: 0.10, green: 0.10, blue: 0.20),
                Color(red: 0.05, green: 0.05, blue: 0.12)
            )
        case .customImage, .selfie:
            // Fallback gradient for custom/selfie (not used when image is loaded)
            return (
                Color(red: 0.55, green: 0.08, blue: 0.10),
                Color(red: 0.40, green: 0.05, blue: 0.08)
            )
        }
    }

    public var swatchColor: Color {
        gradientColors.primary
    }

    /// Styles that appear in the preset picker (not photo/selfie)
    public static var presets: [CardBackStyle] {
        [.classicMaroon, .royalBlue, .forestGreen, .midnight]
    }
}

@Observable
@MainActor
public final class CardDesignConfiguration: Sendable {
    public var faceStyle: CardFaceStyle = .classic
    public var backStyle: CardBackStyle = .classicMaroon

    public var customFaceImageFilename: String?
    public var customBackImageFilename: String?
    public var selfieFaceImageFilename: String?
    public var selfieBackImageFilename: String?

    public init() {
        load()
    }

    // MARK: - Persistence

    private static let faceStyleKey = "cardDesign.faceStyle"
    private static let backStyleKey = "cardDesign.backStyle"
    private static let customFaceImageKey = "cardDesign.customFaceImage"
    private static let customBackImageKey = "cardDesign.customBackImage"
    private static let selfieFaceImageKey = "cardDesign.selfieFaceImage"
    private static let selfieBackImageKey = "cardDesign.selfieBackImage"

    public func save() {
        let defaults = UserDefaults.standard
        defaults.set(faceStyle.rawValue, forKey: Self.faceStyleKey)
        defaults.set(backStyle.rawValue, forKey: Self.backStyleKey)
        defaults.set(customFaceImageFilename, forKey: Self.customFaceImageKey)
        defaults.set(customBackImageFilename, forKey: Self.customBackImageKey)
        defaults.set(selfieFaceImageFilename, forKey: Self.selfieFaceImageKey)
        defaults.set(selfieBackImageFilename, forKey: Self.selfieBackImageKey)
    }

    public func load() {
        let defaults = UserDefaults.standard
        if let raw = defaults.string(forKey: Self.faceStyleKey),
           let style = CardFaceStyle(rawValue: raw) {
            faceStyle = style
        }
        if let raw = defaults.string(forKey: Self.backStyleKey),
           let style = CardBackStyle(rawValue: raw) {
            backStyle = style
        }
        customFaceImageFilename = defaults.string(forKey: Self.customFaceImageKey)
        customBackImageFilename = defaults.string(forKey: Self.customBackImageKey)
        selfieFaceImageFilename = defaults.string(forKey: Self.selfieFaceImageKey)
        selfieBackImageFilename = defaults.string(forKey: Self.selfieBackImageKey)
    }

    /// The filename to use for the current face style's custom image, if any
    public var activeFaceImageFilename: String? {
        switch faceStyle {
        case .customImage: return customFaceImageFilename
        case .selfie: return selfieFaceImageFilename
        default: return nil
        }
    }

    /// The filename to use for the current back style's custom image, if any
    public var activeBackImageFilename: String? {
        switch backStyle {
        case .customImage: return customBackImageFilename
        case .selfie: return selfieBackImageFilename
        default: return nil
        }
    }
}
