import SwiftUI

struct ShimmerView: View {
    @State private var phase: CGFloat = -0.9

    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .overlay {
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.02),
                        Color.white.opacity(0.18),
                        Color.white.opacity(0.02)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .rotationEffect(.degrees(18))
                .offset(x: phase * 320)
                .blendMode(.plusLighter)
            }
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: 1.15).repeatForever(autoreverses: false)) {
                    phase = 0.9
                }
            }
    }
}
