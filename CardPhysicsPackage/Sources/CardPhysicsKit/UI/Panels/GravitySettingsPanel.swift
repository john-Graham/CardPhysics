import SwiftUI

struct GravitySettingsPanel: View {
    @Bindable var settings: PhysicsSettings
    @Binding var isPresented: Bool

    private let presetColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

    private var gravityRange: ClosedRange<Double> {
        Double(GravityPreset.moon.metersPerSecondSquared)...Double(GravityPreset.jupiter.metersPerSecondSquared)
    }

    var body: some View {
        SettingsPanelContainer(title: "Gravity Settings", isPresented: $isPresented, width: 250) {
            Text("Presets")
                .font(.caption)
                .fontWeight(.semibold)

            LazyVGrid(columns: presetColumns, spacing: 8) {
                ForEach([GravityPreset.moon, .mars, .earth, .jupiter], id: \.self) { preset in
                    Button(action: {
                        settings.applyGravityPreset(preset)
                    }) {
                        Text(preset.rawValue)
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .foregroundColor(.white)
                            .glassEffect(
                                .regular
                                    .tint(settings.gravityPreset == preset ? Color.blue.opacity(0.65) : Color.gray.opacity(0.35))
                                    .interactive(),
                                in: .rect(cornerRadius: 6)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()

            FloatSliderSetting(
                label: "Gravity",
                value: $settings.gravityMetersPerSecondSquared,
                range: gravityRange,
                unit: " m/s^2"
            )

            Text("Current: \(settings.gravityPreset.rawValue) (\(String(format: "%.2fx", settings.gravityMultiplier)))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
