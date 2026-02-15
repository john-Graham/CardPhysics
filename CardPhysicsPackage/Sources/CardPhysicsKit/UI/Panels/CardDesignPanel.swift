import SwiftUI
import PhotosUI
import UIKit

struct CardDesignPanel: View {
    @Bindable var settings: PhysicsSettings
    @Binding var isPresented: Bool
    var onDesignChanged: () -> Void = {}

    @State private var showingFaceCamera = false
    @State private var showingBackCamera = false

    private var designConfig: CardDesignConfiguration {
        CardTextureGenerator.shared.designConfig
    }

    var body: some View {
        HStack {
            Spacer()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack {
                        Text("Card Design")
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

                    // Face Style
                    Text("Face Style")
                        .font(.caption)
                        .fontWeight(.semibold)

                    faceStylePicker

                    // Back Style
                    Text("Back Style")
                        .font(.caption)
                        .fontWeight(.semibold)

                    backStylePicker

                    // Preview
                    Text("Preview")
                        .font(.caption)
                        .fontWeight(.semibold)

                    designPreview

                    // Curvature slider
                    SliderSetting(
                        label: "Curvature",
                        value: Binding(
                            get: { Double(settings.cardCurvature) },
                            set: { settings.cardCurvature = Float($0) }
                        ),
                        range: 0.0...0.01,
                        unit: ""
                    )
                }
                .padding(12)
            }
            .frame(width: 350)
            .glassEffect(.regular, in: .rect(cornerRadius: 12))
            .padding(.trailing, 8)
            .padding(.vertical, 8)
        }
        .fullScreenCover(isPresented: $showingFaceCamera) {
            CameraPicker { image in
                handleImageCapture(image, purpose: "selfieFace", isFace: true)
            }
        }
        .fullScreenCover(isPresented: $showingBackCamera) {
            CameraPicker { image in
                handleImageCapture(image, purpose: "selfieBack", isFace: false)
            }
        }
    }

    // MARK: - Face Style Picker

    private var faceStylePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Preset style thumbnails
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CardFaceStyle.presets, id: \.self) { style in
                        Button {
                            designConfig.faceStyle = style
                            designConfig.save()
                            onDesignChanged()
                        } label: {
                            VStack(spacing: 4) {
                                CardView(
                                    card: Card(suit: .hearts, rank: .ace),
                                    isFaceUp: true,
                                    size: .small,
                                    faceStyle: style
                                )

                                Text(style.displayName)
                                    .font(.system(size: 9))
                                    .foregroundColor(.white)
                            }
                            .padding(4)
                            .glassEffect(
                                .regular.tint(
                                    designConfig.faceStyle == style
                                        ? Color.blue.opacity(0.5)
                                        : Color.clear
                                ),
                                in: .rect(cornerRadius: 6)
                            )
                        }
                    }
                }
            }

            // Photo + Selfie buttons
            HStack(spacing: 8) {
                CardPhotoPicker(purpose: "customFace") { image in
                    handleImageCapture(image, purpose: "customFace", isFace: true)
                }
                .font(.caption2)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .glassEffect(
                    .regular.tint(
                        designConfig.faceStyle == .customImage
                            ? Color.blue.opacity(0.5)
                            : Color.clear
                    ).interactive(),
                    in: .rect(cornerRadius: 6)
                )

                Button {
                    showingFaceCamera = true
                } label: {
                    Label("Selfie", systemImage: "camera")
                        .font(.caption2)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .glassEffect(
                    .regular.tint(
                        designConfig.faceStyle == .selfie
                            ? Color.blue.opacity(0.5)
                            : Color.clear
                    ).interactive(),
                    in: .rect(cornerRadius: 6)
                )
            }
        }
    }

    // MARK: - Back Style Picker

    private var backStylePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Preset color swatches
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CardBackStyle.presets, id: \.self) { style in
                        Button {
                            designConfig.backStyle = style
                            designConfig.save()
                            onDesignChanged()
                        } label: {
                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(style.swatchColor)
                                    .frame(width: 40, height: 56)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                                    )

                                Text(style.displayName)
                                    .font(.system(size: 9))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }
                            .padding(4)
                            .glassEffect(
                                .regular.tint(
                                    designConfig.backStyle == style
                                        ? Color.blue.opacity(0.5)
                                        : Color.clear
                                ),
                                in: .rect(cornerRadius: 6)
                            )
                        }
                    }
                }
            }

            // Photo + Selfie buttons
            HStack(spacing: 8) {
                CardPhotoPicker(purpose: "customBack") { image in
                    handleImageCapture(image, purpose: "customBack", isFace: false)
                }
                .font(.caption2)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .glassEffect(
                    .regular.tint(
                        designConfig.backStyle == .customImage
                            ? Color.blue.opacity(0.5)
                            : Color.clear
                    ).interactive(),
                    in: .rect(cornerRadius: 6)
                )

                Button {
                    showingBackCamera = true
                } label: {
                    Label("Selfie", systemImage: "camera")
                        .font(.caption2)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .glassEffect(
                    .regular.tint(
                        designConfig.backStyle == .selfie
                            ? Color.blue.opacity(0.5)
                            : Color.clear
                    ).interactive(),
                    in: .rect(cornerRadius: 6)
                )
            }
        }
    }

    // MARK: - Design Preview

    private var designPreview: some View {
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                CardView(
                    card: Card(suit: .hearts, rank: .ace),
                    isFaceUp: true,
                    size: .small,
                    faceStyle: designConfig.faceStyle
                )
                Text("Front")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 4) {
                CardView(
                    card: Card(suit: .hearts, rank: .ace),
                    isFaceUp: false,
                    size: .small,
                    backStyle: designConfig.backStyle
                )
                Text("Back")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Image Handling

    private func handleImageCapture(_ image: UIImage, purpose: String, isFace: Bool) {
        guard let filename = CardImageStorage.saveImage(image, purpose: purpose) else { return }

        if isFace {
            if purpose.contains("selfie") {
                // Remove old selfie if exists
                if let old = designConfig.selfieFaceImageFilename {
                    CardImageStorage.removeImage(filename: old)
                }
                designConfig.selfieFaceImageFilename = filename
                designConfig.faceStyle = .selfie
            } else {
                if let old = designConfig.customFaceImageFilename {
                    CardImageStorage.removeImage(filename: old)
                }
                designConfig.customFaceImageFilename = filename
                designConfig.faceStyle = .customImage
            }
        } else {
            if purpose.contains("selfie") {
                if let old = designConfig.selfieBackImageFilename {
                    CardImageStorage.removeImage(filename: old)
                }
                designConfig.selfieBackImageFilename = filename
                designConfig.backStyle = .selfie
            } else {
                if let old = designConfig.customBackImageFilename {
                    CardImageStorage.removeImage(filename: old)
                }
                designConfig.customBackImageFilename = filename
                designConfig.backStyle = .customImage
            }
        }

        designConfig.save()
        onDesignChanged()
    }
}

