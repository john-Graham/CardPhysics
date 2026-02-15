import SwiftUI

struct PickUpSettingsPanel: View {
    @Bindable var settings: PhysicsSettings
    @Binding var isPresented: Bool

    var body: some View {
        HStack {
            Spacer()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        Text("Pick Up Settings")
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
                        value: $settings.pickUpDuration,
                        range: 0.1...1.5,
                        unit: "s"
                    )

                    SliderSetting(
                        label: "Arc Height",
                        value: Binding(
                            get: { Double(settings.pickUpArcHeight) },
                            set: { settings.pickUpArcHeight = Float($0) }
                        ),
                        range: 0.0...0.2,
                        unit: "m"
                    )

                    SliderSetting(
                        label: "Rotation",
                        value: $settings.pickUpRotation,
                        range: 0...30,
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

