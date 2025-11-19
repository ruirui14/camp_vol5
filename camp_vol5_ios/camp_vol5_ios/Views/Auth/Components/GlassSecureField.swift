import SwiftUI

struct GlassSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    @Binding var showPassword: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 24, height: 24)

            Group {
                if showPassword {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .textContentType(.password)
            .foregroundColor(.white)
            .tint(.white)
            .frame(height: 24)

            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showPassword.toggle()
                }
            }) {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(width: 24, height: 24)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.25),
                            Color.white.opacity(0.15),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(.ultraThinMaterial.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .shadow(color: Color.white.opacity(0.5), radius: 1, x: 0, y: -1)
    }
}
