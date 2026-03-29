import Foundation

/// Defines available room environment backgrounds for the 3D card table scene.
public enum RoomEnvironment: String, Codable, Sendable, CaseIterable {
    /// No room background (default RealityKit environment)
    case none

    /// Classic poker room with green felt walls and warm lighting
    case pokerRoom

    /// Modern office with contemporary decor
    case modernOffice

    /// Classic library with wood paneling and bookshelves
    case classicLibrary

    /// Rustic wood cabin interior
    case woodCabin

    /// User-provided custom panoramic image
    case customImage

    /// Returns the filename of the panoramic image resource for this room type.
    /// Returns nil for `.none` and `.customImage` (which uses customRoomImageFilename).
    public var panoramaFilename: String? {
        switch self {
        case .none:
            nil
        case .pokerRoom:
            "poker_room.jpg"
        case .modernOffice:
            "modern_office.jpg"
        case .classicLibrary:
            "classic_library.jpg"
        case .woodCabin:
            "wood_cabin.jpg"
        case .customImage:
            nil
        }
    }

    /// Human-readable display name for the room environment
    public var displayName: String {
        switch self {
        case .none:
            "None"
        case .pokerRoom:
            "Poker Room"
        case .modernOffice:
            "Modern Office"
        case .classicLibrary:
            "Classic Library"
        case .woodCabin:
            "Wood Cabin"
        case .customImage:
            "Custom Image"
        }
    }
}
