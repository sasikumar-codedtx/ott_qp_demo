import SwiftUI

struct StorefrontHeaderView: View {
    let topInset: CGFloat

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

                    Button(action: {}) {
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

                Spacer()

                HStack(spacing: 12) {
                    bellButton
                    iconGlyph(AppIcons.Action.tv)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, topInset + 8)
            .padding(.bottom, 10)
        }
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
