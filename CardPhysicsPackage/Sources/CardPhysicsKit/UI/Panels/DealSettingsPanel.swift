import SwiftUI

struct DealSettingsPanel: View {
    @Bindable var settings: PhysicsSettings
    @Binding var isPresented: Bool

    var body: some View {
        HStack {
            Spacer()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        Text("Deal Settings")
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

                    // Sliders
                    SliderSetting(
                        label: "Duration",
                        value: $settings.dealDuration,
                        range: 0.1...3.0,
                        unit: "s"
                    )

                    SliderSetting(
                        label: "Arc Height",
                        value: Binding(
                            get: { Double(settings.dealArcHeight) },
                            set: { settings.dealArcHeight = Float($0) }
                        ),
                        range: 0.0...0.4,
                        unit: "m"
                    )

                    SliderSetting(
                        label: "Rotation",
                        value: $settings.dealRotation,
                        range: 0...90,
                        unit: "°"
                    )
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

