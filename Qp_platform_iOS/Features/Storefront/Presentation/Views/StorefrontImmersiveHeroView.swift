import SwiftUI

struct StorefrontImmersiveHeroView: View {
    let items: [StorefrontItem]
    let topChromeHeight: CGFloat
    let onSelectItem: (StorefrontItem) -> Void
    @State private var currentItemID: String?

    private var visualHeight: CGFloat {
        StorefrontHeroMetrics.mediaHeight + topChromeHeight
    }

    private var reservedHeight: CGFloat {
        StorefrontHeroMetrics.reservedHeight(topChromeHeight: topChromeHeight)
    }

    private var featuredItems: [StorefrontItem] {
        Array(items.prefix(5))
    }

    private var currentIndex: Int {
        guard
            let currentItemID,
            let index = featuredItems.firstIndex(where: { $0.id == currentItemID })
        else {
            return 0
        }
        return index
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            GeometryReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(featuredItems) { item in
                            Button {
                                onSelectItem(item)
                            } label: {
                                immersiveCard(item: item, width: proxy.size.width)
                            }
                            .buttonStyle(LiquidButtonPressStyle())
                            .id(item.id)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $currentItemID, anchor: .center)
            }
            .frame(height: visualHeight)
            .frame(maxHeight: .infinity, alignment: .top)
            .onAppear {
                if currentItemID == nil {
                    currentItemID = featuredItems.first?.id
                }
            }

            HStack(spacing: 7) {
                ForEach(featuredItems.indices, id: \.self) { index in
                    Capsule(style: .continuous)
                        .fill(index == currentIndex ? Color.white : Color.white.opacity(0.25))
                        .frame(width: index == currentIndex ? 28 : 7, height: 7)
                }
            }
            .padding(.bottom, 6)
        }
        .frame(height: reservedHeight)
        .clipped(antialiased: false)
    }

    private func immersiveCard(item: StorefrontItem, width: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            backgroundMedia(item: item, width: width)

            LinearGradient(
                colors: [
                    Color.black.opacity(0.0),
                    Color.black.opacity(0.08),
                    Color.black.opacity(0.68),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 14) {
                Text(item.title)
                    .font(.system(size: 34, weight: .black))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 30)

                Text(metaLine(for: item))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)

                if !item.description.isEmpty {
                    Text(item.description)
                        .font(.system(size: 15, weight: .medium))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.76))
                        .lineLimit(3)
                        .padding(.horizontal, 34)
                }

                HStack(spacing: 12) {
                    SonyGlassPrimaryButton(
                        title: item.previewURL == nil ? "More Info" : "Watch Preview",
                        systemImage: "info.circle.fill",
                        minWidth: 196,
                        height: 54
                    ) {
                        onSelectItem(item)
                    }

                    SonyGlassIconButton(
                        systemImage: AppIcons.Action.plus,
                        size: 54,
                        iconSize: 23,
                        cornerStyle: .circle,
                        action: {}
                    )
                }
            }
            .padding(.bottom, 28)

        }
        .frame(width: width, height: visualHeight)
    }

    private func backgroundMedia(item: StorefrontItem, width: CGFloat) -> some View {
        Group {
            PosterImageView(
                url: item.imageURL(for: "0-16x9", width: Int(width * 3)),
                size: CGSize(width: width, height: visualHeight),
                cornerRadius: 0
            )
        }
        .frame(width: width, height: visualHeight)
        .overlay(Color.black.opacity(0.2))
    }

    private func metaLine(for item: StorefrontItem) -> String {
        let genreText = item.genres.prefix(2).joined(separator: " • ")
        let parts = [item.contentType.capitalized.nilIfEmpty, genreText.nilIfEmpty, item.rating != nil ? "A" : nil].compactMap { $0 }
        return parts.joined(separator: " • ")
    }
}
