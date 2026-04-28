import SwiftUI
import CardEngine

struct DealSettingsPanel: View {
    @Bindable var settings: PhysicsSettings
    @Binding var isPresented: Bool

    var body: some View {
        SettingsPanelContainer(title: "Deal Settings", isPresented: $isPresented) {
            SliderSetting(
                label: "Duration",
                value: $settings.dealDuration,
                range: 0.1...3.0,
                unit: "s"
            )

            FloatSliderSetting(
                label: "Arc Height",
                value: $settings.dealArcHeight,
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
    }
}
