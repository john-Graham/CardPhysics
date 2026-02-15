import SwiftUI
import UIKit
import PhotosUI

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
