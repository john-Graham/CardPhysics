import SwiftUI
import CardEngine

struct InHandsSettingsPanel: View {
    @Bindable var settings: PhysicsSettings
    @Binding var isPresented: Bool
    @State private var selectedSide: Int = 1
    let coordinator: SceneCoordinator?

    var body: some View {
        SettingsPanelContainer(title: "In Hands Settings", isPresented: $isPresented, width: 260) {
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

            SliderSetting(
                label: "Fan Angle",
                value: Binding(
                    get: { Double(settings.inHandsSettings(for: selectedSide).fanAngle * 180 / .pi) },
                    set: {
                        settings.inHandsSettings(for: selectedSide).fanAngle = Float($0 * .pi / 180)
                        coordinator?.updateInHandsPositionsAction?()
                    }
                ),
                range: -60...60,
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

            SliderSetting(
                label: "Curvature",
                value: Binding(
                    get: { Double(settings.inHandsSettings(for: selectedSide).curvature) },
                    set: {
                        settings.inHandsSettings(for: selectedSide).curvature = Float($0)
                        coordinator?.updateInHandsPositionsAction?()
                    }
                ),
                range: -0.05...0.05,
                unit: "m"
            )

            Divider()

            SliderSetting(
                label: "Duration",
                value: $settings.inHandsAnimationDuration,
                range: 0.1...2.0,
                unit: "s"
            )

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
    }
}
