import SwiftUI

// MARK: - Card Face Style Views

extension CardView {

    // MARK: Standard Poker

    var standardPokerFront: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(Color.white)

            RoundedRectangle(cornerRadius: size.cornerRadius)
                .strokeBorder(Color(red: 0.82, green: 0.82, blue: 0.80), lineWidth: 1)

            pipLayout
                .foregroundColor(suitColor)
                .frame(width: size.width * 0.50, height: size.height * 0.54)
                .clipped()

            cornerIndex(fontScale: 0.50, weight: .bold, design: .serif)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.leading, size.width * 0.06)
                .padding(.top, size.height * 0.03)

            cornerIndex(fontScale: 0.50, weight: .bold, design: .serif)
                .rotationEffect(.degrees(180))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, size.width * 0.06)
                .padding(.bottom, size.height * 0.03)
        }
    }

    // MARK: Jumbo Index

    var jumboIndexFront: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(Color.white)

            RoundedRectangle(cornerRadius: size.cornerRadius)
                .strokeBorder(Color(red: 0.74, green: 0.74, blue: 0.72), lineWidth: 1.25)

            Text(card.suit.rawValue)
                .font(.system(size: size.fontSize * 1.35, weight: .regular))
                .foregroundColor(suitColor.opacity(0.95))

            jumboCornerIndex
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.leading, size.width * 0.08)
                .padding(.top, size.height * 0.035)

            jumboCornerIndex
                .rotationEffect(.degrees(180))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, size.width * 0.08)
                .padding(.bottom, size.height * 0.035)
        }
    }

    // MARK: Casino Diamond

    var casinoDiamondFront: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(Color.white)

            casinoDiamondFacePattern
                .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius * 0.65))
                .padding(size.width * 0.08)

            RoundedRectangle(cornerRadius: size.cornerRadius)
                .strokeBorder(Color(red: 0.72, green: 0.72, blue: 0.70), lineWidth: 1)

            RoundedRectangle(cornerRadius: size.cornerRadius * 0.72)
                .strokeBorder(suitColor.opacity(0.28), lineWidth: 1)
                .padding(size.width * 0.06)

            pipLayout
                .foregroundColor(suitColor)
                .frame(width: size.width * 0.46, height: size.height * 0.50)
                .clipped()

            cornerIndex(fontScale: 0.52, weight: .black, design: .default)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.leading, size.width * 0.065)
                .padding(.top, size.height * 0.03)

            cornerIndex(fontScale: 0.52, weight: .black, design: .default)
                .rotationEffect(.degrees(180))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, size.width * 0.065)
                .padding(.bottom, size.height * 0.03)
        }
    }

    // MARK: Custom Image Overlay

    var customImageOverlay: some View {
        ZStack {
            Color.clear

            customImageCornerIndex
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.leading, size.width * 0.06)
                .padding(.top, size.height * 0.03)

            customImageCornerIndex
                .rotationEffect(.degrees(180))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, size.width * 0.06)
                .padding(.bottom, size.height * 0.03)
        }
    }

    // MARK: Shared Parts

    private func cornerIndex(
        fontScale: CGFloat,
        weight: Font.Weight,
        design: Font.Design
    ) -> some View {
        VStack(spacing: -3) {
            Text(card.rank.symbol)
                .font(.system(size: size.fontSize * fontScale, weight: weight, design: design))
            Text(card.suit.rawValue)
                .font(.system(size: size.fontSize * fontScale))
        }
        .foregroundColor(suitColor)
    }

    private var jumboCornerIndex: some View {
        VStack(spacing: -3) {
            Text(card.rank.symbol)
                .font(.system(size: size.fontSize * 0.82, weight: .black, design: .rounded))
            Text(card.suit.rawValue)
                .font(.system(size: size.fontSize * 0.70, weight: .semibold))
        }
        .foregroundColor(suitColor)
    }

    private var customImageCornerIndex: some View {
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
    }

    private var casinoDiamondFacePattern: some View {
        VStack(spacing: size.width * 0.06) {
            ForEach(0..<8, id: \.self) { row in
                HStack(spacing: size.width * 0.06) {
                    ForEach(0..<4, id: \.self) { col in
                        Diamond()
                            .fill(((row + col) % 2 == 0 ? suitColor : Color.gray).opacity(0.055))
                            .frame(width: size.width * 0.09, height: size.width * 0.09)
                    }
                }
            }
        }
    }
}

private struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}
