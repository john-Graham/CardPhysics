import CoreGraphics

// MARK: - Wood Grain Material

extension ProceduralTextureGenerator {

    /// Clears only wood-related cached textures.
    static func clearWoodCache() {
        imageCache = imageCache.filter { !$0.key.hasPrefix("wood_albedo_") }
    }

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
}
