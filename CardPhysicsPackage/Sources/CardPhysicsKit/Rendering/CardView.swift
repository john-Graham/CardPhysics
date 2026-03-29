import SwiftUI

public struct CardView: View {
    public let card: Card
    public var isFaceUp: Bool = true
    public var isHighlighted: Bool = false
    public var isPlayable: Bool = true
    public var size: CardSize = .medium
    public var faceStyle: CardFaceStyle = .classic
    public var backStyle: CardBackStyle = .classicMaroon

    public init(
        card: Card,
        isFaceUp: Bool = true,
        isHighlighted: Bool = false,
        isPlayable: Bool = true,
        size: CardSize = .medium,
        faceStyle: CardFaceStyle = .classic,
        backStyle: CardBackStyle = .classicMaroon
    ) {
        self.card = card
        self.isFaceUp = isFaceUp
        self.isHighlighted = isHighlighted
        self.isPlayable = isPlayable
        self.size = size
        self.faceStyle = faceStyle
        self.backStyle = backStyle
    }

    public enum CardSize {
        case small, medium, large

        var width: CGFloat {
            switch self {
            case .small: return 50
            case .medium: return 70
            case .large: return 90
            }
        }

        var height: CGFloat {
            width * 1.4
        }

        var fontSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 20
            case .large: return 28
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .small: return 6
            case .medium: return 8
            case .large: return 10
            }
        }
    }

    public var body: some View {
        ZStack {
            if isFaceUp {
                cardFront
            } else {
                cardBack
            }
        }
        .frame(width: size.width, height: size.height)
        .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
        .opacity(isPlayable ? 1.0 : 0.5)
        .overlay(
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .stroke(isHighlighted ? Color.yellow : Color.clear, lineWidth: 3)
        )
        .accessibilityIdentifier("card_\(card.suit.name)_\(card.rank.name)")
    }

    // MARK: - Card Front

    @ViewBuilder
    private var cardFront: some View {
        switch faceStyle {
        case .classic:
            classicFront
        case .modern:
            modernFront
        case .minimal:
            minimalFront
        case .bold:
            boldFront
        case .bicycle:
            bicycleFront
        case .french:
            frenchFront
        case .customImage, .selfie:
            customImageOverlay
        }
    }

    // MARK: - Card Back

    private var cardBack: some View {
        Group {
            switch backStyle {
            case .bicycleRed, .bicycleBlue:
                bicycleBack
            case .french:
                frenchBack
            default:
                classicBack
            }
        }
    }

    // MARK: - Shared Helpers

    /// Suit color used across face styles
    var suitColor: Color {
        switch card.suit.color {
        case .red: return Color(red: 0.85, green: 0.05, blue: 0.05)
        case .black: return Color(red: 0.10, green: 0.10, blue: 0.10)
        }
    }

    /// Helper to draw a single suit pip
    func pip(size: CGFloat, flipped: Bool = false) -> some View {
        Text(card.suit.rawValue)
            .font(.system(size: size))
            .rotationEffect(.degrees(flipped ? 180 : 0))
    }
}
