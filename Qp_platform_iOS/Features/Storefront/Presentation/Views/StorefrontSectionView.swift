import SwiftUI

struct StorefrontSectionView: View {
    let section: StorefrontSection
    let isHomeTab: Bool
    let onSelectItem: (StorefrontItem) -> Void

    var body: some View {
        let style = section.cardStyle(isHomeTab: isHomeTab)
        let containerWidth = UIScreen.main.bounds.width - (UIConstants.Spacing.lg * 2)
        let layout = section.cardLayout(isHomeTab: isHomeTab, containerWidth: containerWidth)

        VStack(alignment: .leading, spacing: UIConstants.Spacing.md) {
            if !section.isHero {
                SectionHeaderView(title: section.title)
                    .padding(.horizontal, UIConstants.Spacing.lg)
            }

            switch style {
            case .homeHero, .featuredHero:
                StorefrontHeroCarouselView(items: section.items, style: style, layout: layout, onSelectItem: onSelectItem)
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
