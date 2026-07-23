import SwiftUI
import UIKit
import PhotosUI
import CardEngine

@MainActor
public struct CardPhysicsView: View {
    @State private var settings = PhysicsSettings()
    @State private var panelState = PanelState()
    @State private var sceneKey = UUID()
    @State private var cameraPosition: SIMD3<Float> = [0, 0.55, 0.54]
    @State private var cameraTarget: SIMD3<Float> = [0, 0, 0]
    @State private var coordinator = SceneCoordinator()
    @State private var cameraPresetTask: Task<Void, Never>?
    @State private var selectedDealMode: DealMode = .twenty
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
            .onAppear {
                printCurrentSettings()
            }

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
                                panelState.show(.dealSettings)
                            }

                            Button("Pick Up Settings") {
                                panelState.show(.pickUpSettings)
                            }

                            Button("In Hands Settings") {
                                panelState.show(.inHandsSettings)
                            }

                            Button("Card Design") {
                                panelState.show(.cardDesign)
                            }

                            Button("Table Theme") {
                                panelState.show(.tableTheme)
                            }

                            Button("Room Background") {
                                panelState.show(.roomBackground)
                            }

                            Button("Lighting") {
                                panelState.show(.lighting)
                            }

                            Button("Card Effects") {
                                panelState.show(.cardEffects)
                            }

                            Button("Environmental Effects") {
                                panelState.show(.environmentalEffects)
                            }

                            if settings.enableGravityFeature {
                                Button("Gravity Settings") {
                                    panelState.show(.gravitySettings)
                                }
                            }

                            Button("Camera") {
                                panelState.show(.cameraSettings)
                            }

                            Divider()

                            Button(action: {
                                settings.enableCardTapGesture.toggle()
                            }) {
                                Label("Tap to Flip", systemImage: settings.enableCardTapGesture ? "checkmark" : "")
                            }

                            // Input-feel plan Step 4c soak: gates the flick
                            // gesture (matrix variant D) on fan cards. Takes
                            // effect at the next "Fan in Hands" — gestures
                            // wire when the fan forms.
                            Button(action: {
                                settings.enableFlickToPlay.toggle()
                            }) {
                                Label("Flick to Play (fan)", systemImage: settings.enableFlickToPlay ? "checkmark" : "")
                            }

                            Menu("Feature Flags") {
                                Button(action: {
                                    settings.enableGravityFeature.toggle()
                                    if !settings.enableGravityFeature {
                                        panelState.closeIfShowing(.gravitySettings)
                                    }
                                }) {
                                    Label("Gravity Controls", systemImage: settings.enableGravityFeature ? "checkmark" : "")
                                }

                                Button(action: {
                                    settings.enablePlayerCameraPresets.toggle()
                                }) {
                                    Label("Player Camera Presets", systemImage: settings.enablePlayerCameraPresets ? "checkmark" : "")
                                }

                                Button(action: {
                                    settings.enableOverheadCameraPreset.toggle()
                                }) {
                                    Label("Overhead Camera Preset", systemImage: settings.enableOverheadCameraPreset ? "checkmark" : "")
                                }
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

            switch panelState.activePanel {
            case .cameraSettings:
                CameraControlPanel(
                    cameraPosition: $cameraPosition,
                    cameraTarget: $cameraTarget,
                    isPresented: panelBinding(for: .cameraSettings),
                    showPlayerPresets: settings.enablePlayerCameraPresets,
                    showOverheadPreset: settings.enableOverheadCameraPreset,
                    onPresetSelected: { preset in
                        applyCameraPreset(preset)
                    },
                    onReset: {
                        cameraPresetTask?.cancel()
                        cameraPosition = [0, 0.55, 0.54]
                        cameraTarget = [0, 0, 0]
                        resetScene()
                    }
                )
                .transition(.move(edge: .trailing))

            case .dealSettings:
                DealSettingsPanel(
                    settings: settings,
                    isPresented: panelBinding(for: .dealSettings)
                )
                .transition(.move(edge: .trailing))

            case .pickUpSettings:
                PickUpSettingsPanel(
                    settings: settings,
                    isPresented: panelBinding(for: .pickUpSettings)
                )
                .transition(.move(edge: .trailing))

            case .inHandsSettings:
                InHandsSettingsPanel(
                    settings: settings,
                    isPresented: panelBinding(for: .inHandsSettings),
                    coordinator: coordinator
                )
                .transition(.move(edge: .trailing))

            case .cardDesign:
                CardDesignPanel(
                    settings: settings,
                    isPresented: panelBinding(for: .cardDesign),
                    onDesignChanged: {
                        CardTextureGenerator.shared.invalidateAll()
                        resetScene()
                    }
                )
                .transition(.move(edge: .trailing))

            case .roomBackground:
                RoomBackgroundPanel(
                    settings: settings,
                    isPresented: panelBinding(for: .roomBackground)
                )
                .transition(.move(edge: .trailing))

            case .tableTheme:
                TableThemePanel(
                    settings: settings,
                    isPresented: panelBinding(for: .tableTheme)
                )
                .transition(.move(edge: .trailing))

            case .lighting:
                LightingPanel(
                    settings: settings,
                    isPresented: panelBinding(for: .lighting)
                )
                .transition(.move(edge: .trailing))

            case .cardEffects:
                CardEffectsPanel(
                    settings: settings,
                    isPresented: panelBinding(for: .cardEffects)
                )
                .transition(.move(edge: .trailing))

            case .environmentalEffects:
                EnvironmentalEffectsPanel(
                    settings: settings,
                    isPresented: panelBinding(for: .environmentalEffects)
                )
                .transition(.move(edge: .trailing))

            case .gravitySettings where settings.enableGravityFeature:
                GravitySettingsPanel(
                    settings: settings,
                    isPresented: panelBinding(for: .gravitySettings)
                )
                .transition(.move(edge: .trailing))

            case .gravitySettings, .none:
                EmptyView()
            }
        }
        .animation(.easeInOut, value: panelState.activePanel)
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
            if settings.enableFlickToPlay {
                await enableFlickSoak()
            }
        }
    }

    /// Input-feel plan Step 4c soak harness. After fanning, mark every card
    /// playable (fan cards get the tap+flick wiring via `enableTapToPlay`)
    /// and route gestures to console prints; a flick plays the card to the
    /// side-1 trick spot through the real `playCard` ballistic path so
    /// strength→flight-time scaling is visible. Console filter: FLICKSOAK.
    private func enableFlickSoak() async {
        coordinator.cardTappedHandler = { card in
            print("FLICKSOAK tap → \(card.displayName)")
        }
        coordinator.cardFlickedHandler = { [coordinator] card, strength in
            print("FLICKSOAK flick strength=\(strength) → \(card.displayName)")
            Task { await coordinator.playCardAction?(card, 1) }
        }
        let allCards = Suit.allCases.flatMap { suit in
            Rank.allCases.map { Card(suit: suit, rank: $0) }
        }
        await coordinator.setPlayableCardsAction?(allCards)
    }

    private func applyCameraPreset(_ preset: CameraPreset) {
        cameraPresetTask?.cancel()
        let startPosition = cameraPosition
        let startTarget = cameraTarget
        cameraPresetTask = Task {
            await CameraPresetAnimator.animate(
                fromPosition: startPosition,
                fromTarget: startTarget,
                toPosition: preset.position,
                toTarget: preset.target
            ) { newPosition, newTarget in
                cameraPosition = newPosition
                cameraTarget = newTarget
            }
        }
    }

    private func resetScene() {
        cameraPresetTask?.cancel()
        sceneKey = UUID()
        coordinator = SceneCoordinator()
    }

    private func panelBinding(for panel: PanelKind) -> Binding<Bool> {
        Binding(
            get: { panelState.isShowing(panel) },
            set: { isPresented in
                if isPresented {
                    panelState.show(panel)
                } else {
                    panelState.closeIfShowing(panel)
                }
            }
        )
    }

    private func printCurrentSettings() {
        print("=== CURRENT IN-HANDS SETTINGS ===")
        for side in 1...4 {
            let sideSettings = settings.inHandsSettings(for: side)
            print("Side \(side):")
            print("  Fan Angle: \(sideSettings.fanAngle) radians (\(sideSettings.fanAngle * 180 / .pi) degrees)")
            print("  Tilt Angle: \(sideSettings.tiltAngle) radians (\(sideSettings.tiltAngle * 180 / .pi) degrees)")
            print("  Arc Radius: \(sideSettings.arcRadius) meters")
            print("  Vertical Spacing: \(sideSettings.verticalSpacing) meters")
            print("  Rotation Offset: \(sideSettings.rotationOffset) radians (\(sideSettings.rotationOffset * 180 / .pi) degrees)")
        }
        print("=================================")
    }
}
