import Foundation
import SwiftUI

public enum CardFaceStyle: String, CaseIterable, Codable, Sendable {
    case standardPoker
    case jumboIndex
    case casinoDiamond
    case customImage
    case selfie

    public var displayName: String {
        switch self {
        case .standardPoker: "Standard Poker"
        case .jumboIndex: "Jumbo Index"
        case .casinoDiamond: "Casino Diamond"
        case .customImage: "Photo"
        case .selfie: "Selfie"
        }
    }

    public var icon: String {
        switch self {
        case .standardPoker: "suit.heart.fill"
        case .jumboIndex: "textformat.size.larger"
        case .casinoDiamond: "diamond.fill"
        case .customImage: "photo"
        case .selfie: "camera"
        }
    }

    /// Styles that appear in the preset picker (not photo/selfie)
    public static var presets: [CardFaceStyle] {
        [.standardPoker, .jumboIndex, .casinoDiamond]
    }
}

public enum CardBackStyle: String, CaseIterable, Codable, Sendable {
    case standardPoker
    case jumboIndex
    case casinoDiamond
    case customImage
    case selfie

    public var displayName: String {
        switch self {
        case .standardPoker: "Standard Poker"
        case .jumboIndex: "Jumbo Index"
        case .casinoDiamond: "Casino Diamond"
        case .customImage: "Photo"
        case .selfie: "Selfie"
        }
    }

    public var gradientColors: (primary: Color, secondary: Color) {
        switch self {
        case .standardPoker:
            (
                Color(red: 0.70, green: 0.05, blue: 0.08),
                Color(red: 0.48, green: 0.02, blue: 0.05)
            )
        case .jumboIndex:
            (
                Color(red: 0.10, green: 0.15, blue: 0.55),
                Color(red: 0.06, green: 0.08, blue: 0.40)
            )
        case .casinoDiamond:
            (
                Color(red: 0.82, green: 0.05, blue: 0.07),
                Color(red: 0.58, green: 0.02, blue: 0.04)
            )
        case .customImage, .selfie:
            // Fallback gradient for custom/selfie (not used when image is loaded)
            (
                Color(red: 0.70, green: 0.05, blue: 0.08),
                Color(red: 0.48, green: 0.02, blue: 0.05)
            )
        }
    }

    public var swatchColor: Color {
        gradientColors.primary
    }

    /// Styles that appear in the preset picker (not photo/selfie)
    public static var presets: [CardBackStyle] {
        [.standardPoker, .jumboIndex, .casinoDiamond]
    }
}

@Observable
@MainActor
public final class CardDesignConfiguration {
    public var faceStyle: CardFaceStyle = .standardPoker
    public var backStyle: CardBackStyle = .standardPoker

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
        case .customImage: customFaceImageFilename
        case .selfie: selfieFaceImageFilename
        default: nil
        }
    }

    /// The filename to use for the current back style's custom image, if any
    public var activeBackImageFilename: String? {
        switch backStyle {
        case .customImage: customBackImageFilename
        case .selfie: selfieBackImageFilename
        default: nil
        }
    }
}
