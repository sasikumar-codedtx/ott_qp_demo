import SwiftUI

enum AppBackgroundStyle {
    case auth
    case profile
    case storefront
    case search
}

struct AppBackgroundView: View {
    let style: AppBackgroundStyle

    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: "0A0A0A").ignoresSafeArea()

            switch style {
            case .auth:
                ZStack {
                    Color(hex: "0A0A0A")
                        .ignoresSafeArea()

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "FF5E00"), Color(hex: "4418B4")],
                                startPoint: UnitPoint(x: 0.03, y: 0.26),
                                endPoint: UnitPoint(x: 0.88, y: 0.82)
                            )
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 150)
                        .blur(radius: 155)
                        .opacity(0.9)
                        .offset(y: -12)

                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.02),
                            Color.black.opacity(0.12),
                            Color.black.opacity(0.4),
                            Color.black.opacity(0.82)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                }

            case .profile:
                LinearGradient(
                    colors: [Color(hex: "2B1248"), Color(hex: "0A0A0A")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

            case .storefront:
                LinearGradient(
                    colors: [
                        Color(hex: "F0A91F").opacity(0.42),
                        Color(hex: "7D3A0C").opacity(0.22),
                        Color.black.opacity(0.96)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

            case .search:
                LinearGradient(
                    colors: [
                        Color(hex: "D05C18").opacity(0.42),
                        Color(hex: "5D1F6E").opacity(0.44),
                        Color.black.opacity(0.96)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }

            if style != .auth {
                RadialGradient(
                    colors: [Color.white.opacity(0.05), Color.clear],
                    center: .top,
                    startRadius: 20,
                    endRadius: 320
                )
                .ignoresSafeArea()
            }
        }
    }
}
