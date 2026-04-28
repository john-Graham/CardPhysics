import SwiftUI
import CardEngine

struct CameraControlPanel: View {
    @Binding var cameraPosition: SIMD3<Float>
    @Binding var cameraTarget: SIMD3<Float>
    @Binding var isPresented: Bool
    let showPlayerPresets: Bool
    let showOverheadPreset: Bool
    let onPresetSelected: (CameraPreset) -> Void
    let onReset: () -> Void

    var body: some View {
        SettingsPanelContainer(title: "Camera", isPresented: $isPresented) {
            if showPlayerPresets || showOverheadPreset {
                Text("Presets")
                    .font(.caption)
                    .fontWeight(.semibold)

                if showPlayerPresets {
                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 8
                    ) {
                        ForEach(CameraPreset.playerSides, id: \.self) { preset in
                            Button(action: {
                                onPresetSelected(preset)
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: preset.icon)
                                        .font(.caption2)
                                    Text(preset.rawValue)
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .foregroundColor(.white)
                                .glassEffect(
                                    .regular.tint(Color.gray.opacity(0.35)).interactive(),
                                    in: .rect(cornerRadius: 6)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if showOverheadPreset {
                    Button(action: {
                        onPresetSelected(.overhead)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: CameraPreset.overhead.icon)
                                .font(.caption2)
                            Text(CameraPreset.overhead.rawValue)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .foregroundColor(.white)
                        .glassEffect(
                            .regular.tint(Color.gray.opacity(0.35)).interactive(),
                            in: .rect(cornerRadius: 6)
                        )
                    }
                    .buttonStyle(.plain)
                }

                Divider()
            }

            Text("Position")
                .font(.caption)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 6) {
                AxisSliderRow(label: "X:", value: $cameraPosition.x, range: -2.0...2.0)
                AxisSliderRow(label: "Y:", value: $cameraPosition.y, range: 0.1...1.5)
                AxisSliderRow(label: "Z:", value: $cameraPosition.z, range: 0.1...2.0)
            }

            Divider()

            Text("Look At")
                .font(.caption)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 6) {
                AxisSliderRow(label: "X:", value: $cameraTarget.x, range: -1.0...1.0)
                AxisSliderRow(label: "Y:", value: $cameraTarget.y, range: -0.5...0.5)
                AxisSliderRow(label: "Z:", value: $cameraTarget.z, range: -1.0...1.0)
            }

            Divider()

            Button(action: onReset) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.caption2)
                    Text("Reset")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .foregroundColor(.white)
                .glassEffect(
                    .regular.tint(Color.blue.opacity(0.6)).interactive(),
                    in: .rect(cornerRadius: 6)
                )
            }
        }
    }
}
