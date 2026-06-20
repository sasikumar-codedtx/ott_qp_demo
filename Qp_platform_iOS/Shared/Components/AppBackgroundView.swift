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
            Color.black.ignoresSafeArea()

            switch style {
            case .auth:
                LinearGradient(
                    colors: [Color(hex: "FF5E00"), Color(hex: "4418B4")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 150)
                .blur(radius: 155)
                .offset(y: -30)

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
                        Color(hex: "F0A91F").opacity(0.22),
                        Color(hex: "7D3A0C").opacity(0.14),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 220)
                .blur(radius: 80)
                .offset(y: -30)

            case .search:
                LinearGradient(
                    colors: [
                        Color(hex: "D05C18").opacity(0.28),
                        Color(hex: "5D1F6E").opacity(0.36),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 220)
                .blur(radius: 95)
                .offset(y: -28)
            }

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
