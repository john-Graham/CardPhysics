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

    // MARK: Bicycle/Poker Style (Traditional US playing cards)

    private var bicycleFront: some View {
        ZStack {
            // Pure white background like real playing cards
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(Color.white)

            // Subtle border
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .strokeBorder(
                    Color(red: 0.85, green: 0.85, blue: 0.85),
                    lineWidth: 1
                )

            // Traditional pip layout in center
            pipLayout
                .foregroundColor(suitColor)

            // Corner indices: top-left
            VStack(spacing: -3) {
                Text(card.rank.symbol)
                    .font(.system(size: size.fontSize * 0.5, weight: .bold, design: .serif))
                Text(card.suit.rawValue)
                    .font(.system(size: size.fontSize * 0.5))
            }
            .foregroundColor(suitColor)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.leading, size.width * 0.06)
            .padding(.top, size.height * 0.03)

            // Corner indices: bottom-right (rotated 180)
            VStack(spacing: -3) {
                Text(card.rank.symbol)
                    .font(.system(size: size.fontSize * 0.5, weight: .bold, design: .serif))
                Text(card.suit.rawValue)
                    .font(.system(size: size.fontSize * 0.5))
            }
            .foregroundColor(suitColor)
            .rotationEffect(.degrees(180))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(.trailing, size.width * 0.06)
            .padding(.bottom, size.height * 0.03)
        }
    }

    // MARK: French Style (Classic European playing cards)

    private var frenchFront: some View {
        ZStack {
            // Slightly off-white/ivory background
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(Color(red: 0.99, green: 0.98, blue: 0.96))

            // Delicate border
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .strokeBorder(suitColor.opacity(0.2), lineWidth: 1.5)

            // Center pip layout (French cards are more minimalist)
            pipLayoutFrench
                .foregroundColor(suitColor)

            // Corner indices with French-style serif font
            VStack(spacing: -2) {
                Text(card.rank.symbol)
                    .font(.system(size: size.fontSize * 0.48, weight: .semibold, design: .serif))
                Text(card.suit.rawValue)
                    .font(.system(size: size.fontSize * 0.42))
            }
            .foregroundColor(suitColor)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.leading, size.width * 0.07)
            .padding(.top, size.height * 0.035)

            // Bottom-right corner
            VStack(spacing: -2) {
                Text(card.rank.symbol)
                    .font(.system(size: size.fontSize * 0.48, weight: .semibold, design: .serif))
                Text(card.suit.rawValue)
                    .font(.system(size: size.fontSize * 0.42))
            }
            .foregroundColor(suitColor)
            .rotationEffect(.degrees(180))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(.trailing, size.width * 0.07)
            .padding(.bottom, size.height * 0.035)
        }
    }

    // MARK: - Pip Layouts (Traditional playing card pip patterns)

    private var pipLayout: some View {
        let pipSize = size.fontSize * 0.85
        let spacing = size.height * 0.15

        return Group {
            switch card.rank.value {
            case 9:
                // 9: Classic 3x3 grid with center missing
                VStack(spacing: spacing) {
                    HStack(spacing: size.width * 0.25) {
                        pip(size: pipSize)
                        pip(size: pipSize)
                    }
                    HStack(spacing: size.width * 0.25) {
                        pip(size: pipSize)
                        pip(size: pipSize)
                    }
                    pip(size: pipSize)
                    HStack(spacing: size.width * 0.25) {
                        pip(size: pipSize)
                        pip(size: pipSize)
                    }
                }

            case 10:
                // 10: Two columns with center pip
                VStack(spacing: spacing * 0.7) {
                    HStack(spacing: size.width * 0.25) {
                        pip(size: pipSize)
                        pip(size: pipSize)
                    }
                    pip(size: pipSize)
                    HStack(spacing: size.width * 0.25) {
                        pip(size: pipSize)
                        pip(size: pipSize)
                    }
                    pip(size: pipSize, flipped: true)
                    HStack(spacing: size.width * 0.25) {
                        pip(size: pipSize, flipped: true)
                        pip(size: pipSize, flipped: true)
                    }
                }

            case 11, 12, 13:
                // Jack, Queen, King: Letter only (no actual court card artwork)
                VStack(spacing: 4) {
                    Text(card.rank.symbol)
                        .font(.system(size: size.fontSize * 2.2, weight: .bold, design: .serif))
                    Text(card.suit.rawValue)
                        .font(.system(size: size.fontSize * 1.2))
                }

            case 14:
                // Ace: Single large centered pip
                pip(size: size.fontSize * 2.0)

            default:
                // Fallback: centered rank + suit
                VStack(spacing: 2) {
                    Text(card.rank.symbol)
                        .font(.system(size: size.fontSize * 1.2, weight: .bold))
                    Text(card.suit.rawValue)
                        .font(.system(size: size.fontSize * 1.4))
                }
            }
        }
    }

    private var pipLayoutFrench: some View {
        let pipSize = size.fontSize * 0.75
        let spacing = size.height * 0.16

        return Group {
            switch card.rank.value {
            case 9:
                // French 9: Tighter spacing
                VStack(spacing: spacing * 0.9) {
                    HStack(spacing: size.width * 0.22) {
                        pip(size: pipSize)
                        pip(size: pipSize)
                    }
                    pip(size: pipSize)
                    HStack(spacing: size.width * 0.22) {
                        pip(size: pipSize)
                        pip(size: pipSize)
                    }
                    pip(size: pipSize, flipped: true)
                    HStack(spacing: size.width * 0.22) {
                        pip(size: pipSize, flipped: true)
                        pip(size: pipSize, flipped: true)
                    }
                }

            case 10:
                // French 10: Elegant vertical arrangement
                VStack(spacing: spacing * 0.65) {
                    HStack(spacing: size.width * 0.22) {
                        pip(size: pipSize)
                        pip(size: pipSize)
                    }
                    pip(size: pipSize)
                    HStack(spacing: size.width * 0.22) {
                        pip(size: pipSize)
                        pip(size: pipSize)
                    }
                    pip(size: pipSize, flipped: true)
                    HStack(spacing: size.width * 0.22) {
                        pip(size: pipSize, flipped: true)
                        pip(size: pipSize, flipped: true)
                    }
                }

            case 11, 12, 13:
                // French court cards: Elegant letter with suit
                VStack(spacing: 3) {
                    Text(card.rank.symbol)
                        .font(.system(size: size.fontSize * 2.0, weight: .semibold, design: .serif))
                    Text(card.suit.rawValue)
                        .font(.system(size: size.fontSize * 1.1))
                }

            case 14:
                // French Ace: Refined single pip
                pip(size: size.fontSize * 1.8)

            default:
                VStack(spacing: 2) {
                    Text(card.rank.symbol)
                        .font(.system(size: size.fontSize * 1.1, weight: .semibold))
                    Text(card.suit.rawValue)
                        .font(.system(size: size.fontSize * 1.2))
                }
            }
        }
    }

    /// Helper to draw a single suit pip
    private func pip(size: CGFloat, flipped: Bool = false) -> some View {
        Text(card.suit.rawValue)
            .font(.system(size: size))
            .rotationEffect(.degrees(flipped ? 180 : 0))
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
