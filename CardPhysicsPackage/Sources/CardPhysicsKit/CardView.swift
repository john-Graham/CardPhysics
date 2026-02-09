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
        case .customImage, .selfie:
            customImageOverlay
        }
    }

    // MARK: Classic Face (original design)

    private var classicFront: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(Color(red: 0.97, green: 0.95, blue: 0.91))

            RoundedRectangle(cornerRadius: size.cornerRadius)
                .strokeBorder(
                    Color(red: 0.75, green: 0.72, blue: 0.68, opacity: 0.5),
                    lineWidth: 1.5
                )

            VStack(spacing: 2) {
                Text(card.rank.symbol)
                    .font(.system(size: size.fontSize * 1.1, weight: .bold))
                Text(card.suit.rawValue)
                    .font(.system(size: size.fontSize * 1.3))
            }
            .foregroundColor(suitColor)

            // Corner indices: top-left
            VStack(spacing: -2) {
                Text(card.rank.symbol)
                    .font(.system(size: size.fontSize * 0.45, weight: .bold))
                Text(card.suit.rawValue)
                    .font(.system(size: size.fontSize * 0.45))
            }
            .foregroundColor(suitColor)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.leading, size.width * 0.08)
            .padding(.top, size.height * 0.04)

            // Corner indices: bottom-right (rotated 180)
            VStack(spacing: -2) {
                Text(card.rank.symbol)
                    .font(.system(size: size.fontSize * 0.45, weight: .bold))
                Text(card.suit.rawValue)
                    .font(.system(size: size.fontSize * 0.45))
            }
            .foregroundColor(suitColor)
            .rotationEffect(.degrees(180))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(.trailing, size.width * 0.08)
            .padding(.bottom, size.height * 0.04)
        }
    }

    // MARK: Modern Face

    private var modernFront: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(Color.white)

            // Thin border
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .strokeBorder(suitColor.opacity(0.3), lineWidth: 1)

            // Large centered pip
            Text(card.suit.rawValue)
                .font(.system(size: size.fontSize * 2.0))
                .foregroundColor(suitColor)

            // Rank above the pip
            Text(card.rank.symbol)
                .font(.system(size: size.fontSize * 0.9, weight: .semibold, design: .rounded))
                .foregroundColor(suitColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.leading, size.width * 0.10)
                .padding(.top, size.height * 0.04)

            // Bottom-right rank (rotated 180)
            Text(card.rank.symbol)
                .font(.system(size: size.fontSize * 0.9, weight: .semibold, design: .rounded))
                .foregroundColor(suitColor)
                .rotationEffect(.degrees(180))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, size.width * 0.10)
                .padding(.bottom, size.height * 0.04)
        }
    }

    // MARK: Minimal Face

    private var minimalFront: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(Color(red: 0.98, green: 0.98, blue: 0.97))

            // Single large rank + suit centered, no corner indices
            VStack(spacing: 0) {
                Text(card.rank.symbol)
                    .font(.system(size: size.fontSize * 1.8, weight: .light))
                Text(card.suit.rawValue)
                    .font(.system(size: size.fontSize * 1.4))
            }
            .foregroundColor(suitColor)
        }
    }

    // MARK: Custom Image Overlay (rank/suit on transparent background, composited over photo)

    private var customImageOverlay: some View {
        ZStack {
            // Transparent background — the photo is drawn underneath at the texture level
            Color.clear

            // Corner indices: top-left with pill background for legibility
            VStack(spacing: -2) {
                Text(card.rank.symbol)
                    .font(.system(size: size.fontSize * 0.5, weight: .bold))
                Text(card.suit.rawValue)
                    .font(.system(size: size.fontSize * 0.5))
            }
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.9), radius: 2, x: 0, y: 1)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black.opacity(0.45))
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.leading, size.width * 0.06)
            .padding(.top, size.height * 0.03)

            // Corner indices: bottom-right (rotated 180)
            VStack(spacing: -2) {
                Text(card.rank.symbol)
                    .font(.system(size: size.fontSize * 0.5, weight: .bold))
                Text(card.suit.rawValue)
                    .font(.system(size: size.fontSize * 0.5))
            }
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.9), radius: 2, x: 0, y: 1)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black.opacity(0.45))
            )
            .rotationEffect(.degrees(180))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(.trailing, size.width * 0.06)
            .padding(.bottom, size.height * 0.03)
        }
    }

    // MARK: Bold Face

    private var boldFront: some View {
        let bgColor: Color = card.suit.color == .red
            ? Color(red: 0.85, green: 0.10, blue: 0.10)
            : Color(red: 0.12, green: 0.12, blue: 0.18)

        return ZStack {
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(bgColor)

            // Thick white border
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .strokeBorder(Color.white.opacity(0.8), lineWidth: 2.5)

            VStack(spacing: 2) {
                Text(card.rank.symbol)
                    .font(.system(size: size.fontSize * 1.3, weight: .black))
                Text(card.suit.rawValue)
                    .font(.system(size: size.fontSize * 1.5))
            }
            .foregroundColor(.white)

            // Corner indices: top-left
            VStack(spacing: -2) {
                Text(card.rank.symbol)
                    .font(.system(size: size.fontSize * 0.45, weight: .bold))
                Text(card.suit.rawValue)
                    .font(.system(size: size.fontSize * 0.45))
            }
            .foregroundColor(.white.opacity(0.9))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.leading, size.width * 0.08)
            .padding(.top, size.height * 0.04)

            // Corner indices: bottom-right
            VStack(spacing: -2) {
                Text(card.rank.symbol)
                    .font(.system(size: size.fontSize * 0.45, weight: .bold))
                Text(card.suit.rawValue)
                    .font(.system(size: size.fontSize * 0.45))
            }
            .foregroundColor(.white.opacity(0.9))
            .rotationEffect(.degrees(180))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(.trailing, size.width * 0.08)
            .padding(.bottom, size.height * 0.04)
        }
    }

    // MARK: - Card Back

    private var cardBack: some View {
        let colors = backStyle.gradientColors

        return ZStack {
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [colors.primary, colors.secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Outer white border
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .strokeBorder(Color.white.opacity(0.7), lineWidth: 2)

            // Inner border rectangle — classic card back pattern
            RoundedRectangle(cornerRadius: size.cornerRadius * 0.6)
                .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                .padding(size.width * 0.08)

            // Diamond center icon
            Image(systemName: "diamond.fill")
                .font(.system(size: size.fontSize * 1.0))
                .foregroundColor(.white.opacity(0.25))
        }
    }

    // MARK: - Suit Colors

    private var suitColor: Color {
        switch card.suit.color {
        case .red: return Color(red: 0.85, green: 0.05, blue: 0.05)
        case .black: return Color(red: 0.10, green: 0.10, blue: 0.10)
        }
    }
}
