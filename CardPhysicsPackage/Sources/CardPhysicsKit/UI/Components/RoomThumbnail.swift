import SwiftUI

struct RoomThumbnail: View {
    let room: RoomEnvironment
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                // Thumbnail preview
                RoundedRectangle(cornerRadius: 8)
                    .fill(thumbnailGradient)
                    .frame(width: 80, height: 60)
                    .overlay(
                        Image(systemName: thumbnailIcon)
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                    )

                // Label
                Text(room.displayName)
                    .font(.system(size: 10))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 80)
            }
            .padding(6)
            .glassEffect(
                .regular.tint(
                    isSelected ? Color.blue.opacity(0.5) : Color.clear
                ),
                in: .rect(cornerRadius: 10)
            )
        }
    }

    private var thumbnailGradient: LinearGradient {
        switch room {
        case .none:
            return LinearGradient(
                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .pokerRoom:
            return LinearGradient(
                colors: [Color.green.opacity(0.6), Color.green.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .modernOffice:
            return LinearGradient(
                colors: [Color.blue.opacity(0.6), Color.cyan.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .classicLibrary:
            return LinearGradient(
                colors: [Color.brown.opacity(0.6), Color.orange.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .woodCabin:
            return LinearGradient(
                colors: [Color.brown.opacity(0.8), Color.brown.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .customImage:
            return LinearGradient(
                colors: [Color.purple.opacity(0.6), Color.pink.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var thumbnailIcon: String {
        switch room {
        case .none:
            return "xmark.circle"
        case .pokerRoom:
            return "suit.spade.fill"
        case .modernOffice:
            return "building.2.fill"
        case .classicLibrary:
            return "books.vertical.fill"
        case .woodCabin:
            return "house.fill"
        case .customImage:
            return "photo"
        }
    }
}
