import SwiftUI

struct TableThemePanel: View {
    @Bindable var settings: PhysicsSettings
    @Binding var isPresented: Bool

    private var theme: TableThemeSettings {
        settings.tableTheme
    }

    var body: some View {
        SettingsPanelContainer(title: "Table Theme", isPresented: $isPresented, width: 280) {
            Text("Felt Color")
                .font(.caption)
                .fontWeight(.semibold)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(FeltColor.allCases, id: \.self) { felt in
                        Button {
                            theme.useCustomFelt = false
                            theme.feltColor = felt
                        } label: {
                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(felt.swatchColor)
                                    .frame(width: 40, height: 30)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                                    )
                                Text(felt.rawValue)
                                    .font(.system(size: 9))
                                    .foregroundColor(.white)
                            }
                            .padding(4)
                            .glassEffect(
                                .regular.tint(
                                    !theme.useCustomFelt && theme.feltColor == felt
                                        ? Color.blue.opacity(0.5)
                                        : Color.clear
                                ),
                                in: .rect(cornerRadius: 6)
                            )
                        }
                    }
                }
            }
            Toggle(isOn: Bindable(theme).useCustomFelt) {
                Text("Custom Color")
                    .font(.caption)
            }

            if theme.useCustomFelt {
                feltCustomColorSliders
            }

            Divider()

            Text("Wood Finish")
                .font(.caption)
                .fontWeight(.semibold)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(WoodFinish.allCases, id: \.self) { wood in
                        Button {
                            theme.useCustomWood = false
                            theme.woodFinish = wood
                        } label: {
                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(wood.swatchColor)
                                    .frame(width: 40, height: 30)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                                    )
                                Text(wood.rawValue)
                                    .font(.system(size: 9))
                                    .foregroundColor(.white)
                            }
                            .padding(4)
                            .glassEffect(
                                .regular.tint(
                                    !theme.useCustomWood && theme.woodFinish == wood
                                        ? Color.blue.opacity(0.5)
                                        : Color.clear
                                ),
                                in: .rect(cornerRadius: 6)
                            )
                        }
                    }
                }
            }

            Toggle(isOn: Bindable(theme).useCustomWood) {
                Text("Custom Color")
                    .font(.caption)
            }

            if theme.useCustomWood {
                woodCustomColorSliders
            }
        }
    }

    // MARK: - Custom Felt Color Sliders

    private var feltCustomColorSliders: some View {
        VStack(spacing: 6) {
            ColorChannelSliderRow(label: "R", value: Bindable(theme).customFeltR, range: 0...0.5)
            ColorChannelSliderRow(label: "G", value: Bindable(theme).customFeltG, range: 0...0.5)
            ColorChannelSliderRow(label: "B", value: Bindable(theme).customFeltB, range: 0...0.5)

            // Preview swatch
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(red: theme.customFeltR, green: theme.customFeltG, blue: theme.customFeltB))
                .frame(height: 24)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                )
        }
    }

    // MARK: - Custom Wood Color Sliders

    private var woodCustomColorSliders: some View {
        VStack(spacing: 6) {
            ColorChannelSliderRow(label: "R", value: Bindable(theme).customWoodR, range: 0...0.7)
            ColorChannelSliderRow(label: "G", value: Bindable(theme).customWoodG, range: 0...0.5)
            ColorChannelSliderRow(label: "B", value: Bindable(theme).customWoodB, range: 0...0.4)

            // Preview swatch
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(red: theme.customWoodR, green: theme.customWoodG, blue: theme.customWoodB))
                .frame(height: 24)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                )
        }
    }
}
