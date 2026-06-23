import SwiftUI

struct LiquidLoadingOverlay: View {
    let title: String
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.48)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            AngularGradient(
                                colors: [
                                    Color(hex: "173DFF"),
                                    Color(hex: "DD2CFF"),
                                    Color(hex: "FFB000"),
                                    Color(hex: "173DFF")
                                ],
                                center: .center
                            )
                        )
                        .frame(width: 72, height: 72)
                        .blur(radius: 10)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))

                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 58, height: 58)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.24), lineWidth: 1)
                        )

                    ProgressView()
                        .tint(.white)
                }

                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.black.opacity(0.52))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
            .shadow(color: Color(hex: "DD2CFF").opacity(0.18), radius: 26, x: 0, y: 8)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.35).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}
