import SwiftUI

// MARK: - Card Back Style Views

extension CardView {

    var standardPokerBack: some View {
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

            RoundedRectangle(cornerRadius: size.cornerRadius)
                .strokeBorder(Color.white.opacity(0.88), lineWidth: 2.5)

            RoundedRectangle(cornerRadius: size.cornerRadius * 0.70)
                .strokeBorder(Color.white.opacity(0.72), lineWidth: 1.5)
                .padding(size.width * 0.07)

            RoundedRectangle(cornerRadius: size.cornerRadius * 0.52)
                .strokeBorder(Color.white.opacity(0.32), lineWidth: 1)
                .padding(size.width * 0.13)

            VStack(spacing: size.height * 0.055) {
                ornamentalRow

                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.48), lineWidth: 1.5)
                        .frame(width: size.width * 0.42, height: size.width * 0.42)

                    Circle()
                        .stroke(Color.white.opacity(0.26), lineWidth: 1)
                        .frame(width: size.width * 0.30, height: size.width * 0.30)

                    Image(systemName: "diamond.fill")
                        .font(.system(size: size.fontSize * 0.58))
                        .foregroundColor(.white.opacity(0.34))
                }

                ornamentalRow
                    .rotationEffect(.degrees(180))
            }
            .foregroundColor(.white.opacity(0.54))

            cornerSparkles
                .foregroundColor(.white.opacity(0.38))
                .padding(size.width * 0.12)
        }
    }

    var jumboIndexBack: some View {
        let colors = backStyle.gradientColors

        return ZStack {
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [colors.primary, colors.secondary],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            RoundedRectangle(cornerRadius: size.cornerRadius)
                .strokeBorder(Color.white.opacity(0.92), lineWidth: 3)

            RoundedRectangle(cornerRadius: size.cornerRadius * 0.75)
                .strokeBorder(Color.white.opacity(0.55), lineWidth: 1.5)
                .padding(size.width * 0.10)

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.56), lineWidth: 2)
                    .frame(width: size.width * 0.46, height: size.width * 0.46)

                Image(systemName: "suit.spade.fill")
                    .font(.system(size: size.fontSize * 0.62, weight: .bold))
                    .foregroundColor(.white.opacity(0.38))
                    .offset(y: -size.height * 0.08)

                Image(systemName: "suit.spade.fill")
                    .font(.system(size: size.fontSize * 0.62, weight: .bold))
                    .foregroundColor(.white.opacity(0.38))
                    .rotationEffect(.degrees(180))
                    .offset(y: size.height * 0.08)
            }

            VStack {
                Rectangle()
                    .fill(Color.white.opacity(0.30))
                    .frame(width: size.width * 0.42, height: 1)
                Spacer()
                Rectangle()
                    .fill(Color.white.opacity(0.30))
                    .frame(width: size.width * 0.42, height: 1)
            }
            .padding(.vertical, size.height * 0.23)
        }
    }

    var casinoDiamondBack: some View {
        let colors = backStyle.gradientColors

        return ZStack {
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(colors.primary)

            casinoDiamondBackPattern
                .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius * 0.75))
                .padding(size.width * 0.05)

            RoundedRectangle(cornerRadius: size.cornerRadius)
                .strokeBorder(Color.white.opacity(0.82), lineWidth: 1.5)

            RoundedRectangle(cornerRadius: size.cornerRadius * 0.70)
                .strokeBorder(Color.white.opacity(0.38), lineWidth: 1)
                .padding(size.width * 0.08)

            LinearGradient(
                colors: [Color.white.opacity(0.12), colors.secondary.opacity(0.10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
        }
    }

    // MARK: Shared Parts

    private var ornamentalRow: some View {
        HStack(spacing: size.width * 0.05) {
            Image(systemName: "circle.fill")
                .font(.system(size: size.fontSize * 0.22))
            Image(systemName: "diamond.fill")
                .font(.system(size: size.fontSize * 0.34))
            Image(systemName: "circle.fill")
                .font(.system(size: size.fontSize * 0.22))
        }
    }

    private var cornerSparkles: some View {
        VStack {
            HStack {
                Image(systemName: "sparkle")
                    .font(.system(size: size.fontSize * 0.36))
                Spacer()
                Image(systemName: "sparkle")
                    .font(.system(size: size.fontSize * 0.36))
            }
            Spacer()
            HStack {
                Image(systemName: "sparkle")
                    .font(.system(size: size.fontSize * 0.36))
                Spacer()
                Image(systemName: "sparkle")
                    .font(.system(size: size.fontSize * 0.36))
            }
        }
    }

    private var casinoDiamondBackPattern: some View {
        VStack(spacing: size.width * 0.02) {
            ForEach(0..<13, id: \.self) { row in
                HStack(spacing: size.width * 0.02) {
                    ForEach(0..<7, id: \.self) { col in
                        BackDiamond()
                            .fill(((row + col) % 2 == 0 ? Color.white : Color.clear).opacity(0.30))
                            .frame(width: size.width * 0.10, height: size.width * 0.10)
                    }
                }
            }
        }
    }
}

private struct BackDiamond: Shape {
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
