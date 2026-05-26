import SwiftUI

struct ModuleCardView<Content: View>: View {
    let title: String
    let icon: String
    let tintColor: Color
    let size: ModuleCardSize
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(tintColor)
                    .frame(width: 36, height: 36)
                    .background(tintColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: size == .large ? 140 : 110)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}
