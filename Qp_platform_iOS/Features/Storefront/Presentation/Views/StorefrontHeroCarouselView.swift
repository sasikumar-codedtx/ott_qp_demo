import SwiftUI

struct StorefrontHeroCarouselView: View {
    let items: [StorefrontItem]
    let style: StorefrontCardStyle
    let layout: StorefrontCardLayout
    let onSelectItem: (StorefrontItem) -> Void
    @State private var currentIndex = 0

    var body: some View {
        VStack(spacing: UIConstants.Spacing.md) {
            TabView(selection: $currentIndex) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    StorefrontCardView(item: item, style: style, layout: layout, rank: nil, onSelect: onSelectItem)
                        .tag(index)
                        .padding(.horizontal, style == .homeHero ? 20 : 28)
                }
            }
            .frame(height: layout.size.height + 21)
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: UIConstants.Spacing.xs + 2) {
                ForEach(items.indices, id: \.self) { index in
                    Capsule(style: .continuous)
                        .fill(index == currentIndex ? Color.white : Color.white.opacity(0.22))
                        .frame(width: index == currentIndex ? 24 : 6, height: 6)
                }
            }
        }
    }
}
