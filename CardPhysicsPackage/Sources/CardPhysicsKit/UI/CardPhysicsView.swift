import SwiftUI
import UIKit
import PhotosUI

public enum DealMode: String, CaseIterable, Sendable {
    case four = "4 Cards"
    case twelve = "12 Cards"
    case twenty = "20 Cards"
    case euchre = "Euchre"
    case inHands = "In Hands"

    var cardCount: Int {
        switch self {
        case .four: return 4
        case .twelve: return 12
        case .twenty: return 20
        case .euchre: return 20
        case .inHands: return 20
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
    public var fanInHandsAction: (() async -> Void)?
    public var updateInHandsPositionsAction: (() -> Void)?
    public var resetCardsAction: (() -> Void)?
    public var updateTableMaterialsAction: (() -> Void)?

    public init() {}
}

@MainActor
public struct CardPhysicsView: View {
    @State private var settings = PhysicsSettings()
    @State private var showDealSettings = false
    @State private var showPickUpSettings = false
    @State private var showInHandsSettings = false
    @State private var showCardDesign = false
    @State private var showRoomBackground = false
    @State private var showTableTheme = false
    @State private var showLighting = false
    @State private var showCardEffects = false
    @State private var showEnvironmentalEffects = false
    @State private var showCameraSettings = false
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

                        AnimationButton(title: "Fan in Hands", icon: "hand.thumbsup.fill", color: .green) {
                            await triggerAnimation(.fanInHands)
                        }

                        AnimationButton(title: "Reset", icon: "arrow.counterclockwise", color: .red) {
                            resetScene()
                        }

                        AnimationButton(title: "Settings", icon: "gearshape", color: .gray) {
                            // Long-press for context menu
                        }
                        .contextMenu {
                            Menu("Presets") {
                                Button("Realistic") {
                                    settings.applyRealisticPreset()
                                }
                                Button("Slow Motion") {
                                    settings.applySlowMotionPreset()
                                }
                                Button("Fast") {
                                    settings.applyFastPreset()
                                }
                            }

                            Button("Deal Settings") {
                                closeAllPanels()
                                showDealSettings = true
                            }

                            Button("Pick Up Settings") {
                                closeAllPanels()
                                showPickUpSettings = true
                            }

                            Button("In Hands Settings") {
                                closeAllPanels()
                                showInHandsSettings = true
                            }

                            Button("Card Design") {
                                closeAllPanels()
                                showCardDesign = true
                            }

                            Button("Table Theme") {
                                closeAllPanels()
                                showTableTheme = true
                            }

                            Button("Room Background") {
                                closeAllPanels()
                                showRoomBackground = true
                            }

                            Button("Lighting") {
                                closeAllPanels()
                                showLighting = true
                            }

                            Button("Card Effects") {
                                closeAllPanels()
                                showCardEffects = true
                            }

                            Button("Environmental Effects") {
                                closeAllPanels()
                                showEnvironmentalEffects = true
                            }

                            Button("Camera") {
                                closeAllPanels()
                                showCameraSettings = true
                            }

                            Divider()

                            Button(action: {
                                settings.enableCardTapGesture.toggle()
                            }) {
                                Label("Tap to Flip", systemImage: settings.enableCardTapGesture ? "checkmark" : "")
                            }

                            Divider()

                            Button("Reset to Defaults") {
                                settings.applyRealisticPreset()
                            }
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
            if showCameraSettings {
                CameraControlPanel(
                    cameraPosition: $cameraPosition,
                    cameraTarget: $cameraTarget,
                    isPresented: $showCameraSettings,
                    onReset: {
                        cameraPosition = [0, 0.55, 0.41]
                        cameraTarget = [0, 0, 0]
                        resetScene()
                    }
                )
                .transition(.move(edge: .trailing))
            }

            // Deal Settings Panel
            if showDealSettings {
                DealSettingsPanel(
                    settings: settings,
                    isPresented: $showDealSettings
                )
                .transition(.move(edge: .trailing))
            }

            // Pick Up Settings Panel
            if showPickUpSettings {
                PickUpSettingsPanel(
                    settings: settings,
                    isPresented: $showPickUpSettings
                )
                .transition(.move(edge: .trailing))
            }

            // In Hands Settings Panel
            if showInHandsSettings {
                InHandsSettingsPanel(
                    settings: settings,
                    isPresented: $showInHandsSettings,
                    coordinator: coordinator
                )
                .transition(.move(edge: .trailing))
            }

            // Card Design Panel
            if showCardDesign {
                CardDesignPanel(
                    settings: settings,
                    isPresented: $showCardDesign,
                    onDesignChanged: {
                        CardTextureGenerator.shared.invalidateAll()
                        resetScene()
                    }
                )
                .transition(.move(edge: .trailing))
            }

            // Room Background Panel
            if showRoomBackground {
                RoomBackgroundPanel(
                    settings: settings,
                    isPresented: $showRoomBackground
                )
                .transition(.move(edge: .trailing))
            }

            // Table Theme Panel
            if showTableTheme {
                TableThemePanel(
                    settings: settings,
                    isPresented: $showTableTheme
                )
                .transition(.move(edge: .trailing))
            }

            // Lighting Panel
            if showLighting {
                LightingPanel(
                    settings: settings,
                    isPresented: $showLighting
                )
                .transition(.move(edge: .trailing))
            }

            // Card Effects Panel
            if showCardEffects {
                CardEffectsPanel(
                    settings: settings,
                    isPresented: $showCardEffects
                )
                .transition(.move(edge: .trailing))
            }

            // Environmental Effects Panel
            if showEnvironmentalEffects {
                EnvironmentalEffectsPanel(
                    settings: settings,
                    isPresented: $showEnvironmentalEffects
                )
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut, value: showDealSettings)
        .animation(.easeInOut, value: showPickUpSettings)
        .animation(.easeInOut, value: showInHandsSettings)
        .animation(.easeInOut, value: showCardDesign)
        .animation(.easeInOut, value: showRoomBackground)
        .animation(.easeInOut, value: showTableTheme)
        .animation(.easeInOut, value: showLighting)
        .animation(.easeInOut, value: showCardEffects)
        .animation(.easeInOut, value: showEnvironmentalEffects)
        .animation(.easeInOut, value: showCameraSettings)
        .persistentSystemOverlays(.hidden)
    }

    enum AnimationType {
        case deal, pickUp, fanInHands
    }

    private func triggerAnimation(_ type: AnimationType) async {
        switch type {
        case .deal:
            await coordinator.dealCardsAction?(selectedDealMode)
        case .pickUp:
            await coordinator.pickUpCardAction?(selectedCorner)
        case .fanInHands:
            await coordinator.fanInHandsAction?()
        }
    }

    private func resetScene() {
        sceneKey = UUID()
        coordinator = SceneCoordinator()
    }

    private func closeAllPanels() {
        showDealSettings = false
        showPickUpSettings = false
        showInHandsSettings = false
        showCardDesign = false
        showRoomBackground = false
        showTableTheme = false
        showLighting = false
        showCardEffects = false
        showEnvironmentalEffects = false
        showCameraSettings = false
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
            Spacer()

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
            .padding(.trailing, 8)
            .padding(.vertical, 8)
        }
    }
}

struct DealSettingsPanel: View {
    @Bindable var settings: PhysicsSettings
    @Binding var isPresented: Bool

    var body: some View {
        HStack {
            Spacer()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        Text("Deal Settings")
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

                    // Sliders
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
                .padding(12)
            }
            .frame(width: 240)
            .glassEffect(.regular, in: .rect(cornerRadius: 12))
            .padding(.trailing, 8)
            .padding(.vertical, 8)
        }
    }
}

struct PickUpSettingsPanel: View {
    @Bindable var settings: PhysicsSettings
    @Binding var isPresented: Bool

    var body: some View {
        HStack {
            Spacer()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        Text("Pick Up Settings")
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

                    // Sliders
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
                .padding(12)
            }
            .frame(width: 240)
            .glassEffect(.regular, in: .rect(cornerRadius: 12))
            .padding(.trailing, 8)
            .padding(.vertical, 8)
        }
    }
}

struct InHandsSettingsPanel: View {
    @Bindable var settings: PhysicsSettings
    @Binding var isPresented: Bool
    @State private var selectedSide: Int = 1
    let coordinator: SceneCoordinator?

    var body: some View {
        HStack {
            Spacer()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        Text("In Hands Settings")
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

                    // Side Picker
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Player Side")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Picker("Side", selection: $selectedSide) {
                            Text("1 (Bottom)").tag(1)
                            Text("2 (Left)").tag(2)
                            Text("3 (Top)").tag(3)
                            Text("4 (Right)").tag(4)
                        }
                        .pickerStyle(.segmented)
                    }

                    Divider()

                    // Sliders for selected side
                    SliderSetting(
                        label: "Fan Angle",
                        value: Binding(
                            get: { Double(settings.inHandsSettings(for: selectedSide).fanAngle * 180 / .pi) },
                            set: {
                                settings.inHandsSettings(for: selectedSide).fanAngle = Float($0 * .pi / 180)
                                coordinator?.updateInHandsPositionsAction?()
                            }
                        ),
                        range: 0...90,
                        unit: "°"
                    )

                    SliderSetting(
                        label: "Tilt Angle",
                        value: Binding(
                            get: { Double(settings.inHandsSettings(for: selectedSide).tiltAngle * 180 / .pi) },
                            set: {
                                settings.inHandsSettings(for: selectedSide).tiltAngle = Float($0 * .pi / 180)
                                coordinator?.updateInHandsPositionsAction?()
                            }
                        ),
                        range: -180...180,
                        unit: "°"
                    )

                    SliderSetting(
                        label: "Arc Radius",
                        value: Binding(
                            get: { Double(settings.inHandsSettings(for: selectedSide).arcRadius) },
                            set: {
                                settings.inHandsSettings(for: selectedSide).arcRadius = Float($0)
                                coordinator?.updateInHandsPositionsAction?()
                            }
                        ),
                        range: 0.1...0.6,
                        unit: "m"
                    )

                    SliderSetting(
                        label: "Vertical Spacing",
                        value: Binding(
                            get: { Double(settings.inHandsSettings(for: selectedSide).verticalSpacing) },
                            set: {
                                settings.inHandsSettings(for: selectedSide).verticalSpacing = Float($0)
                                coordinator?.updateInHandsPositionsAction?()
                            }
                        ),
                        range: 0.0...0.05,
                        unit: "m"
                    )

                    SliderSetting(
                        label: "Rotation Offset",
                        value: Binding(
                            get: { Double(settings.inHandsSettings(for: selectedSide).rotationOffset * 180 / .pi) },
                            set: {
                                settings.inHandsSettings(for: selectedSide).rotationOffset = Float($0 * .pi / 180)
                                coordinator?.updateInHandsPositionsAction?()
                            }
                        ),
                        range: -180...180,
                        unit: "°"
                    )

                    Divider()

                    SliderSetting(
                        label: "Duration",
                        value: $settings.inHandsAnimationDuration,
                        range: 0.1...2.0,
                        unit: "s"
                    )

                    // Apply button
                    Button(action: {
                        Task {
                            await coordinator?.dealCardsAction?(.inHands)
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text("Re-deal Cards")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .glassEffect(.regular.tint(.blue).interactive(), in: .rect(cornerRadius: 8))
                    }
                }
                .padding(12)
            }
            .frame(width: 260)
            .glassEffect(.regular, in: .rect(cornerRadius: 12))
            .padding(.trailing, 8)
            .padding(.vertical, 8)
        }
    }
}

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

struct TableThemePanel: View {
    @Bindable var settings: PhysicsSettings
    @Binding var isPresented: Bool

    private var theme: TableThemeSettings {
        settings.tableTheme
    }

    var body: some View {
        HStack {
            Spacer()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        Text("Table Theme")
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

                    // Felt Color Section
                    Text("Felt Color")
                        .font(.caption)
                        .fontWeight(.semibold)

                    // Preset swatches
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(FeltColor.allCases, id: \.self) { felt in
                                Button {
                                    theme.useCustomFelt = false
                                    theme.feltColor = felt
                                } label: {
                                    VStack(spacing: 4) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(felt.swatchColor)
                                            .frame(width: 40, height: 30)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                                            )
                                        Text(felt.rawValue)
                                            .font(.system(size: 9))
                                            .foregroundColor(.white)
                                    }
                                    .padding(4)
                                    .glassEffect(
                                        .regular.tint(
                                            !theme.useCustomFelt && theme.feltColor == felt
                                                ? Color.blue.opacity(0.5)
                                                : Color.clear
                                        ),
                                        in: .rect(cornerRadius: 6)
                                    )
                                }
                            }
                        }
                    }

                    // Custom felt toggle
                    Toggle(isOn: Bindable(theme).useCustomFelt) {
                        Text("Custom Color")
                            .font(.caption)
                    }

                    if theme.useCustomFelt {
                        feltCustomColorSliders
                    }

                    Divider()

                    // Wood Finish Section
                    Text("Wood Finish")
                        .font(.caption)
                        .fontWeight(.semibold)

                    // Preset swatches
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(WoodFinish.allCases, id: \.self) { wood in
                                Button {
                                    theme.useCustomWood = false
                                    theme.woodFinish = wood
                                } label: {
                                    VStack(spacing: 4) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(wood.swatchColor)
                                            .frame(width: 40, height: 30)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                                            )
                                        Text(wood.rawValue)
                                            .font(.system(size: 9))
                                            .foregroundColor(.white)
                                    }
                                    .padding(4)
                                    .glassEffect(
                                        .regular.tint(
                                            !theme.useCustomWood && theme.woodFinish == wood
                                                ? Color.blue.opacity(0.5)
                                                : Color.clear
                                        ),
                                        in: .rect(cornerRadius: 6)
                                    )
                                }
                            }
                        }
                    }

                    // Custom wood toggle
                    Toggle(isOn: Bindable(theme).useCustomWood) {
                        Text("Custom Color")
                            .font(.caption)
                    }

                    if theme.useCustomWood {
                        woodCustomColorSliders
                    }
                }
                .padding(12)
            }
            .frame(width: 280)
            .glassEffect(.regular, in: .rect(cornerRadius: 12))
            .padding(.trailing, 8)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Custom Felt Color Sliders

    private var feltCustomColorSliders: some View {
        VStack(spacing: 6) {
            HStack {
                Text("R")
                    .font(.caption2)
                    .frame(width: 14)
                Slider(value: Bindable(theme).customFeltR, in: 0...0.5)
                Text(String(format: "%.2f", theme.customFeltR))
                    .font(.caption2)
                    .frame(width: 32)
            }
            HStack {
                Text("G")
                    .font(.caption2)
                    .frame(width: 14)
                Slider(value: Bindable(theme).customFeltG, in: 0...0.5)
                Text(String(format: "%.2f", theme.customFeltG))
                    .font(.caption2)
                    .frame(width: 32)
            }
            HStack {
                Text("B")
                    .font(.caption2)
                    .frame(width: 14)
                Slider(value: Bindable(theme).customFeltB, in: 0...0.5)
                Text(String(format: "%.2f", theme.customFeltB))
                    .font(.caption2)
                    .frame(width: 32)
            }

            // Preview swatch
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(red: theme.customFeltR, green: theme.customFeltG, blue: theme.customFeltB))
                .frame(height: 24)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                )
        }
    }

    // MARK: - Custom Wood Color Sliders

    private var woodCustomColorSliders: some View {
        VStack(spacing: 6) {
            HStack {
                Text("R")
                    .font(.caption2)
                    .frame(width: 14)
                Slider(value: Bindable(theme).customWoodR, in: 0...0.7)
                Text(String(format: "%.2f", theme.customWoodR))
                    .font(.caption2)
                    .frame(width: 32)
            }
            HStack {
                Text("G")
                    .font(.caption2)
                    .frame(width: 14)
                Slider(value: Bindable(theme).customWoodG, in: 0...0.5)
                Text(String(format: "%.2f", theme.customWoodG))
                    .font(.caption2)
                    .frame(width: 32)
            }
            HStack {
                Text("B")
                    .font(.caption2)
                    .frame(width: 14)
                Slider(value: Bindable(theme).customWoodB, in: 0...0.4)
                Text(String(format: "%.2f", theme.customWoodB))
                    .font(.caption2)
                    .frame(width: 32)
            }

            // Preview swatch
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(red: theme.customWoodR, green: theme.customWoodG, blue: theme.customWoodB))
                .frame(height: 24)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

struct LightingPanel: View {
    @Bindable var settings: PhysicsSettings
    @Binding var isPresented: Bool

    var body: some View {
        HStack {
            Spacer()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        Text("Lighting")
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

                    // Shadow toggle
                    Toggle(isOn: $settings.enableCardShadows) {
                        Text("Card Shadows")
                            .font(.subheadline)
                    }

                    if settings.enableCardShadows {
                        // Quality picker
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Shadow Quality")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Picker("Quality", selection: $settings.shadowQuality) {
                                ForEach(ShadowQuality.allCases, id: \.self) { quality in
                                    Text(quality.rawValue).tag(quality)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        // Performance warning
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                            Text("Shadows may reduce performance on older devices.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(12)
            }
            .frame(width: 240)
            .glassEffect(.regular, in: .rect(cornerRadius: 12))
            .padding(.trailing, 8)
            .padding(.vertical, 8)
        }
    }
}

struct CardEffectsPanel: View {
    @Bindable var settings: PhysicsSettings
    @Binding var isPresented: Bool

    var body: some View {
        HStack {
            Spacer()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        Text("Card Effects")
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

                    // Wear toggle
                    Toggle(isOn: $settings.enableCardWear) {
                        Text("Wear & Tear")
                            .font(.subheadline)
                    }

                    if settings.enableCardWear {
                        // Intensity slider
                        SliderSetting(
                            label: "Wear Intensity",
                            value: $settings.wearIntensity,
                            range: 0.5...2.0,
                            unit: "x"
                        )

                        // Info text
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Cards accumulate wear from:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("  - Collisions with table and other cards")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("  - Tap-to-flip interactions")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("  - Gather and pick up actions")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)

                        // Note about reset
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Text("Reset or re-deal cards to clear wear.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
            }
            .frame(width: 240)
            .glassEffect(.regular, in: .rect(cornerRadius: 12))
            .padding(.trailing, 8)
            .padding(.vertical, 8)
        }
    }
}

struct EnvironmentalEffectsPanel: View {
    @Bindable var settings: PhysicsSettings
    @Binding var isPresented: Bool

    var body: some View {
        HStack {
            Spacer()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        Text("Environmental Effects")
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

                    // Dust Motes Section
                    Toggle(isOn: $settings.enableDustMotes) {
                        Text("Dust Motes")
                            .font(.subheadline)
                    }

                    if settings.enableDustMotes {
                        SliderSetting(
                            label: "Dust Density",
                            value: $settings.dustDensity,
                            range: 0.5...2.0,
                            unit: "x"
                        )

                        Text("Floating dust particles above the table surface.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // Felt Disturbance Section
                    Toggle(isOn: $settings.enableFeltDisturbance) {
                        Text("Felt Disturbance")
                            .font(.subheadline)
                    }

                    if settings.enableFeltDisturbance {
                        SliderSetting(
                            label: "Burst Intensity",
                            value: $settings.burstIntensity,
                            range: 0.5...2.0,
                            unit: "x"
                        )

                        Text("Particle bursts when cards land on the felt.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    // Performance warning
                    if settings.enableDustMotes || settings.enableFeltDisturbance {
                        Divider()

                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                            Text("Particle effects may reduce performance on older devices.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(12)
            }
            .frame(width: 240)
            .glassEffect(.regular, in: .rect(cornerRadius: 12))
            .padding(.trailing, 8)
            .padding(.vertical, 8)
        }
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
