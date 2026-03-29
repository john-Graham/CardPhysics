import SwiftUI

// MARK: - Card Face Style Views

extension CardView {

    // MARK: Classic Face (original design)

    var classicFront: some View {
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

    var modernFront: some View {
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

    var minimalFront: some View {
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

    var customImageOverlay: some View {
        ZStack {
            // Transparent background -- the photo is drawn underneath at the texture level
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

    var boldFront: some View {
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

    var bicycleFront: some View {
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

    var frenchFront: some View {
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
}
