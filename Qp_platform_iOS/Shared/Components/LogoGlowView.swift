import SwiftUI

struct LogoGlowView: View {
    var size: CGFloat
    var glowScale: CGFloat = 1.75

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            Color(hex: "0EA5FF").opacity(0.42),
                            Color(hex: "A324FF").opacity(0.38),
                            Color(hex: "FF7A00").opacity(0.4),
                            Color(hex: "F5C132").opacity(0.34),
                            Color(hex: "0EA5FF").opacity(0.42)
                        ],
                        center: .center
                    )
                )
                .frame(width: size * glowScale, height: size * glowScale)
                .blur(radius: size * 0.28)
                .opacity(0.72)

            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
        .frame(width: size * glowScale, height: size * glowScale)
    }
}
