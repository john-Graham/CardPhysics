import SwiftUI

struct CardEffectsPanel: View {
    @Bindable var settings: PhysicsSettings
    @Binding var isPresented: Bool

    var body: some View {
        SettingsPanelContainer(title: "Card Effects", isPresented: $isPresented) {
            Toggle(isOn: $settings.enableCardWear) {
                Text("Wear & Tear")
                    .font(.subheadline)
            }

            if settings.enableCardWear {
                SliderSetting(
                    label: "Wear Intensity",
                    value: $settings.wearIntensity,
                    range: 0.5...2.0,
                    unit: "x"
                )

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
    }
}
