import SwiftUI

struct RoomBackgroundPanel: View {
    @Bindable var settings: PhysicsSettings
    @Binding var isPresented: Bool

    var body: some View {
        HStack {
            Spacer()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack {
                        Text("Room Background")
                            .font(.subheadline)
                            .fontWeight(.bold)
                        Spacer()
                        Button("Done") {
                            isPresented = false
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }

                    Divider()

                    // Room thumbnails
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

                    // Custom image import
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
                            .glassEffect(.regular.tint(Color.blue.opacity(0.6)).interactive(), in: .rect(cornerRadius: 8))
                        }
                    }

                    // Room rotation slider
                    SliderSetting(
                        label: "Rotation",
                        value: $settings.roomRotation,
                        range: 0...360,
                        unit: "°"
                    )
                }
                .padding(12)
            }
            .frame(width: 300)
            .glassEffect(.regular, in: .rect(cornerRadius: 12))
            .padding(.trailing, 8)
            .padding(.vertical, 8)
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

