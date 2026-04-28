import SwiftUI
import CardEngine

struct SettingsPanelContainer<Content: View>: View {
    let title: String
    @Binding var isPresented: Bool
    let width: CGFloat
    let spacing: CGFloat
    @ViewBuilder let content: Content

    init(
        title: String,
        isPresented: Binding<Bool>,
        width: CGFloat = 240,
        spacing: CGFloat = 12,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self._isPresented = isPresented
        self.width = width
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        HStack {
            Spacer()

            ScrollView {
                VStack(alignment: .leading, spacing: spacing) {
                    HStack {
                        Text(title)
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

                    content
                }
                .padding(12)
            }
            .frame(width: width)
            .glassEffect(.regular, in: .rect(cornerRadius: 12))
            .padding(.trailing, 8)
            .padding(.vertical, 8)
        }
    }
}
