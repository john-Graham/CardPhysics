import SwiftUI

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
