import SwiftUI

struct StorefrontHeaderView: View {
    enum Mode {
        case standard
        case immersive
    }

    let topInset: CGFloat
    var mode: Mode = .standard
    @State private var showDemoAlert = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: UIConstants.Spacing.lg) {
                HStack(spacing: UIConstants.Spacing.md) {
                    ZStack {
                        Capsule()
                            .fill(Color(hex: "F5B919").opacity(0.24))
                            .frame(width: 62, height: 28)
                            .blur(radius: 12)

                        Image("minilogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 30)
                    }

                    if mode == .standard {
                        Button(action: { showDemoAlert = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: AppIcons.Action.crown)
                                    .font(.system(size: 11, weight: .bold))
                                Text(AppStrings.Storefront.subscribe)
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundStyle(Color(hex: "F5B919"))
                            .padding(.horizontal, 10)
                            .frame(height: 24)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .stroke(Color(hex: "F5B919"), lineWidth: 1)
                            )
                        }
                        .buttonStyle(LiquidButtonPressStyle())
                    }
                }

                Spacer()

                if mode == .standard {
                    HStack(spacing: 12) {
                        bellButton
                        iconGlyph(AppIcons.Action.tv)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, topInset + 8)
            .padding(.bottom, 10)
            .background(headerScrim)
        }
        .demoAlert(isPresented: $showDemoAlert)
    }

    private var headerScrim: some View {
        LinearGradient(
            colors: [
                Color.black.opacity(mode == .immersive ? 0.34 : 0.46),
                Color.black.opacity(mode == .immersive ? 0.16 : 0.24),
                Color.clear
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
    }

    private var bellButton: some View {
        ZStack(alignment: .topTrailing) {
            iconGlyph(AppIcons.Action.bell)
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
                .offset(x: -1, y: 1)
        }
    }

    private func iconGlyph(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(.white)
            .frame(width: 24, height: 24)
    }
}
