import SwiftUI
import UIKit

struct StorefrontCardView: View {
    let item: StorefrontItem
    let style: StorefrontCardStyle
    let layout: StorefrontCardLayout
    let rank: Int?
    let onSelect: (StorefrontItem) -> Void
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        Button(action: handleTap) {
            Group {
                switch style {
                case .homeHero:
                    heroCard(width: layout.size.width, height: layout.size.height, showLongMeta: true)
                case .featuredHero:
                    heroCard(width: layout.size.width, height: layout.size.height, showLongMeta: false)
                case .sportsHero:
                    heroCard(width: layout.size.width, height: layout.size.height, showLongMeta: false)
                case .landscape:
                    standardCard(size: layout.size, overlayHeight: layout.overlayHeight)
                case .poster:
                    standardCard(size: layout.size, overlayHeight: layout.overlayHeight)
                case .square:
                    standardCard(size: layout.size, overlayHeight: layout.overlayHeight)
                case .short:
                    standardCard(size: layout.size, overlayHeight: layout.overlayHeight)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(StorefrontCardPressStyle(isEnabled: item.canOpenDetail))
        .disabled(!item.canOpenDetail)
    }

    private func handleTap() {
        guard item.canOpenDetail else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred(intensity: 0.82)
        onSelect(item)
    }

    private func heroCard(width: CGFloat, height: CGFloat, showLongMeta: Bool) -> some View {
        ZStack(alignment: .bottomLeading) {
            PosterImageView(
                url: item.imageURL(for: "0-16x9", width: requestedImageWidth(for: CGSize(width: width, height: height), minimum: 960)),
                size: CGSize(width: width, height: height),
                cornerRadius: UIConstants.CornerRadius.hero
            )

            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.hero, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.22), Color.black.opacity(0.94)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            VStack(alignment: .leading, spacing: UIConstants.Spacing.md) {
                if item.isPremium {
                    Text(AppStrings.Storefront.premium)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, UIConstants.Spacing.md - 2)
                        .frame(height: 20)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color(hex: "151515").opacity(0.72))
                        )
                }

                Text(item.title)
                    .font(showLongMeta ? .largeTitle.weight(.black) : .title.weight(.black))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                if showLongMeta {
                    Text(item.primaryMetaText.nilIfEmpty ?? item.contentType.capitalized)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.white.opacity(0.74))

                    if !item.description.isEmpty {
                        Text(item.description)
                            .font(.footnote)
                            .foregroundStyle(Color.white.opacity(0.82))
                            .lineLimit(2)
                    }
                }

                HStack(spacing: UIConstants.Spacing.sm) {
                    Label(item.watchLabel, systemImage: AppIcons.Action.play)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 18)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.lg - 2, style: .continuous)
                                .fill(.white)
                        )

                    ZStack {
                        RoundedRectangle(cornerRadius: UIConstants.CornerRadius.lg - 2, style: .continuous)
                            .fill(Color.white.opacity(0.12))
                        Image(systemName: AppIcons.Action.plus)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, UIConstants.Spacing.xl)
            .padding(.bottom, UIConstants.Spacing.xl)
        }
        .frame(width: width, height: height)
    }

    private func standardCard(size: CGSize, overlayHeight: CGFloat) -> some View {
        ZStack(alignment: .bottomLeading) {
            PosterImageView(
                url: item.imageURL(
                    for: style.imageRatio,
                    width: requestedImageWidth(for: size, minimum: style == .short ? 360 : 240)
                ),
                size: size,
                cornerRadius: UIConstants.CornerRadius.md + 4
            )

            if overlayHeight > 0 {
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.82)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: overlayHeight)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .clipShape(RoundedRectangle(cornerRadius: UIConstants.CornerRadius.md + 4, style: .continuous))
            }

            ZStack(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: UIConstants.Spacing.xs) {
                    HStack {
                        if item.isPremium {
                            Image(systemName: AppIcons.Action.crown)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color(hex: "F6C84B"))
                                .padding(6)
                                .background(Color.black.opacity(0.32), in: Circle())
                        }
                        Spacer()
                    }

                    Spacer()

                    if item.showsInlinePlayCTA {
                        if overlayHeight > 0 {
                            HStack {
                                Spacer()
                                Image(systemName: AppIcons.Action.playCircle)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(.white, Color(hex: "F1B944"))
                            }
                        } else {
                            Image(systemName: AppIcons.Action.playCircle)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(.white.opacity(0.92), .white.opacity(0.18))
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        }
                    }
                }
                .padding(UIConstants.Spacing.sm)

                if let progress = item.progress {
                    VStack {
                        Spacer()
                        progressBar(progress)
                            .padding(.horizontal, UIConstants.Spacing.sm)
                            .padding(.bottom, UIConstants.Spacing.sm)
                    }
                }

                if let rank {
                    HStack(spacing: -6) {
                        Text("\(rank)")
                            .font(.system(size: 56, weight: .black))
                            .foregroundStyle(Color.black.opacity(0.7))
                            .offset(x: -6, y: 18)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                }
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private func requestedImageWidth(for size: CGSize, minimum: Int) -> Int {
        max(Int(ceil(size.width * displayScale)), minimum)
    }

    private func progressBar(_ progress: Double) -> some View {
        let clamped = min(max(progress, 0), 1)

        return ZStack(alignment: .leading) {
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.18))
                .frame(height: 5)

            GeometryReader { geometry in
                Capsule(style: .continuous)
                    .fill(.white)
                    .frame(width: max(18, geometry.size.width * clamped), height: 5)
            }
        }
        .frame(height: 5)
    }
}

private struct StorefrontCardPressStyle: ButtonStyle {
    let isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && isEnabled ? 0.972 : 1)
            .animation(.spring(response: 0.26, dampingFraction: 0.62), value: configuration.isPressed)
    }
}
