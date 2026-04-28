import SwiftUI
import CardEngine

struct EnvironmentalEffectsPanel: View {
    @Bindable var settings: PhysicsSettings
    @Binding var isPresented: Bool

    var body: some View {
        SettingsPanelContainer(title: "Environmental Effects", isPresented: $isPresented) {
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
    }
}
