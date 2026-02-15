import SwiftUI

struct AnimationButton: View {
    let title: String
    let icon: String
    var color: Color = .blue
    let action: () async -> Void

    @State private var isAnimating = false

    var body: some View {
        Button {
            Task {
                isAnimating = true
                await action()
                isAnimating = false
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption2)
            }
            .frame(width: 90, height: 32)
            .foregroundColor(.white)
            .glassEffect(.regular.tint(color.opacity(isAnimating ? 0.3 : 0.6)).interactive(), in: .rect(cornerRadius: 8))
        }
        .disabled(isAnimating)
    }
}
