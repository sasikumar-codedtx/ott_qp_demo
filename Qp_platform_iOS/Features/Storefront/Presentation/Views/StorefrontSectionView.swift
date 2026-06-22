import SwiftUI

struct StorefrontSectionView: View {
    let section: StorefrontSection
    let isHomeTab: Bool
    let cohort: QuickplayCohort
    let onViewAll: ((StorefrontSection) -> Void)?
    let onSelectItem: (StorefrontItem) -> Void

    var body: some View {
        let style = section.cardStyle(isHomeTab: isHomeTab, cohort: cohort)
        let containerWidth = UIScreen.main.bounds.width - (UIConstants.Spacing.lg * 2)
        let layout = section.cardLayout(isHomeTab: isHomeTab, cohort: cohort, containerWidth: containerWidth)

        VStack(alignment: .leading, spacing: UIConstants.Spacing.md) {
            if !section.isHero {
                SectionHeaderView(title: section.title, onTap: {
                    onViewAll?(section)
                })
                    .padding(.horizontal, UIConstants.Spacing.lg)
            }

            switch style {
            case .homeHero, .featuredHero:
                StorefrontEntertainmentHeroView(
                    items: section.items,
                    cohort: cohort,
                    onSelectItem: onSelectItem
                )
            case .sportsHero:
                StorefrontSportsHeroView(items: section.items, onSelectItem: onSelectItem)
            default:
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: UIConstants.Spacing.md) {
                        ForEach(Array(section.items.enumerated()), id: \.element.id) { index, item in
                            StorefrontCardView(
                                item: item,
                                style: style,
                                layout: layout,
                                rank: section.title.lowercased().contains("trending") ? index + 1 : nil,
                                onSelect: onSelectItem
                            )
                        }
                    }
                    .padding(.horizontal, UIConstants.Spacing.lg)
                }
            }
        }
    }
}
