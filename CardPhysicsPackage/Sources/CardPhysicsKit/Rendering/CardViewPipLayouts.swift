import SwiftUI

// MARK: - Pip Layouts (Traditional playing card pip patterns)

extension CardView {

    // MARK: Bicycle-style pip layout

    var pipLayout: some View {
        let pipSize = size.fontSize * 0.85
        let spacing = size.height * 0.15

        return Group {
            switch card.rank.rawValue {
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

    // MARK: French-style pip layout

    var pipLayoutFrench: some View {
        let pipSize = size.fontSize * 0.75
        let spacing = size.height * 0.16

        return Group {
            switch card.rank.rawValue {
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
}
