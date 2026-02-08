import SwiftUI
import RealityKit

@MainActor
final class CardTextureGenerator {
    static let shared = CardTextureGenerator()

    private var cache: [String: TextureResource] = [:]
    private var cardBackTexture: TextureResource?
    private var paperGrainImage: CGImage?

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
        let key = "\(card.suit.name)_\(card.rank.name)"
        if let cached = cache[key] {
            return cached
        }

        guard let cgImage = renderCardFace(card) else { return nil }

        // Composite paper grain over the card face
        let grainedImage = compositePaperGrain(over: cgImage) ?? cgImage
        // Apply rounded-rect alpha mask for clean 3D corners
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
        if let cached = cardBackTexture {
            return cached
        }

        guard let rawImage = renderCardBack() else { return nil }
        let cgImage = applyRoundedCornerMask(to: rawImage) ?? rawImage

        let texture = try? TextureResource(
            image: cgImage,
            options: .init(semantic: .color)
        )
        cardBackTexture = texture
        return texture
    }

    private func renderCardFace(_ card: Card) -> CGImage? {
        let view = CardView(card: card, isFaceUp: true, size: .large)
            .frame(width: renderWidth, height: renderHeight)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 5.0
        return renderer.cgImage
    }

    private func renderCardBack() -> CGImage? {
        let dummyCard = Card(suit: .spades, rank: .ace)
        let view = CardView(card: dummyCard, isFaceUp: false, size: .large)
            .frame(width: renderWidth, height: renderHeight)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 5.0
        return renderer.cgImage
    }

    /// Masks a card image with a rounded-rect alpha so corners become transparent.
    /// Combined with `opacityThreshold` on the 3D material, this gives clean rounded corners.
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
        // Corner radius: CardView.large uses 10pt at 5x scale = 50px
        let cornerRadius: CGFloat = 50.0
        let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

        // Clip to rounded rect, then draw the image
        ctx.addPath(path)
        ctx.clip()
        ctx.draw(image, in: rect)

        return ctx.makeImage()
    }

    /// Composites the paper grain texture over a card face image at low opacity.
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

        // Draw card face
        ctx.draw(cardImage, in: rect)

        // Overlay paper grain at low opacity for subtle texture
        ctx.setAlpha(0.08)
        ctx.setBlendMode(.multiply)
        ctx.draw(grain, in: rect)

        return ctx.makeImage()
    }
}
