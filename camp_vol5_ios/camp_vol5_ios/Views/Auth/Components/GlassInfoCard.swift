import SwiftUI

struct GlassInfoCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let items: [String]

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.callout)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.white.opacity(0.7))
                        Text(item)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.1),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(.ultraThinMaterial.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        )
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
}
