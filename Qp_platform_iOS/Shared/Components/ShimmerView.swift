import SwiftUI

struct ShimmerView: View {
    @State private var phase: CGFloat = -1.1

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.025),
                        Color.white.opacity(0.045),
                        Color.white.opacity(0.025)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.0),
                        Color.white.opacity(0.09),
                        Color.white.opacity(0.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .rotationEffect(.degrees(18))
                .offset(x: phase * 420)
                .blur(radius: 7)
                .blendMode(.plusLighter)
            }
            .clipped()
            .onAppear {
                withAnimation(.easeInOut(duration: 1.75).repeatForever(autoreverses: false)) {
                    phase = 1.1
                }
            }
    }
}
