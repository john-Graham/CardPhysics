import SwiftUI

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

