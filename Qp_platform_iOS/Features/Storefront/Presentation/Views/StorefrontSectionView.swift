import SwiftUI

struct StorefrontSectionView: View {
    let section: StorefrontSection
    let isHomeTab: Bool
    let cohort: QuickplayCohort
    let heroVariant: StorefrontHeroVariant
    let topChromeHeight: CGFloat
    let favoriteIDs: Set<String>
    let onViewAll: ((StorefrontSection) -> Void)?
    let onSelectItem: (StorefrontItem) -> Void
    let onToggleFavorite: (StorefrontItem) -> Void
    @State private var measuredWidth: CGFloat = 390

    var body: some View {
        let style = section.cardStyle(isHomeTab: isHomeTab, cohort: cohort)
        let containerWidth = measuredWidth - (UIConstants.Spacing.lg * 2)
        let layout = section.cardLayout(isHomeTab: isHomeTab, cohort: cohort, containerWidth: containerWidth)

        VStack(alignment: .leading, spacing: StorefrontRailMetrics.headerToCardsGap) {
            if !section.isHero && !section.usesRankedArtwork && section.backgroundImageURL == nil {
                SectionHeaderView(title: section.title, onTap: section.allowsViewAll ? {
                    onViewAll?(section)
                } : nil)
                    .padding(.horizontal, UIConstants.Spacing.lg)
            }

            if section.isHero {
                heroContainer
                    .frame(height: StorefrontHeroMetrics.reservedHeight(topChromeHeight: topChromeHeight))
                    .frame(maxWidth: .infinity)
                    .clipped(antialiased: false)
                    .transition(.opacity.animation(.easeInOut(duration: 0.24)))
            } else if section.usesRankedArtwork {
                StorefrontTrendingRankedSectionView(
                    section: section,
                    onViewAll: onViewAll,
                    onSelectItem: onSelectItem
                )
            } else if let backgroundImageURL = section.backgroundImageURL {
                StorefrontBackgroundImageSectionView(
                    section: section,
                    backgroundImageURL: backgroundImageURL,
                    style: style,
                    layout: layout,
                    sectionWidth: measuredWidth,
                    onViewAll: onViewAll,
                    onSelectItem: onSelectItem
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: StorefrontRailMetrics.cardGap) {
                        ForEach(Array(section.items.enumerated()), id: \.element.id) { index, item in
                            StorefrontCardView(
                                item: item,
                                style: style,
                                layout: layout,
                                rank: nil,
                                onSelect: onSelectItem
                            )
                        }
                    }
                    .padding(.horizontal, UIConstants.Spacing.lg)
                }
                .frame(height: layout.size.height)
            }
        }
        .background(widthReader)
    }

    private var widthReader: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear {
                    measuredWidth = proxy.size.width
                }
                .onChange(of: proxy.size.width) { _, newValue in
                    measuredWidth = newValue
                }
        }
    }

    @ViewBuilder
    private var heroContainer: some View {
        switch heroVariant {
        case .carousel:
            VStack(spacing: 0) {
                Spacer(minLength: topChromeHeight)
                    .frame(height: topChromeHeight)
                StorefrontEntertainmentHeroView(
                    items: section.items,
                    cohort: cohort,
                    favoriteIDs: favoriteIDs,
                    onToggleFavorite: onToggleFavorite,
                    onSelectItem: onSelectItem
                )
                .frame(height: StorefrontHeroMetrics.slotHeight)
            }
        case .stackedSports:
            VStack(spacing: 0) {
                Spacer(minLength: topChromeHeight)
                    .frame(height: topChromeHeight)
                StorefrontSportsHeroView(items: section.items, onSelectItem: onSelectItem)
                    .frame(height: StorefrontHeroMetrics.slotHeight)
            }
        case .immersive:
            StorefrontImmersiveHeroView(
                items: section.items,
                topChromeHeight: topChromeHeight,
                onSelectItem: onSelectItem
            )
        }
    }
}

private struct StorefrontBackgroundImageSectionView: View {
    let section: StorefrontSection
    let backgroundImageURL: URL
    let style: StorefrontCardStyle
    let layout: StorefrontCardLayout
    let sectionWidth: CGFloat
    let onViewAll: ((StorefrontSection) -> Void)?
    let onSelectItem: (StorefrontItem) -> Void

    private let titleBandHeight: CGFloat = 48
    private let titleBandVerticalPadding: CGFloat = 12
    private let cardToTitleGap: CGFloat = 12

    private var backgroundColor: Color {
        Color(hex: section.backgroundColorHex ?? "1F0C00")
    }

    private var cardRailHeight: CGFloat {
        layout.size.height + StorefrontRailMetrics.cardGap + 30
    }

    var body: some View {
        GeometryReader { proxy in
            let mediaSize = proxy.size.width
            let sectionHeight = mediaSize + titleBandHeight

            VStack(spacing: 0) {
                ZStack(alignment: .bottom) {
                    PosterImageView(
                        url: backgroundImageURL,
                        size: CGSize(width: mediaSize, height: mediaSize),
                        cornerRadius: 0
                    )
                    .frame(width: mediaSize, height: mediaSize)
                    cardRail
                        .frame(height: cardRailHeight)
                        .padding(.bottom,titleBandHeight + cardToTitleGap)
                    bottomHeading
                }
                .frame(width: mediaSize, height: mediaSize)
                .clipped()
            }
            .frame(width: mediaSize, height: sectionHeight)
        }
        .frame(height: max(sectionWidth, 1) + titleBandHeight)
        .clipped()
    }

    private var cardRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: StorefrontRailMetrics.cardGap) {
                ForEach(section.items, id: \.id) { item in
                    StorefrontBackgroundSectionCard(
                        item: item,
                        style: style,
                        layout: layout,
                        onSelect: onSelectItem
                    )
                }
            }
            .padding(.horizontal, UIConstants.Spacing.lg)
        }
        .frame(height: cardRailHeight)
    }

    private var bottomHeading: some View {
        Group {
            if section.allowsViewAll {
                Button {
                    onViewAll?(section)
                } label: {
                    bottomHeadingContent(showsChevron: true)
                }
                .buttonStyle(LiquidButtonPressStyle())
            } else {
                bottomHeadingContent(showsChevron: false)
            }
        }
    }

    private func bottomHeadingContent(showsChevron: Bool) -> some View {
        HStack(spacing: UIConstants.Spacing.sm) {
            Text(section.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            if showsChevron {
                Image(systemName: AppIcons.Navigation.next)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.vertical, titleBandVerticalPadding)
        .frame(height: titleBandHeight, alignment: .center)
        .padding(.horizontal, UIConstants.Spacing.lg)
        .background(backgroundColor)
    }
}

private struct StorefrontBackgroundSectionCard: View {
    let item: StorefrontItem
    let style: StorefrontCardStyle
    let layout: StorefrontCardLayout
    let onSelect: (StorefrontItem) -> Void
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        Button(action: handleTap) {
            VStack(alignment: .leading, spacing: StorefrontRailMetrics.cardGap) {
                ZStack(alignment: .bottomLeading) {
                    PosterImageView(
                        url: item.imageURL(
                            for: style.imageRatio,
                            width: max(Int(ceil(layout.size.width * displayScale)), 360)
                        ),
                        size: layout.size,
                        cornerRadius: StorefrontRailMetrics.cardCornerRadius
                    )

                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: StorefrontRailMetrics.cardCornerRadius, style: .continuous))

                    if item.showsInlinePlayCTA {
                        Image(systemName: AppIcons.Action.play)
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(.white)
                            .frame(width: 18, height: 18)
                            .background(Color.black.opacity(0.5), in: Circle())
                            .padding(6)
                    }
                }
                .frame(width: layout.size.width, height: layout.size.height)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(item.primaryMetaText.nilIfEmpty ?? item.contentType.capitalized)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(.white.opacity(0.74))
                        .lineLimit(1)
                }
                .frame(width: layout.size.width, alignment: .leading)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(LiquidButtonPressStyle())
        .disabled(!item.canOpenDetail)
    }

    private func handleTap() {
        guard item.canOpenDetail else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred(intensity: 0.82)
        onSelect(item)
    }
}

enum StorefrontHeroVariant {
    case carousel
    case stackedSports
    case immersive
}

enum StorefrontHeroMetrics {
    static let mediaHeight: CGFloat = 537
    static let slotHeight: CGFloat = 558

    static func topChromeHeight(topInset: CGFloat) -> CGFloat {
        topInset + 48
    }

    static func reservedHeight(topChromeHeight: CGFloat) -> CGFloat {
        slotHeight + topChromeHeight
    }
}

private extension StorefrontSection {
    var usesRankedArtwork: Bool {
        let source = "\(id) \(title)".lowercased()
        return source.contains("trending") || source.contains("top") || source.contains("rank")
    }
}
