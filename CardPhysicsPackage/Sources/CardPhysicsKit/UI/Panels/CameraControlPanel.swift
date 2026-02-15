import SwiftUI

struct CameraControlPanel: View {
    @Binding var cameraPosition: SIMD3<Float>
    @Binding var cameraTarget: SIMD3<Float>
    @Binding var isPresented: Bool
    let onReset: () -> Void

    var body: some View {
        HStack {
            Spacer()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        Text("Camera")
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

                    // Camera Position
                    Text("Position")
                        .font(.caption)
                        .fontWeight(.semibold)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("X:")
                                .frame(width: 18)
                                .font(.caption2)
                            Slider(value: Binding(
                                get: { Double(cameraPosition.x) },
                                set: { cameraPosition.x = Float($0) }
                            ), in: -2.0...2.0)
                            Text(String(format: "%.2f", cameraPosition.x))
                                .frame(width: 40)
                                .font(.caption2)
                        }

                        HStack {
                            Text("Y:")
                                .frame(width: 18)
                                .font(.caption2)
                            Slider(value: Binding(
                                get: { Double(cameraPosition.y) },
                                set: { cameraPosition.y = Float($0) }
                            ), in: 0.1...1.5)
                            Text(String(format: "%.2f", cameraPosition.y))
                                .frame(width: 40)
                                .font(.caption2)
                        }

                        HStack {
                            Text("Z:")
                                .frame(width: 18)
                                .font(.caption2)
                            Slider(value: Binding(
                                get: { Double(cameraPosition.z) },
                                set: { cameraPosition.z = Float($0) }
                            ), in: 0.1...2.0)
                            Text(String(format: "%.2f", cameraPosition.z))
                                .frame(width: 40)
                                .font(.caption2)
                        }
                    }

                    Divider()

                    // Look At Target
                    Text("Look At")
                        .font(.caption)
                        .fontWeight(.semibold)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("X:")
                                .frame(width: 18)
                                .font(.caption2)
                            Slider(value: Binding(
                                get: { Double(cameraTarget.x) },
                                set: { cameraTarget.x = Float($0) }
                            ), in: -1.0...1.0)
                            Text(String(format: "%.2f", cameraTarget.x))
                                .frame(width: 40)
                                .font(.caption2)
                        }

                        HStack {
                            Text("Y:")
                                .frame(width: 18)
                                .font(.caption2)
                            Slider(value: Binding(
                                get: { Double(cameraTarget.y) },
                                set: { cameraTarget.y = Float($0) }
                            ), in: -0.5...0.5)
                            Text(String(format: "%.2f", cameraTarget.y))
                                .frame(width: 40)
                                .font(.caption2)
                        }

                        HStack {
                            Text("Z:")
                                .frame(width: 18)
                                .font(.caption2)
                            Slider(value: Binding(
                                get: { Double(cameraTarget.z) },
                                set: { cameraTarget.z = Float($0) }
                            ), in: -1.0...1.0)
                            Text(String(format: "%.2f", cameraTarget.z))
                                .frame(width: 40)
                                .font(.caption2)
                        }
                    }

                    Divider()

                    // Reset Button
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
                        .glassEffect(.regular.tint(Color.blue.opacity(0.6)).interactive(), in: .rect(cornerRadius: 6))
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
