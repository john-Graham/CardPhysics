import SwiftUI

@MainActor
@Observable
public class SceneCoordinator {
    public var dealCardsAction: (() async -> Void)?
    public var playCardAction: ((Int) async -> Void)?
    public var pickUpCardAction: ((Int) async -> Void)?
    public var slideCardsAction: (() async -> Void)?
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
                            .background(.black.opacity(0.7))
                            .cornerRadius(6)

                        AnimationButton(title: "Deal", icon: "square.stack.3d.down.right") {
                            await triggerAnimation(.deal)
                        }

                        AnimationButton(title: "Play", icon: "play.circle") {
                            await triggerAnimation(.play)
                        }

                        AnimationButton(title: "Pick Up", icon: "hand.raised") {
                            await triggerAnimation(.pickUp)
                        }

                        AnimationButton(title: "Slide", icon: "arrow.right") {
                            await triggerAnimation(.slide)
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
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .shadow(radius: 8)
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
                SettingsPanel(settings: settings, isPresented: $showSettings)
                    .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut, value: showSettings)
        .animation(.easeInOut, value: showCameraControls)
        .persistentSystemOverlays(.hidden)
    }

    enum AnimationType {
        case deal, play, pickUp, slide
    }

    private func triggerAnimation(_ type: AnimationType) async {
        switch type {
        case .deal:
            await coordinator.dealCardsAction?()
        case .play:
            await coordinator.playCardAction?(0)
        case .pickUp:
            await coordinator.pickUpCardAction?(0)
        case .slide:
            await coordinator.slideCardsAction?()
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
            .background(color.opacity(isAnimating ? 0.5 : 1.0))
            .foregroundColor(.white)
            .cornerRadius(8)
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
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    }
                }
                .padding(12)
            }
            .frame(width: 240)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .shadow(radius: 12)
            .padding(.leading, 8)
            .padding(.vertical, 8)

            Spacer()
        }
    }
}

struct SettingsPanel: View {
    @Bindable var settings: PhysicsSettings
    @Binding var isPresented: Bool

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

                    // Animation Durations
                    Text("Animation Durations")
                        .font(.headline)

                    SliderSetting(
                        label: "Deal Duration",
                        value: $settings.dealDuration,
                        range: 0.1...3.0,
                        unit: "s"
                    )

                    SliderSetting(
                        label: "Play Duration",
                        value: $settings.playDuration,
                        range: 0.1...2.0,
                        unit: "s"
                    )

                    SliderSetting(
                        label: "Pick Up Duration",
                        value: $settings.pickUpDuration,
                        range: 0.1...1.5,
                        unit: "s"
                    )

                    SliderSetting(
                        label: "Slide Duration",
                        value: $settings.slideDuration,
                        range: 0.1...3.0,
                        unit: "s"
                    )

                    Divider()

                    // Arc Heights
                    Text("Arc Heights")
                        .font(.headline)

                    SliderSetting(
                        label: "Deal Arc",
                        value: Binding(
                            get: { Double(settings.dealArcHeight) },
                            set: { settings.dealArcHeight = Float($0) }
                        ),
                        range: 0.0...0.4,
                        unit: "m"
                    )

                    SliderSetting(
                        label: "Play Arc",
                        value: Binding(
                            get: { Double(settings.playArcHeight) },
                            set: { settings.playArcHeight = Float($0) }
                        ),
                        range: 0.0...0.3,
                        unit: "m"
                    )

                    SliderSetting(
                        label: "Pick Up Arc",
                        value: Binding(
                            get: { Double(settings.pickUpArcHeight) },
                            set: { settings.pickUpArcHeight = Float($0) }
                        ),
                        range: 0.0...0.2,
                        unit: "m"
                    )

                    Divider()

                    // Rotations
                    Text("Rotations")
                        .font(.headline)

                    SliderSetting(
                        label: "Deal Rotation",
                        value: $settings.dealRotation,
                        range: 0...90,
                        unit: "°"
                    )

                    SliderSetting(
                        label: "Play Rotation",
                        value: $settings.playRotation,
                        range: 0...45,
                        unit: "°"
                    )

                    SliderSetting(
                        label: "Pick Up Rotation",
                        value: $settings.pickUpRotation,
                        range: 0...30,
                        unit: "°"
                    )

                    Divider()

                    // Card Curvature
                    Text("Card Appearance")
                        .font(.headline)

                    SliderSetting(
                        label: "Card Curvature",
                        value: Binding(
                            get: { Double(settings.cardCurvature) },
                            set: { settings.cardCurvature = Float($0) }
                        ),
                        range: 0.0...0.01,
                        unit: ""
                    )
                }
                .padding()
            }
            .frame(width: 350)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding()
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
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
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
