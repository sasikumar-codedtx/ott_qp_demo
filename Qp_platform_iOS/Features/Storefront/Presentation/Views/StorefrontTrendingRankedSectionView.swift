import SwiftUI
import UIKit

struct StorefrontTrendingRankedSectionView: View {
    let section: StorefrontSection
    let onViewAll: ((StorefrontSection) -> Void)?
    let onSelectItem: (StorefrontItem) -> Void
    private let rankedCardHeight: CGFloat = 196
    private let railTopPadding: CGFloat = 4
    private let railBottomPadding: CGFloat = 18

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .bottom, spacing: 8) {
                    ForEach(Array(section.items.enumerated()), id: \.element.id) { index, item in
                        StorefrontTrendingRankedCard(
                            item: item,
                            rank: index + 1,
                            onSelect: onSelectItem
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, railTopPadding)
                .padding(.bottom, railBottomPadding)
            }
            .frame(height: rankedCardHeight + railTopPadding + railBottomPadding)
        }
        .padding(.top, 2)
        .background(sectionGlow)
    }

    private var header: some View {
        Group {
            if section.allowsViewAll {
                Button {
                    onViewAll?(section)
                } label: {
                    headerContent(showsChevron: true)
                }
                .buttonStyle(LiquidButtonPressStyle())
            } else {
                headerContent(showsChevron: false)
            }
        }
    }

    private func headerContent(showsChevron: Bool) -> some View {
        HStack(spacing: 8) {
            Text(section.title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer(minLength: 12)

            if showsChevron {
                Image(systemName: AppIcons.Navigation.next)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
            }
        }
        .frame(height: 30)
        .padding(.horizontal, 16)
    }

    private var sectionGlow: some View {
        GeometryReader { proxy in
            LinearGradient(
                colors: [
                    Color(hex: "FF5E00").opacity(0.19),
                    Color(hex: "1800E7").opacity(0.19)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: max(proxy.size.width + 55, 467), height: 237)
            .blur(radius: 26)
            .offset(x: -28, y: -10)
        }
        .allowsHitTesting(false)
    }
}

private struct StorefrontTrendingRankedCard: View {
    let item: StorefrontItem
    let rank: Int
    let onSelect: (StorefrontItem) -> Void
    @Environment(\.displayScale) private var displayScale

    private let posterSize = CGSize(width: 124, height: 186)

    var body: some View {
        Button(action: handleTap) {
            ZStack(alignment: .bottomLeading) {
                rankView
                    .frame(width: 78, height: 94, alignment: .bottomLeading)
                    .offset(x: -4, y: 2)

                poster
                    .offset(x: 33)
            }
            .frame(width: 157, height: 196, alignment: .bottomLeading)
            .contentShape(Rectangle())
        }
        .buttonStyle(StorefrontTrendingPressStyle(isEnabled: item.canOpenDetail))
        .disabled(!item.canOpenDetail)
    }

    private var poster: some View {
        ZStack(alignment: .bottom) {
            PosterImageView(
                url: item.imageURL(
                    for: "0-2x3",
                    width: max(Int(ceil(posterSize.width * displayScale)), 372)
                ),
                size: posterSize,
                cornerRadius: 8
            )

            if !item.customTag.isEmpty {
                Text(item.customTag)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity)
                    .frame(height: 22)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "EC2027"), Color(hex: "5612CA")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .frame(width: posterSize.width, height: posterSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: Color.black.opacity(0.45), radius: 8, x: -3, y: 6)
    }

    @ViewBuilder
    private var rankView: some View {
        if rank <= 10 {
            Image("trendingNumber\(rank)")
                .resizable()
                .scaledToFit()
                .frame(height: 94)
                .frame(width: rank == 10 ? 104 : 70, alignment: .bottomLeading)
                .opacity(0.72)
                .shadow(color: Color.black.opacity(0.42), radius: 5, x: 5, y: 0)
        } else {
            Text("\(rank)")
                .font(.system(size: 92, weight: .black))
                .tracking(-10)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hex: "FFE680").opacity(0.38),
                            Color(hex: "965C00").opacity(0.38)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.black.opacity(0.35), radius: 5, x: 5, y: 0)
                .lineLimit(1)
        }
    }

    private func handleTap() {
        guard item.canOpenDetail else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred(intensity: 0.82)
        onSelect(item)
    }
}

private struct StorefrontTrendingPressStyle: ButtonStyle {
    let isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && isEnabled ? 0.972 : 1)
            .animation(.spring(response: 0.26, dampingFraction: 0.62), value: configuration.isPressed)
    }
}
