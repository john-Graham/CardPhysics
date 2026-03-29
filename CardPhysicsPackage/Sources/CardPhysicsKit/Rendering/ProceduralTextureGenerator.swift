import CoreGraphics
import RealityKit

/// Generates procedural PBR textures for the game table materials using CoreGraphics.
///
/// Material-specific generation is split into extension files:
/// - `FeltMaterialGenerator.swift` -- felt albedo, roughness, and normal maps
/// - `WoodMaterialGenerator.swift` -- wood albedo, roughness, and normal maps
/// - `CardWearTextureGenerator.swift` -- paper grain, wear overlays
@MainActor
enum ProceduralTextureGenerator {

    // MARK: - Texture Cache

    /// Cache for generated CGImages, keyed by a string identifier.
    /// Internal access so extension files can read/write the cache.
    static var imageCache: [String: CGImage] = [:]

    /// Clears all cached textures. Call when theme changes require fresh generation.
    static func clearCache() {
        imageCache.removeAll()
    }

    // MARK: - Texture Resource Conversion

    /// Converts a CGImage to a RealityKit TextureResource for use as albedo/color.
    static func colorTexture(from image: CGImage) -> TextureResource? {
        try? TextureResource(image: image, options: .init(semantic: .color))
    }

    /// Converts a CGImage to a RealityKit TextureResource for use as normal map.
    static func normalTexture(from image: CGImage) -> TextureResource? {
        try? TextureResource(image: image, options: .init(semantic: .normal))
    }

    /// Converts a CGImage to a RealityKit TextureResource for use as roughness/data.
    static func dataTexture(from image: CGImage) -> TextureResource? {
        try? TextureResource(image: image, options: .init(semantic: .raw))
    }

    // MARK: - Helpers

    /// Creates a CoreGraphics bitmap context for texture generation.
    /// Internal access so extension files can use this helper.
    static func makeContext(width: Int, height: Int) -> CGContext? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        return CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
    }
}
