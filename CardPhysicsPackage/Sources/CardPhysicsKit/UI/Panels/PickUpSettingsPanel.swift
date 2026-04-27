import SwiftUI

struct PickUpSettingsPanel: View {
    @Bindable var settings: PhysicsSettings
    @Binding var isPresented: Bool

    var body: some View {
        SettingsPanelContainer(title: "Pick Up Settings", isPresented: $isPresented) {
            SliderSetting(
                label: "Duration",
                value: $settings.pickUpDuration,
                range: 0.1...1.5,
                unit: "s"
            )

            FloatSliderSetting(
                label: "Arc Height",
                value: $settings.pickUpArcHeight,
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
    }
}
