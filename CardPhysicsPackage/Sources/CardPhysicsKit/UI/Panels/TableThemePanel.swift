import SwiftUI

struct TableThemePanel: View {
    @Bindable var settings: PhysicsSettings
    @Binding var isPresented: Bool

    private var theme: TableThemeSettings {
        settings.tableTheme
    }

    var body: some View {
        HStack {
            Spacer()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        Text("Table Theme")
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

                    // Felt Color Section
                    Text("Felt Color")
                        .font(.caption)
                        .fontWeight(.semibold)

                    // Preset swatches
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

                    // Custom felt toggle
                    Toggle(isOn: Bindable(theme).useCustomFelt) {
                        Text("Custom Color")
                            .font(.caption)
                    }

                    if theme.useCustomFelt {
                        feltCustomColorSliders
                    }

                    Divider()

                    // Wood Finish Section
                    Text("Wood Finish")
                        .font(.caption)
                        .fontWeight(.semibold)

                    // Preset swatches
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

                    // Custom wood toggle
                    Toggle(isOn: Bindable(theme).useCustomWood) {
                        Text("Custom Color")
                            .font(.caption)
                    }

                    if theme.useCustomWood {
                        woodCustomColorSliders
                    }
                }
                .padding(12)
            }
            .frame(width: 280)
            .glassEffect(.regular, in: .rect(cornerRadius: 12))
            .padding(.trailing, 8)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Custom Felt Color Sliders

    private var feltCustomColorSliders: some View {
        VStack(spacing: 6) {
            HStack {
                Text("R")
                    .font(.caption2)
                    .frame(width: 14)
                Slider(value: Bindable(theme).customFeltR, in: 0...0.5)
                Text(String(format: "%.2f", theme.customFeltR))
                    .font(.caption2)
                    .frame(width: 32)
            }
            HStack {
                Text("G")
                    .font(.caption2)
                    .frame(width: 14)
                Slider(value: Bindable(theme).customFeltG, in: 0...0.5)
                Text(String(format: "%.2f", theme.customFeltG))
                    .font(.caption2)
                    .frame(width: 32)
            }
            HStack {
                Text("B")
                    .font(.caption2)
                    .frame(width: 14)
                Slider(value: Bindable(theme).customFeltB, in: 0...0.5)
                Text(String(format: "%.2f", theme.customFeltB))
                    .font(.caption2)
                    .frame(width: 32)
            }

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
            HStack {
                Text("R")
                    .font(.caption2)
                    .frame(width: 14)
                Slider(value: Bindable(theme).customWoodR, in: 0...0.7)
                Text(String(format: "%.2f", theme.customWoodR))
                    .font(.caption2)
                    .frame(width: 32)
            }
            HStack {
                Text("G")
                    .font(.caption2)
                    .frame(width: 14)
                Slider(value: Bindable(theme).customWoodG, in: 0...0.5)
                Text(String(format: "%.2f", theme.customWoodG))
                    .font(.caption2)
                    .frame(width: 32)
            }
            HStack {
                Text("B")
                    .font(.caption2)
                    .frame(width: 14)
                Slider(value: Bindable(theme).customWoodB, in: 0...0.4)
                Text(String(format: "%.2f", theme.customWoodB))
                    .font(.caption2)
                    .frame(width: 32)
            }

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

