import SwiftUI

struct SonyGlassPrimaryButton: View {
    let title: String
    var systemImage: String?
    var minWidth: CGFloat?
    var height: CGFloat = 54
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 17, weight: .bold))
                }

                Text(title)
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundStyle(Color.black)
            .frame(minWidth: minWidth)
            .frame(maxWidth: minWidth == nil ? .infinity : nil)
            .frame(height: height)
            .background(primaryBackground)
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(LiquidButtonPressStyle())
    }

    private var primaryBackground: some View {
        LiquidGlassBackground(cornerRadius: 12, tone: .light, isHighlighted: true)
    }
}

struct SonyGlassIconButton: View {
    enum CornerStyle {
        case rounded
        case leadingPill
        case trailingPill
        case circle
    }

    let systemImage: String
    var size: CGFloat = 56
    var iconSize: CGFloat = 22
    var cornerStyle: CornerStyle = .rounded
    var isHighlighted = false
    var action: () -> Void

    var body: some View {
        let buttonShape = SonyGlassButtonShape(cornerStyle: cornerStyle)

        Button(action: action) {
            ZStack {
                buttonShape
                    .fill(.ultraThinMaterial)
                    .overlay(
                        buttonShape
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(isHighlighted ? 0.18 : 0.11),
                                        Color.black.opacity(0.24),
                                        Color.black.opacity(0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        buttonShape
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(hex: "FFB000").opacity(isHighlighted ? 0.42 : 0.16),
                                        Color(hex: "FF5E00").opacity(isHighlighted ? 0.2 : 0.08),
                                        Color.clear
                                    ],
                                    center: .bottomTrailing,
                                    startRadius: 2,
                                    endRadius: 50
                                )
                            )
                            .blendMode(.screen)
                    )
                    .overlay(
                        buttonShape
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.28),
                                        Color(hex: "FFB000").opacity(isHighlighted ? 0.52 : 0.16),
                                        Color.white.opacity(0.08)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isHighlighted ? 1.35 : 1
                            )
                    )
                    .shadow(color: isHighlighted ? Color(hex: "FF5E00").opacity(0.35) : Color.black.opacity(0.35), radius: isHighlighted ? 18 : 10, x: 0, y: 6)

                if isHighlighted {
                    buttonShape
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: "FF5E00").opacity(0.42),
                                    Color(hex: "7818B4").opacity(0.22),
                                    Color.clear
                                ],
                                center: .bottomTrailing,
                                startRadius: 2,
                                endRadius: 36
                            )
                        )
                }

                Image(systemName: systemImage)
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: size, height: size)
            .contentShape(buttonShape)
        }
        .buttonStyle(LiquidButtonPressStyle())
    }
}

private struct SonyGlassButtonShape: Shape {
    let cornerStyle: SonyGlassIconButton.CornerStyle

    func path(in rect: CGRect) -> Path {
        switch cornerStyle {
        case .rounded:
            RoundedRectangle(cornerRadius: 8, style: .continuous).path(in: rect)
        case .leadingPill:
            UnevenRoundedRectangle(
                topLeadingRadius: 20,
                bottomLeadingRadius: 20,
                bottomTrailingRadius: 8,
                topTrailingRadius: 8,
                style: .continuous
            ).path(in: rect)
        case .trailingPill:
            UnevenRoundedRectangle(
                topLeadingRadius: 8,
                bottomLeadingRadius: 8,
                bottomTrailingRadius: 20,
                topTrailingRadius: 20,
                style: .continuous
            ).path(in: rect)
        case .circle:
            Circle().path(in: rect)
        }
    }
}
