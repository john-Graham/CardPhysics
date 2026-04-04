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

    private var gravityValue: Binding<Double> {
        Binding(
            get: { Double(settings.gravityMetersPerSecondSquared) },
            set: { settings.gravityMetersPerSecondSquared = Float($0) }
        )
    }

    var body: some View {
        HStack {
            Spacer()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Gravity Settings")
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

                    SliderSetting(
                        label: "Gravity",
                        value: gravityValue,
                        range: gravityRange,
                        unit: " m/s^2"
                    )

                    Text("Current: \(settings.gravityPreset.rawValue) (\(String(format: "%.2fx", settings.gravityMultiplier)))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(12)
            }
            .frame(width: 250)
            .glassEffect(.regular, in: .rect(cornerRadius: 12))
            .padding(.trailing, 8)
            .padding(.vertical, 8)
        }
    }
}
