import SwiftUI

struct PresetButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundColor(.white)
                .glassEffect(.regular.tint(Color.blue.opacity(0.6)).interactive(), in: .rect(cornerRadius: 8))
        }
    }
}
