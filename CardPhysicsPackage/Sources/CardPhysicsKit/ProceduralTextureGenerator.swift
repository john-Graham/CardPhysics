import CoreGraphics
import RealityKit

/// Generates procedural PBR textures for the game table materials using CoreGraphics.
@MainActor
enum ProceduralTextureGenerator {

    // MARK: - Texture Cache

    /// Cache for generated CGImages, keyed by a string identifier.
    private static var imageCache: [String: CGImage] = [:]

    /// Clears all cached textures. Call when theme changes require fresh generation.
    static func clearCache() {
        imageCache.removeAll()
    }

    /// Clears only felt-related cached textures.
    static func clearFeltCache() {
        imageCache = imageCache.filter { !$0.key.hasPrefix("felt_albedo_") }
    }

    /// Clears only wood-related cached textures.
    static func clearWoodCache() {
        imageCache = imageCache.filter { !$0.key.hasPrefix("wood_albedo_") }
    }

    // MARK: - Felt Fabric Texture

    /// Generates a felt albedo texture with the given base color.
    /// Uses caching: subsequent calls with the same color return instantly.
    static func feltAlbedo(
        baseR: CGFloat = 0.02,
        baseG: CGFloat = 0.18,
        baseB: CGFloat = 0.06,
        width: Int = 1024,
        height: Int = 1024
    ) -> CGImage? {
        let cacheKey = String(format: "felt_albedo_%.3f_%.3f_%.3f", baseR, baseG, baseB)
        if let cached = imageCache[cacheKey] { return cached }

        guard let ctx = makeContext(width: width, height: height) else { return nil }

        ctx.setFillColor(CGColor(red: baseR, green: baseG, blue: baseB, alpha: 1.0))
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // Layer 1: Large-scale unevenness (mottled patches)
        for _ in 0..<600 {
            let x = CGFloat.random(in: 0...CGFloat(width))
            let y = CGFloat.random(in: 0...CGFloat(height))
            let radius = CGFloat.random(in: 30...80)
            let brightness = CGFloat.random(in: -0.015...0.015)

            ctx.setFillColor(CGColor(red: baseR + brightness, green: baseG + brightness * 1.2, blue: baseB + brightness, alpha: 0.15))
            ctx.fillEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
        }

        // Layer 2: High-density fiber noise (simulating wool texture)
        for _ in 0..<80000 {
            let x = CGFloat.random(in: 0...CGFloat(width))
            let y = CGFloat.random(in: 0...CGFloat(height))
            let size = CGFloat.random(in: 0.5...1.5)
            let brightness = CGFloat.random(in: -0.04...0.08)

            ctx.setFillColor(CGColor(
                red: baseR + brightness,
                green: baseG + brightness * 1.8,
                blue: baseB + brightness,
                alpha: 0.15
            ))
            ctx.fillEllipse(in: CGRect(x: x, y: y, width: size, height: size))
        }

        // Layer 3: Occasional brighter "lint" or nap highlights
        for _ in 0..<2000 {
            let x = CGFloat.random(in: 0...CGFloat(width))
            let y = CGFloat.random(in: 0...CGFloat(height))
            let size = CGFloat.random(in: 0.5...1.2)
            let bright = CGFloat.random(in: 0.05...0.15)
            ctx.setFillColor(CGColor(red: baseR + bright, green: baseG + bright, blue: baseB + bright, alpha: 0.1))
            ctx.fillEllipse(in: CGRect(x: x, y: y, width: size, height: size))
        }

        let image = ctx.makeImage()
        if let image { imageCache[cacheKey] = image }
        return image
    }

    /// Generates a felt roughness map -- mostly rough with slight variation.
    static func feltRoughness(width: Int = 1024, height: Int = 1024) -> CGImage? {
        let cacheKey = "felt_roughness"
        if let cached = imageCache[cacheKey] { return cached }

        guard let ctx = makeContext(width: width, height: height) else { return nil }

        // High base roughness (near white = rough). Felt is very matte.
        ctx.setFillColor(CGColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0))
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // Slight variation for wear
        for _ in 0..<3000 {
            let x = CGFloat.random(in: 0...CGFloat(width))
            let y = CGFloat.random(in: 0...CGFloat(height))
            let size = CGFloat.random(in: 5...15)
            let v = CGFloat.random(in: 0.75...0.90)
            ctx.setFillColor(CGColor(red: v, green: v, blue: v, alpha: 0.2))
            ctx.fillEllipse(in: CGRect(x: x, y: y, width: size, height: size))
        }

        let image = ctx.makeImage()
        if let image { imageCache[cacheKey] = image }
        return image
    }

    // MARK: - Wood Grain Texture

    /// Generates a wood albedo texture with the given base color.
    /// Uses caching: subsequent calls with the same color return instantly.
    static func woodAlbedo(
        baseR: CGFloat = 0.40,
        baseG: CGFloat = 0.18,
        baseB: CGFloat = 0.08,
        width: Int = 1024,
        height: Int = 1024
    ) -> CGImage? {
        let cacheKey = String(format: "wood_albedo_%.3f_%.3f_%.3f", baseR, baseG, baseB)
        if let cached = imageCache[cacheKey] { return cached }

        guard let ctx = makeContext(width: width, height: height) else { return nil }

        ctx.setFillColor(CGColor(red: baseR, green: baseG, blue: baseB, alpha: 1.0))
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // Layer 1: Micro-grain noise (pores/texture)
        for _ in 0..<40000 {
            let x = CGFloat.random(in: 0...CGFloat(width))
            let y = CGFloat.random(in: 0...CGFloat(height))
            let len = CGFloat.random(in: 2...8)
            let w = CGFloat.random(in: 0.5...1.0)

            // Darker pores
            ctx.setFillColor(CGColor(red: baseR - 0.05, green: baseG - 0.02, blue: baseB - 0.01, alpha: 0.2))
            ctx.fill(CGRect(x: x, y: y, width: len, height: w))
        }

        // Layer 2: Horizontal grain lines
        var y: CGFloat = 0
        while y < CGFloat(height) {
            let thickness = CGFloat.random(in: 1...6)
            let brightness = CGFloat.random(in: -0.08...0.06)

            ctx.setFillColor(CGColor(
                red: baseR + brightness,
                green: baseG + brightness * 0.8,
                blue: baseB + brightness * 0.5,
                alpha: 0.5
            ))
            ctx.fill(CGRect(x: 0, y: y, width: CGFloat(width), height: thickness))

            y += thickness + CGFloat.random(in: 0.5...3.0)
        }

        // Layer 3: Prominent growth rings (Dark streaks)
        // Derive streak color from base -- darker variant
        let streakR = max(baseR * 0.375, 0.02)
        let streakG = max(baseG * 0.22, 0.02)
        let streakB = max(baseB * 0.25, 0.01)

        for _ in 0..<140 {
            let yPos = CGFloat.random(in: 0...CGFloat(height))
            let thickness = CGFloat.random(in: 1.0...4.0)

            ctx.setStrokeColor(CGColor(red: streakR, green: streakG, blue: streakB, alpha: 0.5))
            ctx.setLineWidth(thickness)

            // Organic wavy line
            ctx.move(to: CGPoint(x: 0, y: yPos))
            let segments = 16
            let waveAmp = CGFloat.random(in: 3...15)
            let phase = CGFloat.random(in: 0...10)

            for s in 1...segments {
                let sx = CGFloat(s) * CGFloat(width) / CGFloat(segments)
                let sy = yPos + sin(Double(s) + Double(phase)) * waveAmp
                ctx.addLine(to: CGPoint(x: sx, y: sy))
            }
            ctx.strokePath()
        }

        let image = ctx.makeImage()
        if let image { imageCache[cacheKey] = image }
        return image
    }

    /// Generates a wood roughness map -- tailored for a varnished look.
    static func woodRoughness(width: Int = 1024, height: Int = 1024) -> CGImage? {
        let cacheKey = "wood_roughness"
        if let cached = imageCache[cacheKey] { return cached }

        guard let ctx = makeContext(width: width, height: height) else { return nil }

        // Medium-low roughness base (The wood itself has some texture)
        ctx.setFillColor(CGColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0))
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // Grain patterns affect roughness (pores in the wood)
        for _ in 0..<500 {
            let y = CGFloat.random(in: 0...CGFloat(height))
            let h = CGFloat.random(in: 1...3)
            // Pores are rougher (lighter)
            ctx.setFillColor(CGColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 0.3))
            ctx.fill(CGRect(x: 0, y: y, width: CGFloat(width), height: h))
        }

        let image = ctx.makeImage()
        if let image { imageCache[cacheKey] = image }
        return image
    }

    // MARK: - Card Paper Texture

    /// Generates a subtle paper grain noise overlay for card faces.
    static func paperGrain(width: Int = 450, height: Int = 630) -> CGImage? {
        guard let ctx = makeContext(width: width, height: height) else { return nil }

        // Cream base matching card face color
        ctx.setFillColor(CGColor(red: 0.97, green: 0.95, blue: 0.91, alpha: 1.0))
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // Fine speckle noise -- simulates paper fiber
        for _ in 0..<12000 {
            let x = CGFloat.random(in: 0...CGFloat(width))
            let y = CGFloat.random(in: 0...CGFloat(height))
            let size = CGFloat.random(in: 0.3...1.0)
            let v = CGFloat.random(in: 0.88...0.98)
            ctx.setFillColor(CGColor(red: v, green: v * 0.98, blue: v * 0.94, alpha: 0.15))
            ctx.fillEllipse(in: CGRect(x: x, y: y, width: size, height: size))
        }

        return ctx.makeImage()
    }

    // MARK: - Card Wear Overlay Textures

    /// Generates a wear overlay texture for a given wear level.
    /// Returns a semi-transparent image with darkened corners, edge scuffs, and scratches.
    /// Cached by wear level for reuse across cards.
    static func cardWearOverlay(level: WearLevel, intensity: CGFloat = 1.0, width: Int = 450, height: Int = 630) -> CGImage? {
        guard level != .none else { return nil }

        let cacheKey = "card_wear_\(level.rawValue)_\(String(format: "%.2f", intensity))"
        if let cached = imageCache[cacheKey] { return cached }

        guard let ctx = makeContext(width: width, height: height) else { return nil }

        // Start fully transparent
        ctx.clear(CGRect(x: 0, y: 0, width: width, height: height))

        let w = CGFloat(width)
        let h = CGFloat(height)

        // Scale effects based on wear level
        let levelFactor = CGFloat(level.rawValue) / 4.0 * intensity

        // Layer 1: Corner darkening (accumulated finger grime)
        let cornerRadius = w * 0.25 * levelFactor
        let cornerAlpha = 0.08 * levelFactor
        let corners: [(CGFloat, CGFloat)] = [
            (0, 0), (w, 0), (0, h), (w, h)
        ]
        for (cx, cy) in corners {
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    CGColor(red: 0.15, green: 0.12, blue: 0.08, alpha: cornerAlpha),
                    CGColor(red: 0.15, green: 0.12, blue: 0.08, alpha: 0.0)
                ] as CFArray,
                locations: [0.0, 1.0]
            )!
            ctx.drawRadialGradient(
                gradient,
                startCenter: CGPoint(x: cx, y: cy),
                startRadius: 0,
                endCenter: CGPoint(x: cx, y: cy),
                endRadius: cornerRadius,
                options: []
            )
        }

        // Layer 2: Edge darkening (wear along the perimeter)
        let edgeWidth = 8.0 * levelFactor
        let edgeAlpha = 0.06 * levelFactor
        ctx.setFillColor(CGColor(red: 0.2, green: 0.15, blue: 0.1, alpha: edgeAlpha))
        // Top edge
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: edgeWidth))
        // Bottom edge
        ctx.fill(CGRect(x: 0, y: h - edgeWidth, width: w, height: edgeWidth))
        // Left edge
        ctx.fill(CGRect(x: 0, y: 0, width: edgeWidth, height: h))
        // Right edge
        ctx.fill(CGRect(x: w - edgeWidth, y: 0, width: edgeWidth, height: h))

        // Layer 3: Random scratches
        let scratchCount = Int(20 * levelFactor * levelFactor)
        for _ in 0..<scratchCount {
            let startX = CGFloat.random(in: 0...w)
            let startY = CGFloat.random(in: 0...h)
            let length = CGFloat.random(in: 10...60) * levelFactor
            let angle = CGFloat.random(in: 0...(.pi * 2))
            let endX = startX + cos(angle) * length
            let endY = startY + sin(angle) * length

            ctx.setStrokeColor(CGColor(
                red: 0.3, green: 0.25, blue: 0.2,
                alpha: CGFloat.random(in: 0.03...0.08) * levelFactor
            ))
            ctx.setLineWidth(CGFloat.random(in: 0.5...1.5))
            ctx.move(to: CGPoint(x: startX, y: startY))
            ctx.addLine(to: CGPoint(x: endX, y: endY))
            ctx.strokePath()
        }

        // Layer 4: Surface scuff marks (larger smudge areas)
        let scuffCount = Int(5 * levelFactor)
        for _ in 0..<scuffCount {
            let cx = CGFloat.random(in: w * 0.1...w * 0.9)
            let cy = CGFloat.random(in: h * 0.1...h * 0.9)
            let radius = CGFloat.random(in: 8...25) * levelFactor
            ctx.setFillColor(CGColor(
                red: 0.25, green: 0.2, blue: 0.15,
                alpha: CGFloat.random(in: 0.02...0.05) * levelFactor
            ))
            ctx.fillEllipse(in: CGRect(
                x: cx - radius, y: cy - radius,
                width: radius * 2, height: radius * 2
            ))
        }

        let image = ctx.makeImage()
        if let image { imageCache[cacheKey] = image }
        return image
    }

    /// Pre-generates and caches all wear overlay textures.
    static func preloadWearOverlays(intensity: CGFloat = 1.0) {
        for level in WearLevel.allCases {
            _ = cardWearOverlay(level: level, intensity: intensity)
        }
    }

    // MARK: - Normal Map Generation

    /// Generates a simple felt normal map with random micro-bumps.
    static func feltNormal(width: Int = 1024, height: Int = 1024) -> CGImage? {
        let cacheKey = "felt_normal"
        if let cached = imageCache[cacheKey] { return cached }

        guard let ctx = makeContext(width: width, height: height) else { return nil }

        // Flat normal base: RGB (128, 128, 255)
        ctx.setFillColor(CGColor(red: 0.5, green: 0.5, blue: 1.0, alpha: 1.0))
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // Random micro-bumps -- slight deviations from flat
        for _ in 0..<10000 {
            let x = CGFloat.random(in: 0...CGFloat(width))
            let y = CGFloat.random(in: 0...CGFloat(height))
            let size = CGFloat.random(in: 1...3)
            let nx = 0.5 + CGFloat.random(in: -0.1...0.1)
            let ny = 0.5 + CGFloat.random(in: -0.1...0.1)
            ctx.setFillColor(CGColor(red: nx, green: ny, blue: 0.98, alpha: 0.2))
            ctx.fillEllipse(in: CGRect(x: x, y: y, width: size, height: size))
        }

        let image = ctx.makeImage()
        if let image { imageCache[cacheKey] = image }
        return image
    }

    /// Generates a wood normal map with horizontal grain direction.
    static func woodNormal(width: Int = 1024, height: Int = 1024) -> CGImage? {
        let cacheKey = "wood_normal"
        if let cached = imageCache[cacheKey] { return cached }

        guard let ctx = makeContext(width: width, height: height) else { return nil }

        // Flat normal base
        ctx.setFillColor(CGColor(red: 0.5, green: 0.5, blue: 1.0, alpha: 1.0))
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // Grain ridges
        var y: CGFloat = 0
        while y < CGFloat(height) {
            let thickness = CGFloat.random(in: 1...3)
            // Ridge: normal tilts slightly in Y
            let ny = 0.5 + CGFloat.random(in: -0.15...0.15)
            ctx.setFillColor(CGColor(red: 0.5, green: ny, blue: 0.9, alpha: 0.35))
            ctx.fill(CGRect(x: 0, y: y, width: CGFloat(width), height: thickness))
            y += thickness + CGFloat.random(in: 2...6)
        }

        let image = ctx.makeImage()
        if let image { imageCache[cacheKey] = image }
        return image
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

    private static func makeContext(width: Int, height: Int) -> CGContext? {
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
