import SwiftUI

struct LightingPanel: View {
    @Bindable var settings: PhysicsSettings
    @Binding var isPresented: Bool

    var body: some View {
        HStack {
            Spacer()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        Text("Lighting")
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

                    // Shadow toggle
                    Toggle(isOn: $settings.enableCardShadows) {
                        Text("Card Shadows")
                            .font(.subheadline)
                    }

                    if settings.enableCardShadows {
                        // Quality picker
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

                        // Performance warning
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
                .padding(12)
            }
            .frame(width: 240)
            .glassEffect(.regular, in: .rect(cornerRadius: 12))
            .padding(.trailing, 8)
            .padding(.vertical, 8)
        }
    }
}

