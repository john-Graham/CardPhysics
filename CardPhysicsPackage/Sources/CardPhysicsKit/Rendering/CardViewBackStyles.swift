import SwiftUI

// MARK: - Card Back Style Views

extension CardView {

    var classicBack: some View {
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

            // Inner border rectangle -- classic card back pattern
            RoundedRectangle(cornerRadius: size.cornerRadius * 0.6)
                .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                .padding(size.width * 0.08)

            // Diamond center icon
            Image(systemName: "diamond.fill")
                .font(.system(size: size.fontSize * 1.0))
                .foregroundColor(.white.opacity(0.25))
        }
    }

    var bicycleBack: some View {
        let colors = backStyle.gradientColors

        return ZStack {
            // Base gradient
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [colors.primary, colors.secondary],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // White border frame
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .strokeBorder(Color.white, lineWidth: 3)

            // Inner decorative border
            RoundedRectangle(cornerRadius: size.cornerRadius * 0.7)
                .strokeBorder(Color.white.opacity(0.8), lineWidth: 2)
                .padding(size.width * 0.06)

            // Central ornate pattern - Angel/Cherub inspired
            VStack(spacing: size.height * 0.02) {
                // Top ornamental cluster
                HStack(spacing: size.width * 0.04) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: size.fontSize * 0.3))
                    Image(systemName: "diamond.fill")
                        .font(.system(size: size.fontSize * 0.4))
                    Image(systemName: "circle.fill")
                        .font(.system(size: size.fontSize * 0.3))
                }

                // Center medallion with bicycle-style pattern
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: size.width * 0.35, height: size.width * 0.35)

                    Circle()
                        .stroke(Color.white.opacity(0.6), lineWidth: 2)
                        .frame(width: size.width * 0.35, height: size.width * 0.35)

                    // Inner decorative elements
                    ForEach(0..<8, id: \.self) { i in
                        Image(systemName: "suit.club.fill")
                            .font(.system(size: size.fontSize * 0.25))
                            .rotationEffect(.degrees(Double(i) * 45))
                            .offset(y: -size.width * 0.12)
                    }

                    // Center circle
                    Circle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: size.width * 0.12, height: size.width * 0.12)
                }

                // Bottom ornamental cluster
                HStack(spacing: size.width * 0.04) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: size.fontSize * 0.3))
                    Image(systemName: "diamond.fill")
                        .font(.system(size: size.fontSize * 0.4))
                    Image(systemName: "circle.fill")
                        .font(.system(size: size.fontSize * 0.3))
                }
            }
            .foregroundColor(.white.opacity(0.7))

            // Corner flourishes
            VStack {
                HStack {
                    Image(systemName: "sparkle")
                        .font(.system(size: size.fontSize * 0.4))
                    Spacer()
                    Image(systemName: "sparkle")
                        .font(.system(size: size.fontSize * 0.4))
                }
                Spacer()
                HStack {
                    Image(systemName: "sparkle")
                        .font(.system(size: size.fontSize * 0.4))
                    Spacer()
                    Image(systemName: "sparkle")
                        .font(.system(size: size.fontSize * 0.4))
                }
            }
            .foregroundColor(.white.opacity(0.5))
            .padding(size.width * 0.10)
        }
    }

    var frenchBack: some View {
        let colors = backStyle.gradientColors

        return ZStack {
            // Base color
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(colors.primary)

            // Elegant geometric pattern - French style
            VStack(spacing: 0) {
                ForEach(0..<5, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<3, id: \.self) { col in
                            Rectangle()
                                .fill((row + col) % 2 == 0 ? Color.white.opacity(0.15) : Color.clear)
                        }
                    }
                    .frame(height: size.height / 5)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius * 0.8))
            .padding(size.width * 0.08)

            // Refined border
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .strokeBorder(Color.white.opacity(0.6), lineWidth: 2.5)

            // Inner decorative frame
            RoundedRectangle(cornerRadius: size.cornerRadius * 0.6)
                .strokeBorder(Color.white.opacity(0.4), lineWidth: 1.5)
                .padding(size.width * 0.08)

            // Center fleur-de-lis or spade motif
            VStack(spacing: size.height * 0.1) {
                Image(systemName: "suit.spade.fill")
                    .font(.system(size: size.fontSize * 0.8))
                    .foregroundColor(.white.opacity(0.4))

                // Horizontal divider line
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: size.width * 0.4, height: 1.5)

                Image(systemName: "suit.spade.fill")
                    .font(.system(size: size.fontSize * 0.8))
                    .foregroundColor(.white.opacity(0.4))
                    .rotationEffect(.degrees(180))
            }

            // Corner ornaments
            VStack {
                HStack {
                    Image(systemName: "line.diagonal")
                        .font(.system(size: size.fontSize * 0.3))
                        .rotationEffect(.degrees(45))
                    Spacer()
                    Image(systemName: "line.diagonal")
                        .font(.system(size: size.fontSize * 0.3))
                        .rotationEffect(.degrees(-45))
                }
                Spacer()
                HStack {
                    Image(systemName: "line.diagonal")
                        .font(.system(size: size.fontSize * 0.3))
                        .rotationEffect(.degrees(-45))
                    Spacer()
                    Image(systemName: "line.diagonal")
                        .font(.system(size: size.fontSize * 0.3))
                        .rotationEffect(.degrees(45))
                }
            }
            .foregroundColor(.white.opacity(0.35))
            .padding(size.width * 0.10)
        }
    }
}
