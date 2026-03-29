import CoreGraphics

// MARK: - Felt Fabric Material

extension ProceduralTextureGenerator {

    /// Clears only felt-related cached textures.
    static func clearFeltCache() {
        imageCache = imageCache.filter { !$0.key.hasPrefix("felt_albedo_") }
    }

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
}
