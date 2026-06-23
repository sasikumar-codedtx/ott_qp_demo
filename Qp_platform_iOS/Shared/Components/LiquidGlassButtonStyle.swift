import SwiftUI

enum LiquidGlassTone {
    case light
    case dark
    case accent
}

struct LiquidGlassBackground: View {
    var cornerRadius: CGFloat = 16
    var tone: LiquidGlassTone = .dark
    var isHighlighted = false

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(baseFill)
            .overlay(baseShade)
            .overlay(specularHighlight)
            .overlay(colorGlow)
            .overlay(border)
            .shadow(color: shadowColor, radius: isHighlighted ? 22 : 14, x: 0, y: isHighlighted ? 10 : 7)
            .shadow(color: Color.white.opacity(tone == .light ? 0.18 : 0.06), radius: 6, x: -2, y: -2)
    }

    private var baseFill: AnyShapeStyle {
        switch tone {
        case .light:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color.white,
                        Color(hex: "F6F3EF").opacity(0.96),
                        Color(hex: "DAD5D0").opacity(0.9)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .dark, .accent:
            return AnyShapeStyle(.ultraThinMaterial)
        }
    }

    private var baseShade: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: shadeColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var specularHighlight: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(tone == .light ? 0.72 : 0.2),
                        Color.white.opacity(0.05),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .center
                )
            )
            .blendMode(.screen)
    }

    private var colorGlow: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "FFB000").opacity(isHighlighted ? 0.38 : 0.16),
                            Color(hex: "FF5E00").opacity(isHighlighted ? 0.18 : 0.08),
                            Color.clear
                        ],
                        center: .bottomTrailing,
                        startRadius: 2,
                        endRadius: 90
                    )
                )

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "5B6DFF").opacity(tone == .accent ? 0.22 : 0.08),
                            Color.clear
                        ],
                        center: .topLeading,
                        startRadius: 4,
                        endRadius: 78
                    )
                )
        }
        .blendMode(.screen)
    }

    private var border: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(tone == .light ? 0.86 : 0.28),
                        Color(hex: "FFB000").opacity(isHighlighted ? 0.5 : 0.16),
                        Color.white.opacity(tone == .light ? 0.18 : 0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: isHighlighted ? 1.35 : 1
            )
    }

    private var shadeColors: [Color] {
        switch tone {
        case .light:
            return [Color.white.opacity(0.24), Color.clear, Color.black.opacity(0.08)]
        case .dark:
            return [Color.white.opacity(0.1), Color.black.opacity(0.26), Color.black.opacity(0.58)]
        case .accent:
            return [Color.white.opacity(0.13), Color(hex: "211208").opacity(0.36), Color.black.opacity(0.62)]
        }
    }

    private var shadowColor: Color {
        switch tone {
        case .light:
            return Color.black.opacity(0.36)
        case .dark:
            return Color.black.opacity(0.42)
        case .accent:
            return Color(hex: "FF8A00").opacity(isHighlighted ? 0.34 : 0.2)
        }
    }
}

struct LiquidGlassCircleBackground: View {
    var tone: LiquidGlassTone = .dark
    var isHighlighted = false

    var body: some View {
        Circle()
            .fill(tone == .light ? AnyShapeStyle(Color.white.opacity(0.92)) : AnyShapeStyle(.ultraThinMaterial))
            .overlay(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(tone == .light ? 0.44 : 0.14),
                                Color.black.opacity(tone == .light ? 0.04 : 0.38)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "FFB000").opacity(isHighlighted ? 0.44 : 0.16),
                                Color(hex: "FF5E00").opacity(isHighlighted ? 0.22 : 0.08),
                                Color.clear
                            ],
                            center: .bottomTrailing,
                            startRadius: 2,
                            endRadius: 44
                        )
                    )
                    .blendMode(.screen)
            )
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(tone == .light ? 0.78 : 0.3),
                                Color(hex: "FFB000").opacity(isHighlighted ? 0.52 : 0.18),
                                Color.white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isHighlighted ? 1.35 : 1
                    )
            )
            .shadow(color: isHighlighted ? Color(hex: "FF8A00").opacity(0.32) : Color.black.opacity(0.38), radius: isHighlighted ? 18 : 11, x: 0, y: 7)
    }
}

struct LiquidButtonPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.955 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.spring(response: 0.24, dampingFraction: 0.72), value: configuration.isPressed)
    }
}
