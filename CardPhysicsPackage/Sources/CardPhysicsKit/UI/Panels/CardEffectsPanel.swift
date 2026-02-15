import SwiftUI

struct CardEffectsPanel: View {
    @Bindable var settings: PhysicsSettings
    @Binding var isPresented: Bool

    var body: some View {
        HStack {
            Spacer()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        Text("Card Effects")
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

                    // Wear toggle
                    Toggle(isOn: $settings.enableCardWear) {
                        Text("Wear & Tear")
                            .font(.subheadline)
                    }

                    if settings.enableCardWear {
                        // Intensity slider
                        SliderSetting(
                            label: "Wear Intensity",
                            value: $settings.wearIntensity,
                            range: 0.5...2.0,
                            unit: "x"
                        )

                        // Info text
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Cards accumulate wear from:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("  - Collisions with table and other cards")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("  - Tap-to-flip interactions")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("  - Gather and pick up actions")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)

                        // Note about reset
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Text("Reset or re-deal cards to clear wear.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
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

