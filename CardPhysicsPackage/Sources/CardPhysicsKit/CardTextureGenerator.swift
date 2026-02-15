import SwiftUI
import RealityKit

@MainActor
final class CardTextureGenerator {
    static let shared = CardTextureGenerator()

    private var cache: [String: TextureResource] = [:]
    private var cardBackTexture: TextureResource?
    private var paperGrainImage: CGImage?

    var designConfig = CardDesignConfiguration()

    // Render at exactly the CardView.large size so texture fills the 3D card with no padding
    private let renderWidth: CGFloat = 90
    private let renderHeight: CGFloat = 126

    private init() {
        // Pre-generate paper grain overlay once
        paperGrainImage = ProceduralTextureGenerator.paperGrain(
            width: Int(renderWidth * 5.0),
            height: Int(renderHeight * 5.0)
        )
    }

    func texture(for card: Card) -> TextureResource? {
        let faceStyle = designConfig.faceStyle

        // Custom image faces: composite photo + rank/suit overlay per card
        if faceStyle == .customImage || faceStyle == .selfie {
            let filename = designConfig.activeFaceImageFilename
            // Key includes card identity so each card gets its own rank/suit overlay
            let key = "custom_face_\(faceStyle.rawValue)_\(filename ?? "none")_\(card.suit.name)_\(card.rank.name)"
            if let cached = cache[key] {
                return cached
            }
            guard let filename, let photoImage = loadAndCropCustomImage(filename: filename) else {
                return renderStyledTexture(for: card, style: .classic)
            }
            // Render the rank/suit overlay (transparent background with corner indices)
            let overlayImage = renderCardFace(card, style: faceStyle)
            // Composite: photo underneath, overlay on top
            let composited = compositeOverlay(overlayImage, over: photoImage) ?? photoImage
            let finalImage = applyRoundedCornerMask(to: composited) ?? composited
            let texture = try? TextureResource(
                image: finalImage,
                options: .init(semantic: .color)
            )
            if let texture {
                cache[key] = texture
            }
            return texture
        }

        return renderStyledTexture(for: card, style: faceStyle)
    }

    private func renderStyledTexture(for card: Card, style: CardFaceStyle) -> TextureResource? {
        let key = "\(style.rawValue)_\(card.suit.name)_\(card.rank.name)"
        if let cached = cache[key] {
            return cached
        }

        guard let cgImage = renderCardFace(card, style: style) else { return nil }

        let grainedImage = compositePaperGrain(over: cgImage) ?? cgImage
        let finalImage = applyRoundedCornerMask(to: grainedImage) ?? grainedImage

        let texture = try? TextureResource(
            image: finalImage,
            options: .init(semantic: .color)
        )
        if let texture {
            cache[key] = texture
        }
        return texture
    }

    func backTexture() -> TextureResource? {
        let backStyle = designConfig.backStyle

        // Custom image backs bypass the SwiftUI rendering pipeline
        if backStyle == .customImage || backStyle == .selfie {
            let filename = designConfig.activeBackImageFilename
            let key = "custom_back_\(backStyle.rawValue)_\(filename ?? "none")"
            if let cached = cache[key] {
                return cached
            }
            guard let filename, let cgImage = loadAndCropCustomImage(filename: filename) else {
                return renderStyledBackTexture(style: .classicMaroon)
            }
            let finalImage = applyRoundedCornerMask(to: cgImage) ?? cgImage
            let texture = try? TextureResource(
                image: finalImage,
                options: .init(semantic: .color)
            )
            if let texture {
                cache[key] = texture
            }
            return texture
        }

        return renderStyledBackTexture(style: backStyle)
    }

    private func renderStyledBackTexture(style: CardBackStyle) -> TextureResource? {
        let key = "back_\(style.rawValue)"
        if let cached = cache[key] {
            return cached
        }

        guard let rawImage = renderCardBack(style: style) else { return nil }
        let cgImage = applyRoundedCornerMask(to: rawImage) ?? rawImage

        let texture = try? TextureResource(
            image: cgImage,
            options: .init(semantic: .color)
        )
        if let texture {
            cache[key] = texture
        }
        return texture
    }

    /// Returns a card face texture composited with a wear overlay for the given level.
    func textureWithWear(for card: Card, wearLevel: WearLevel, intensity: CGFloat = 1.0) -> TextureResource? {
        guard wearLevel != .none else { return texture(for: card) }

        let faceStyle = designConfig.faceStyle
        let key = "worn_\(faceStyle.rawValue)_\(card.suit.name)_\(card.rank.name)_\(wearLevel.rawValue)_\(String(format: "%.2f", intensity))"
        if let cached = cache[key] { return cached }

        // Get the base card face image
        guard let baseImage = renderCardFace(card, style: faceStyle) else { return nil }
        let grainedImage = compositePaperGrain(over: baseImage) ?? baseImage

        // Composite wear overlay
        guard let wearOverlay = ProceduralTextureGenerator.cardWearOverlay(
            level: wearLevel, intensity: intensity
        ) else {
            return texture(for: card)
        }

        let wornImage = compositeOverlay(wearOverlay, over: grainedImage) ?? grainedImage
        let finalImage = applyRoundedCornerMask(to: wornImage) ?? wornImage

        let texture = try? TextureResource(
            image: finalImage,
            options: .init(semantic: .color)
        )
        if let texture {
            cache[key] = texture
        }
        return texture
    }

    /// Clears all cached textures, forcing regeneration on next access
    func invalidateAll() {
        cache.removeAll()
        cardBackTexture = nil
    }

    // MARK: - Rendering

    private func renderCardFace(_ card: Card, style: CardFaceStyle) -> CGImage? {
        let view = CardView(card: card, isFaceUp: true, size: .large, faceStyle: style)
            .frame(width: renderWidth, height: renderHeight)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 5.0
        return renderer.cgImage
    }

    private func renderCardBack(style: CardBackStyle) -> CGImage? {
        let dummyCard = Card(suit: .spades, rank: .ace)
        let view = CardView(card: dummyCard, isFaceUp: false, size: .large, backStyle: style)
            .frame(width: renderWidth, height: renderHeight)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 5.0
        return renderer.cgImage
    }

    // MARK: - Custom Image Pipeline

    /// Loads a custom image from CardImageStorage, crops to card proportions, and scales to render size
    func loadAndCropCustomImage(filename: String) -> CGImage? {
        let url = CardImageStorage.imageURL(for: filename)
        guard let data = try? Data(contentsOf: url),
              let uiImage = UIImage(data: data),
              let source = uiImage.cgImage else {
            return nil
        }

        let targetWidth = Int(renderWidth * 5.0)  // 450
        let targetHeight = Int(renderHeight * 5.0) // 630

        // Aspect-fill crop to card proportions (5:7)
        let srcW = CGFloat(source.width)
        let srcH = CGFloat(source.height)
        let targetAspect = CGFloat(targetWidth) / CGFloat(targetHeight)
        let srcAspect = srcW / srcH

        let cropRect: CGRect
        if srcAspect > targetAspect {
            // Source is wider — crop sides
            let cropW = srcH * targetAspect
            let x = (srcW - cropW) / 2
            cropRect = CGRect(x: x, y: 0, width: cropW, height: srcH)
        } else {
            // Source is taller — crop top/bottom
            let cropH = srcW / targetAspect
            let y = (srcH - cropH) / 2
            cropRect = CGRect(x: 0, y: y, width: srcW, height: cropH)
        }

        guard let cropped = source.cropping(to: cropRect) else { return nil }

        // Scale to target size
        guard let ctx = CGContext(
            data: nil,
            width: targetWidth,
            height: targetHeight,
            bitsPerComponent: 8,
            bytesPerRow: targetWidth * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        ctx.interpolationQuality = .high
        ctx.draw(cropped, in: CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight))

        return ctx.makeImage()
    }

    // MARK: - Image Processing

    private func applyRoundedCornerMask(to image: CGImage) -> CGImage? {
        let w = image.width
        let h = image.height

        guard let ctx = CGContext(
            data: nil,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: w * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        let rect = CGRect(x: 0, y: 0, width: w, height: h)
        let cornerRadius: CGFloat = 50.0
        let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

        ctx.addPath(path)
        ctx.clip()
        ctx.draw(image, in: rect)

        return ctx.makeImage()
    }

    /// Composites a transparent overlay (rank/suit indicators) on top of a base image (custom photo)
    private func compositeOverlay(_ overlay: CGImage?, over baseImage: CGImage) -> CGImage? {
        guard let overlay else { return nil }

        let w = baseImage.width
        let h = baseImage.height

        guard let ctx = CGContext(
            data: nil,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: w * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        let rect = CGRect(x: 0, y: 0, width: w, height: h)

        // Draw the photo
        ctx.draw(baseImage, in: rect)

        // Draw the overlay (rank/suit with transparent background) on top
        ctx.draw(overlay, in: rect)

        return ctx.makeImage()
    }

    private func compositePaperGrain(over cardImage: CGImage) -> CGImage? {
        guard let grain = paperGrainImage else { return nil }

        let w = cardImage.width
        let h = cardImage.height

        guard let ctx = CGContext(
            data: nil,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: w * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        let rect = CGRect(x: 0, y: 0, width: w, height: h)

        ctx.draw(cardImage, in: rect)

        ctx.setAlpha(0.08)
        ctx.setBlendMode(.multiply)
        ctx.draw(grain, in: rect)

        return ctx.makeImage()
    }
}
