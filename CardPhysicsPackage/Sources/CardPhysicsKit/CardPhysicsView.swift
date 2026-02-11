import SwiftUI
import UIKit
import PhotosUI

public enum DealMode: String, CaseIterable, Sendable {
    case four = "4 Cards"
    case twelve = "12 Cards"
    case twenty = "20 Cards"
    case euchre = "Euchre"

    var cardCount: Int {
        switch self {
        case .four: return 4
        case .twelve: return 12
        case .twenty: return 20
        case .euchre: return 20
        }
    }
}

public enum GatherCorner: String, CaseIterable, Sendable {
    case bottomLeft = "Bottom Left"
    case topLeft = "Top Left"
    case topRight = "Top Right"
    case bottomRight = "Bottom Right"
}

@MainActor
@Observable
public class SceneCoordinator {
    public var dealCardsAction: ((DealMode) async -> Void)?
    public var pickUpCardAction: ((GatherCorner) async -> Void)?
    public var resetCardsAction: (() -> Void)?

    public init() {}
}

@MainActor
public struct CardPhysicsView: View {
    @State private var settings = PhysicsSettings()
    @State private var showSettings = false
    @State private var showCameraControls = false
    @State private var sceneKey = UUID()
    @State private var cameraPosition: SIMD3<Float> = [0, 0.55, 0.41]
    @State private var cameraTarget: SIMD3<Float> = [0, 0, 0]
    @State private var coordinator = SceneCoordinator()
    @State private var selectedDealMode: DealMode = .twelve
    @State private var selectedCorner: GatherCorner = .bottomLeft

    public init() {}

    public var body: some View {
        ZStack {
            // 3D Scene
            CardPhysicsScene(
                settings: settings,
                cameraPosition: cameraPosition,
                cameraTarget: cameraTarget,
                coordinator: coordinator
            )
            .id(sceneKey)
            .ignoresSafeArea()

            // Floating control buttons on the left side
            HStack {
                VStack {
                    Spacer()

                    // Animation buttons
                    VStack(spacing: 8) {
                        Text("Controls")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .glassEffect(.regular, in: .capsule)

                        AnimationButton(title: "Deal", icon: "square.stack.3d.down.right") {
                            await triggerAnimation(.deal)
                        }
                        .contextMenu {
                            ForEach(DealMode.allCases, id: \.self) { mode in
                                Button(mode.rawValue) {
                                    selectedDealMode = mode
                                    Task {
                                        await triggerAnimation(.deal)
                                    }
                                }
                            }
                        }

                        AnimationButton(title: "Pick Up", icon: "hand.raised") {
                            await triggerAnimation(.pickUp)
                        }
                        .contextMenu {
                            ForEach(GatherCorner.allCases, id: \.self) { corner in
                                Button(corner.rawValue) {
                                    selectedCorner = corner
                                    Task {
                                        await triggerAnimation(.pickUp)
                                    }
                                }
                            }
                        }

                        AnimationButton(title: "Reset", icon: "arrow.counterclockwise", color: .red) {
                            resetScene()
                        }

                        AnimationButton(title: "Camera", icon: "video", color: .purple) {
                            showCameraControls.toggle()
                        }

                        AnimationButton(title: "Settings", icon: "gearshape", color: .gray) {
                            showSettings.toggle()
                        }
                    }
                    .padding(8)
                    .glassEffect(.regular, in: .rect(cornerRadius: 12))
                    .padding(.leading, 8)
                    .padding(.bottom, 8)

                    Spacer()
                }

                Spacer()
            }

            // Camera control panel
            if showCameraControls {
                CameraControlPanel(
                    cameraPosition: $cameraPosition,
                    cameraTarget: $cameraTarget,
                    isPresented: $showCameraControls,
                    onReset: {
                        cameraPosition = [0, 0.55, 0.41]
                        cameraTarget = [0, 0, 0]
                        resetScene()
                    }
                )
                .transition(.move(edge: .leading))
            }

            // Settings panel
            if showSettings {
                SettingsPanel(
                    settings: settings,
                    isPresented: $showSettings,
                    onDesignChanged: {
                        CardTextureGenerator.shared.invalidateAll()
                        resetScene()
                    }
                )
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut, value: showSettings)
        .animation(.easeInOut, value: showCameraControls)
        .persistentSystemOverlays(.hidden)
    }

    enum AnimationType {
        case deal, pickUp
    }

    private func triggerAnimation(_ type: AnimationType) async {
        switch type {
        case .deal:
            await coordinator.dealCardsAction?(selectedDealMode)
        case .pickUp:
            await coordinator.pickUpCardAction?(selectedCorner)
        }
    }

    private func resetScene() {
        sceneKey = UUID()
        coordinator = SceneCoordinator()
    }
}

struct AnimationButton: View {
    let title: String
    let icon: String
    var color: Color = .blue
    let action: () async -> Void

    @State private var isAnimating = false

    var body: some View {
        Button {
            Task {
                isAnimating = true
                await action()
                isAnimating = false
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption2)
            }
            .frame(width: 90, height: 32)
            .foregroundColor(.white)
            .glassEffect(.regular.tint(color.opacity(isAnimating ? 0.3 : 0.6)).interactive(), in: .rect(cornerRadius: 8))
        }
        .disabled(isAnimating)
    }
}

struct CameraControlPanel: View {
    @Binding var cameraPosition: SIMD3<Float>
    @Binding var cameraTarget: SIMD3<Float>
    @Binding var isPresented: Bool
    let onReset: () -> Void

    var body: some View {
        HStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        Text("Camera")
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

                    // Camera Position
                    Text("Position")
                        .font(.caption)
                        .fontWeight(.semibold)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("X:")
                                .frame(width: 18)
                                .font(.caption2)
                            Slider(value: Binding(
                                get: { Double(cameraPosition.x) },
                                set: { cameraPosition.x = Float($0) }
                            ), in: -2.0...2.0)
                            Text(String(format: "%.2f", cameraPosition.x))
                                .frame(width: 40)
                                .font(.caption2)
                        }

                        HStack {
                            Text("Y:")
                                .frame(width: 18)
                                .font(.caption2)
                            Slider(value: Binding(
                                get: { Double(cameraPosition.y) },
                                set: { cameraPosition.y = Float($0) }
                            ), in: 0.1...1.5)
                            Text(String(format: "%.2f", cameraPosition.y))
                                .frame(width: 40)
                                .font(.caption2)
                        }

                        HStack {
                            Text("Z:")
                                .frame(width: 18)
                                .font(.caption2)
                            Slider(value: Binding(
                                get: { Double(cameraPosition.z) },
                                set: { cameraPosition.z = Float($0) }
                            ), in: 0.1...2.0)
                            Text(String(format: "%.2f", cameraPosition.z))
                                .frame(width: 40)
                                .font(.caption2)
                        }
                    }

                    Divider()

                    // Look At Target
                    Text("Look At")
                        .font(.caption)
                        .fontWeight(.semibold)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("X:")
                                .frame(width: 18)
                                .font(.caption2)
                            Slider(value: Binding(
                                get: { Double(cameraTarget.x) },
                                set: { cameraTarget.x = Float($0) }
                            ), in: -1.0...1.0)
                            Text(String(format: "%.2f", cameraTarget.x))
                                .frame(width: 40)
                                .font(.caption2)
                        }

                        HStack {
                            Text("Y:")
                                .frame(width: 18)
                                .font(.caption2)
                            Slider(value: Binding(
                                get: { Double(cameraTarget.y) },
                                set: { cameraTarget.y = Float($0) }
                            ), in: -0.5...0.5)
                            Text(String(format: "%.2f", cameraTarget.y))
                                .frame(width: 40)
                                .font(.caption2)
                        }

                        HStack {
                            Text("Z:")
                                .frame(width: 18)
                                .font(.caption2)
                            Slider(value: Binding(
                                get: { Double(cameraTarget.z) },
                                set: { cameraTarget.z = Float($0) }
                            ), in: -1.0...1.0)
                            Text(String(format: "%.2f", cameraTarget.z))
                                .frame(width: 40)
                                .font(.caption2)
                        }
                    }

                    Divider()

                    // Reset Button
                    Button(action: onReset) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.caption2)
                            Text("Reset")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .foregroundColor(.white)
                        .glassEffect(.regular.tint(Color.blue.opacity(0.6)).interactive(), in: .rect(cornerRadius: 6))
                    }
                }
                .padding(12)
            }
            .frame(width: 240)
            .glassEffect(.regular, in: .rect(cornerRadius: 12))
            .padding(.leading, 8)
            .padding(.vertical, 8)

            Spacer()
        }
    }
}

struct SettingsPanel: View {
    @Bindable var settings: PhysicsSettings
    @Binding var isPresented: Bool
    var onDesignChanged: () -> Void = {}

    @State private var dealExpanded = true
    @State private var pickUpExpanded = true
    @State private var designExpanded = true
    @State private var roomExpanded = true
    @State private var showingFacePhotoPicker = false
    @State private var showingBackPhotoPicker = false
    @State private var showingFaceCamera = false
    @State private var showingBackCamera = false
    @State private var showingRoomPhotoPicker = false

    private var designConfig: CardDesignConfiguration {
        CardTextureGenerator.shared.designConfig
    }

    var body: some View {
        HStack {
            Spacer()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Text("Physics Settings")
                            .font(.title2)
                            .bold()

                        Spacer()

                        Button("Done") {
                            isPresented = false
                        }
                    }
                    .padding(.bottom)

                    // Presets
                    Text("Presets")
                        .font(.headline)

                    HStack(spacing: 12) {
                        PresetButton(title: "Realistic") {
                            settings.applyRealisticPreset()
                        }

                        PresetButton(title: "Slow Motion") {
                            settings.applySlowMotionPreset()
                        }

                        PresetButton(title: "Fast") {
                            settings.applyFastPreset()
                        }
                    }

                    Divider()

                    // Deal animation settings
                    DisclosureGroup(isExpanded: $dealExpanded) {
                        VStack(alignment: .leading, spacing: 12) {
                            SliderSetting(
                                label: "Duration",
                                value: $settings.dealDuration,
                                range: 0.1...3.0,
                                unit: "s"
                            )

                            SliderSetting(
                                label: "Arc Height",
                                value: Binding(
                                    get: { Double(settings.dealArcHeight) },
                                    set: { settings.dealArcHeight = Float($0) }
                                ),
                                range: 0.0...0.4,
                                unit: "m"
                            )

                            SliderSetting(
                                label: "Rotation",
                                value: $settings.dealRotation,
                                range: 0...90,
                                unit: "°"
                            )
                        }
                        .padding(.top, 8)
                    } label: {
                        Text("Deal")
                            .font(.headline)
                    }

                    // Pick Up animation settings
                    DisclosureGroup(isExpanded: $pickUpExpanded) {
                        VStack(alignment: .leading, spacing: 12) {
                            SliderSetting(
                                label: "Duration",
                                value: $settings.pickUpDuration,
                                range: 0.1...1.5,
                                unit: "s"
                            )

                            SliderSetting(
                                label: "Arc Height",
                                value: Binding(
                                    get: { Double(settings.pickUpArcHeight) },
                                    set: { settings.pickUpArcHeight = Float($0) }
                                ),
                                range: 0.0...0.2,
                                unit: "m"
                            )

                            SliderSetting(
                                label: "Rotation",
                                value: $settings.pickUpRotation,
                                range: 0...30,
                                unit: "°"
                            )
                        }
                        .padding(.top, 8)
                    } label: {
                        Text("Pick Up")
                            .font(.headline)
                    }

                    Divider()

                    // Card Design
                    DisclosureGroup(isExpanded: $designExpanded) {
                        VStack(alignment: .leading, spacing: 16) {
                            // Face Style
                            Text("Face Style")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            faceStylePicker

                            // Back Style
                            Text("Back Style")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            backStylePicker

                            // Preview
                            Text("Preview")
                                .font(.subheadline)
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
                        .padding(.top, 8)
                    } label: {
                        Text("Card Design")
                            .font(.headline)
                    }

                    Divider()

                    // Room Background
                    DisclosureGroup(isExpanded: $roomExpanded) {
                        VStack(alignment: .leading, spacing: 16) {
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
                                        .font(.subheadline)
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
                        .padding(.top, 8)
                    } label: {
                        Text("Room Background")
                            .font(.headline)
                    }

                    Divider()

                    // Interaction
                    Text("Interaction")
                        .font(.headline)

                    Toggle("Tap to Flip Cards", isOn: $settings.enableCardTapGesture)
                        .font(.subheadline)

                    Divider()

                    // Reset to Defaults
                    Button(action: { settings.applyRealisticPreset() }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.caption2)
                            Text("Reset to Defaults")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .foregroundColor(.white)
                        .glassEffect(.regular.tint(Color.red.opacity(0.6)).interactive(), in: .rect(cornerRadius: 6))
                    }
                }
                .padding()
            }
            .frame(width: 350)
            .glassEffect(.regular, in: .rect(cornerRadius: 20))
            .padding()
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

    // MARK: - Room Image Handling

    private func handleRoomImageCapture(_ image: UIImage) {
        // TODO: This will be implemented when RoomImageStorage is available
        // For now, we'll just set the filename to a placeholder
        settings.customRoomImageFilename = "custom_room_\(UUID().uuidString).jpg"
    }
}

struct PresetButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundColor(.white)
                .glassEffect(.regular.tint(Color.blue.opacity(0.6)).interactive(), in: .rect(cornerRadius: 8))
        }
    }
}

struct SliderSetting: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text(String(format: "%.2f\(unit)", value))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Slider(value: $value, in: range)
        }
    }
}

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

struct RoomPhotoPicker: View {
    let onImagePicked: (UIImage) -> Void

    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            Label("Choose Panorama", systemImage: "photo.on.rectangle")
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    onImagePicked(image)
                }
            }
        }
    }
}
