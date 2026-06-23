import SwiftUI

struct StorefrontSportsHeroView: View {
    let items: [StorefrontItem]
    let onSelectItem: (StorefrontItem) -> Void
    @State private var currentItemID: String?

    private var featuredItems: [StorefrontItem] {
        Array(items.prefix(6))
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
        VStack(spacing: 18) {
            GeometryReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: -18) {
                        ForEach(Array(featuredItems.enumerated()), id: \.element.id) { index, item in
                            Button {
                                currentItemID = item.id
                                onSelectItem(item)
                            } label: {
                                sportsCard(item: item, index: index, containerWidth: proxy.size.width)
                            }
                            .buttonStyle(LiquidButtonPressStyle())
                            .id(item.id)
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.horizontal, 22)
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $currentItemID, anchor: .center)
            }
            .frame(height: 486)
            .onAppear {
                if currentItemID == nil {
                    currentItemID = featuredItems.first?.id
                }
            }

            HStack(spacing: 4) {
                ForEach(featuredItems.indices, id: \.self) { index in
                    Capsule(style: .continuous)
                        .fill(index == currentIndex ? Color(hex: "FBBF1B") : Color.white.opacity(0.2))
                        .frame(width: index == currentIndex ? 24 : 6, height: 6)
                }
            }
        }
    }

    private func sportsCard(item: StorefrontItem, index: Int, containerWidth: CGFloat) -> some View {
        let cardWidth = min(274, containerWidth * 0.68)
        let cardHeight: CGFloat = 448
        let isActive = index == currentIndex

        return ZStack(alignment: .bottomLeading) {
            heroMedia(item: item, size: CGSize(width: cardWidth, height: cardHeight), width: 980, cornerRadius: 18)

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.16), Color.black.opacity(0.84)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    liveBadge

                    Text(item.title.replacingOccurrences(of: " vs ", with: " vs "))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Text(item.description.nilIfEmpty ?? item.primaryMetaText.nilIfEmpty ?? item.watchLabel)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    HStack(spacing: 3) {
                        Image(systemName: "soccerball")
                            .font(.system(size: 11, weight: .regular))
                        Text(item.contentType.capitalized == "Tvchannel" ? "Football" : item.contentType.capitalized)
                            .font(.system(size: 12, weight: .regular))
                    }
                    .foregroundStyle(.white.opacity(0.92))
                }

                floatingControls
            }
            .padding(18)
        }
        .frame(width: cardWidth, height: cardHeight)
        .background(Color.black.opacity(0.001))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isActive ? Color(hex: "2E95D3").opacity(0.95) : Color.white.opacity(0.12), lineWidth: isActive ? 1.4 : 1)
        )
        .scaleEffect(isActive ? 1 : 0.94)
        .offset(y: isActive ? 0 : 26)
        .shadow(color: Color(hex: "0A65A8").opacity(isActive ? 0.34 : 0.12), radius: isActive ? 24 : 10, x: 0, y: 10)
        .animation(.spring(response: 0.34, dampingFraction: 0.84), value: currentIndex)
    }

    private func heroMedia(item: StorefrontItem, size: CGSize, width: Int, cornerRadius: CGFloat) -> some View {
        Group {
            PosterImageView(
                url: item.imageURL(for: "0-2x3", width: width),
                size: size,
                cornerRadius: cornerRadius
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private var liveBadge: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(Color(hex: "E42121"))
                .frame(width: 4, height: 4)
            Text("Live")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.white.opacity(0.18))
        )
    }

    private var floatingControls: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(Circle().fill(Color.black.opacity(0.28)))
                    .overlay(Circle().stroke(Color.white.opacity(0.16), lineWidth: 1))
                Image(systemName: AppIcons.Action.plus)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 46, height: 46)

            ZStack {
                Circle()
                    .fill(Color.white)
                    .shadow(color: Color.white.opacity(0.2), radius: 18, x: 0, y: 4)
                Image(systemName: AppIcons.Action.play)
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(.black)
                    .offset(x: 1)
            }
            .frame(width: 54, height: 54)
        }
    }
}
