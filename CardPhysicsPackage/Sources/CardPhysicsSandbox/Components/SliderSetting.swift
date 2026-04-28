import SwiftUI
import CardEngine

struct SliderSetting: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text(String(format: "%.2f\(unit)", value))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Slider(value: $value, in: range)
        }
    }
}

struct FloatSliderSetting: View {
    let label: String
    @Binding var value: Float
    let range: ClosedRange<Double>
    let unit: String

    var body: some View {
        SliderSetting(
            label: label,
            value: Binding(
                get: { Double(value) },
                set: { value = Float($0) }
            ),
            range: range,
            unit: unit
        )
    }
}

struct AxisSliderRow: View {
    let label: String
    @Binding var value: Float
    let range: ClosedRange<Double>

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 18)
                .font(.caption2)
            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { value = Float($0) }
                ),
                in: range
            )
            Text(String(format: "%.2f", value))
                .frame(width: 40)
                .font(.caption2)
        }
    }
}

struct ColorChannelSliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        HStack {
            Text(label)
                .font(.caption2)
                .frame(width: 14)
            Slider(value: $value, in: range)
            Text(String(format: "%.2f", value))
                .font(.caption2)
                .frame(width: 32)
        }
    }
}
