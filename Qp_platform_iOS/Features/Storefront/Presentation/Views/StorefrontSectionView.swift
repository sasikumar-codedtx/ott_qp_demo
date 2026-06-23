import SwiftUI

struct StorefrontSectionView: View {
    let section: StorefrontSection
    let isHomeTab: Bool
    let cohort: QuickplayCohort
    let heroVariant: StorefrontHeroVariant
    let onViewAll: ((StorefrontSection) -> Void)?
    let onSelectItem: (StorefrontItem) -> Void
    @State private var measuredWidth: CGFloat = 390

    var body: some View {
        let style = section.cardStyle(isHomeTab: isHomeTab, cohort: cohort)
        let containerWidth = measuredWidth - (UIConstants.Spacing.lg * 2)
        let layout = section.cardLayout(isHomeTab: isHomeTab, cohort: cohort, containerWidth: containerWidth)

        VStack(alignment: .leading, spacing: UIConstants.Spacing.md) {
            if !section.isHero && !section.usesRankedArtwork {
                SectionHeaderView(title: section.title, onTap: {
                    onViewAll?(section)
                })
                    .padding(.horizontal, UIConstants.Spacing.lg)
            }

            if section.isHero {
                heroContent
            } else if section.usesRankedArtwork {
                StorefrontTrendingRankedSectionView(
                    section: section,
                    onViewAll: onViewAll,
                    onSelectItem: onSelectItem
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: UIConstants.Spacing.md) {
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
    private var heroContent: some View {
        switch heroVariant {
        case .carousel:
            StorefrontEntertainmentHeroView(
                items: section.items,
                cohort: cohort,
                onSelectItem: onSelectItem
            )
        case .stackedSports:
            StorefrontSportsHeroView(items: section.items, onSelectItem: onSelectItem)
        case .immersive:
            StorefrontImmersiveHeroView(items: section.items, onSelectItem: onSelectItem)
        }
    }
}

enum StorefrontHeroVariant {
    case carousel
    case stackedSports
    case immersive
}

private extension StorefrontSection {
    var usesRankedArtwork: Bool {
        let source = "\(id) \(title)".lowercased()
        return source.contains("trending") || source.contains("top") || source.contains("rank")
    }
}
