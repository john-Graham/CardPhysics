import CoreGraphics
import RealityKit

/// Generates procedural PBR textures for the game table materials using CoreGraphics.
@MainActor
enum ProceduralTextureGenerator {

    // MARK: - Felt Fabric Texture

    /// Generates a rich billiard green felt albedo texture with visible fiber noise.
    static func feltAlbedo(width: Int = 1024, height: Int = 1024) -> CGImage? {
        guard let ctx = makeContext(width: width, height: height) else { return nil }

        // Base felt color — Deeper Billiard Green
        let baseR: CGFloat = 0.02
        let baseG: CGFloat = 0.18
        let baseB: CGFloat = 0.06
        
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
        // Instead of long strokes, we use thousands of tiny specs to create a soft noisy look
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

        return ctx.makeImage()
    }

    /// Generates a felt roughness map — mostly rough with slight variation.
    static func feltRoughness(width: Int = 1024, height: Int = 1024) -> CGImage? {
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

        return ctx.makeImage()
    }

    // MARK: - Wood Grain Texture

    /// Generates a rich Mahogany/Cherry wood albedo texture.
    static func woodAlbedo(width: Int = 1024, height: Int = 1024) -> CGImage? {
        guard let ctx = makeContext(width: width, height: height) else { return nil }

        // Base Mahogany color (Warm reddish brown, matched to sample render)
        let baseR: CGFloat = 0.40
        let baseG: CGFloat = 0.18
        let baseB: CGFloat = 0.08
        
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
        for _ in 0..<140 {
            let yPos = CGFloat.random(in: 0...CGFloat(height))
            let thickness = CGFloat.random(in: 1.0...4.0)
            
            // Deep brown/black streaks
            ctx.setStrokeColor(CGColor(red: 0.15, green: 0.04, blue: 0.02, alpha: 0.5))
            ctx.setLineWidth(thickness)

            // Organic wavy line
            ctx.move(to: CGPoint(x: 0, y: yPos))
            let segments = 16
            let waveAmp = CGFloat.random(in: 3...15)
            // Phase shift to prevent waves from aligning
            let phase = CGFloat.random(in: 0...10)
            
            for s in 1...segments {
                let sx = CGFloat(s) * CGFloat(width) / CGFloat(segments)
                let sy = yPos + sin(Double(s) + Double(phase)) * waveAmp
                ctx.addLine(to: CGPoint(x: sx, y: sy))
            }
            ctx.strokePath()
        }

        return ctx.makeImage()
    }

    /// Generates a wood roughness map — tailored for a varnished look.
    static func woodRoughness(width: Int = 1024, height: Int = 1024) -> CGImage? {
        guard let ctx = makeContext(width: width, height: height) else { return nil }

        // Medium-low roughness base (The wood itself has some texture)
        // But the clearcoat will handle the primary gloss. 
        // We want the underlying wood to capture some diffuse scattering.
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

        return ctx.makeImage()
    }

    // MARK: - Card Paper Texture

    /// Generates a subtle paper grain noise overlay for card faces.
    static func paperGrain(width: Int = 450, height: Int = 630) -> CGImage? {
        guard let ctx = makeContext(width: width, height: height) else { return nil }

        // Cream base matching card face color
        ctx.setFillColor(CGColor(red: 0.97, green: 0.95, blue: 0.91, alpha: 1.0))
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // Fine speckle noise — simulates paper fiber
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

    // MARK: - Normal Map Generation

    /// Generates a simple felt normal map with random micro-bumps.
    static func feltNormal(width: Int = 1024, height: Int = 1024) -> CGImage? {
        guard let ctx = makeContext(width: width, height: height) else { return nil }

        // Flat normal base: RGB (128, 128, 255)
        ctx.setFillColor(CGColor(red: 0.5, green: 0.5, blue: 1.0, alpha: 1.0))
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // Random micro-bumps — slight deviations from flat
        for _ in 0..<10000 {
            let x = CGFloat.random(in: 0...CGFloat(width))
            let y = CGFloat.random(in: 0...CGFloat(height))
            let size = CGFloat.random(in: 1...3)
            let nx = 0.5 + CGFloat.random(in: -0.1...0.1)
            let ny = 0.5 + CGFloat.random(in: -0.1...0.1)
            ctx.setFillColor(CGColor(red: nx, green: ny, blue: 0.98, alpha: 0.2))
            ctx.fillEllipse(in: CGRect(x: x, y: y, width: size, height: size))
        }

        return ctx.makeImage()
    }

    /// Generates a wood normal map with horizontal grain direction.
    static func woodNormal(width: Int = 1024, height: Int = 1024) -> CGImage? {
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

        return ctx.makeImage()
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