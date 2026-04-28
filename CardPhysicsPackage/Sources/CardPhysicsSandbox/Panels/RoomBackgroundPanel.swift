import SwiftUI
import CardEngine

struct RoomBackgroundPanel: View {
    @Bindable var settings: PhysicsSettings
    @Binding var isPresented: Bool

    var body: some View {
        SettingsPanelContainer(title: "Room Background", isPresented: $isPresented, width: 300, spacing: 16) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(RoomEnvironment.allCases, id: \.self) { room in
                        RoomThumbnail(
                            room: room,
                            isSelected: settings.roomEnvironment == room,
                            onSelect: {
                                settings.roomEnvironment = room
                            }
                        )
                    }
                }
            }

            if settings.roomEnvironment == .customImage {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Custom Image")
                        .font(.caption)
                        .fontWeight(.semibold)

                    RoomPhotoPicker { image in
                        handleRoomImageCapture(image)
                    }
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .glassEffect(
                        .regular.tint(Color.blue.opacity(0.6)).interactive(),
                        in: .rect(cornerRadius: 8)
                    )
                }
            }

            SliderSetting(
                label: "Rotation",
                value: $settings.roomRotation,
                range: 0...360,
                unit: "°"
            )
        }
    }

    // MARK: - Room Image Handling

    private func handleRoomImageCapture(_ image: UIImage) {
        guard let filename = RoomImageStorage.saveImage(image) else { return }

        // Clean up old custom room image
        if !settings.customRoomImageFilename.isEmpty {
            RoomImageStorage.removeImage(filename: settings.customRoomImageFilename)
        }

        settings.customRoomImageFilename = filename
        settings.roomEnvironment = .customImage
    }
}
