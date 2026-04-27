import SwiftUI

struct LightingPanel: View {
    @Bindable var settings: PhysicsSettings
    @Binding var isPresented: Bool

    var body: some View {
        SettingsPanelContainer(title: "Lighting", isPresented: $isPresented) {
            Toggle(isOn: $settings.enableCardShadows) {
                Text("Card Shadows")
                    .font(.subheadline)
            }

            if settings.enableCardShadows {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Shadow Quality")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Picker("Quality", selection: $settings.shadowQuality) {
                        ForEach(ShadowQuality.allCases, id: \.self) { quality in
                            Text(quality.rawValue).tag(quality)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                    Text("Shadows may reduce performance on older devices.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
        }
    }
}
