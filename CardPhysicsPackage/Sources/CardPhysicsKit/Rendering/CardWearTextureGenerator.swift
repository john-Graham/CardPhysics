import CoreGraphics

// MARK: - Card Paper & Wear Textures

extension ProceduralTextureGenerator {

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
}
