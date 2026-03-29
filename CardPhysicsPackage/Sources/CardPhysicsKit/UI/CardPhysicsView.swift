import SwiftUI
import UIKit
import PhotosUI

@MainActor
public struct CardPhysicsView: View {
    @State private var settings = PhysicsSettings()
    @State private var panelState = PanelState()
    @State private var sceneKey = UUID()
    @State private var cameraPosition: SIMD3<Float> = [0, 0.55, 0.54]
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
                                panelState.closeAll()
                                panelState.showDealSettings = true
                            }

                            Button("Pick Up Settings") {
                                panelState.closeAll()
                                panelState.showPickUpSettings = true
                            }

                            Button("In Hands Settings") {
                                panelState.closeAll()
                                panelState.showInHandsSettings = true
                            }

                            Button("Card Design") {
                                panelState.closeAll()
                                panelState.showCardDesign = true
                            }

                            Button("Table Theme") {
                                panelState.closeAll()
                                panelState.showTableTheme = true
                            }

                            Button("Room Background") {
                                panelState.closeAll()
                                panelState.showRoomBackground = true
                            }

                            Button("Lighting") {
                                panelState.closeAll()
                                panelState.showLighting = true
                            }

                            Button("Card Effects") {
                                panelState.closeAll()
                                panelState.showCardEffects = true
                            }

                            Button("Environmental Effects") {
                                panelState.closeAll()
                                panelState.showEnvironmentalEffects = true
                            }

                            Button("Camera") {
                                panelState.closeAll()
                                panelState.showCameraSettings = true
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
            if panelState.showCameraSettings {
                CameraControlPanel(
                    cameraPosition: $cameraPosition,
                    cameraTarget: $cameraTarget,
                    isPresented: $panelState.showCameraSettings,
                    onReset: {
                        cameraPosition = [0, 0.55, 0.54]
                        cameraTarget = [0, 0, 0]
                        resetScene()
                    }
                )
                .transition(.move(edge: .trailing))
            }

            // Deal Settings Panel
            if panelState.showDealSettings {
                DealSettingsPanel(
                    settings: settings,
                    isPresented: $panelState.showDealSettings
                )
                .transition(.move(edge: .trailing))
            }

            // Pick Up Settings Panel
            if panelState.showPickUpSettings {
                PickUpSettingsPanel(
                    settings: settings,
                    isPresented: $panelState.showPickUpSettings
                )
                .transition(.move(edge: .trailing))
            }

            // In Hands Settings Panel
            if panelState.showInHandsSettings {
                InHandsSettingsPanel(
                    settings: settings,
                    isPresented: $panelState.showInHandsSettings,
                    coordinator: coordinator
                )
                .transition(.move(edge: .trailing))
            }

            // Card Design Panel
            if panelState.showCardDesign {
                CardDesignPanel(
                    settings: settings,
                    isPresented: $panelState.showCardDesign,
                    onDesignChanged: {
                        CardTextureGenerator.shared.invalidateAll()
                        resetScene()
                    }
                )
                .transition(.move(edge: .trailing))
            }

            // Room Background Panel
            if panelState.showRoomBackground {
                RoomBackgroundPanel(
                    settings: settings,
                    isPresented: $panelState.showRoomBackground
                )
                .transition(.move(edge: .trailing))
            }

            // Table Theme Panel
            if panelState.showTableTheme {
                TableThemePanel(
                    settings: settings,
                    isPresented: $panelState.showTableTheme
                )
                .transition(.move(edge: .trailing))
            }

            // Lighting Panel
            if panelState.showLighting {
                LightingPanel(
                    settings: settings,
                    isPresented: $panelState.showLighting
                )
                .transition(.move(edge: .trailing))
            }

            // Card Effects Panel
            if panelState.showCardEffects {
                CardEffectsPanel(
                    settings: settings,
                    isPresented: $panelState.showCardEffects
                )
                .transition(.move(edge: .trailing))
            }

            // Environmental Effects Panel
            if panelState.showEnvironmentalEffects {
                EnvironmentalEffectsPanel(
                    settings: settings,
                    isPresented: $panelState.showEnvironmentalEffects
                )
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut, value: panelState.showDealSettings)
        .animation(.easeInOut, value: panelState.showPickUpSettings)
        .animation(.easeInOut, value: panelState.showInHandsSettings)
        .animation(.easeInOut, value: panelState.showCardDesign)
        .animation(.easeInOut, value: panelState.showRoomBackground)
        .animation(.easeInOut, value: panelState.showTableTheme)
        .animation(.easeInOut, value: panelState.showLighting)
        .animation(.easeInOut, value: panelState.showCardEffects)
        .animation(.easeInOut, value: panelState.showEnvironmentalEffects)
        .animation(.easeInOut, value: panelState.showCameraSettings)
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
