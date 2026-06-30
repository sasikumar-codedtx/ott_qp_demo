import SwiftUI

struct StorefrontEntertainmentHeroView: View {
    let items: [StorefrontItem]
    let cohort: QuickplayCohort
    let density: StorefrontCardDensity
    let favoriteIDs: Set<String>
    let onToggleFavorite: (StorefrontItem) -> Void
    let onSelectItem: (StorefrontItem) -> Void

    @State private var currentItemID: String?

    private var featuredItems: [StorefrontItem] {
        let candidates = Array(items.prefix(6))
        return candidates.isEmpty ? items : candidates
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
        VStack(spacing: 15) {
            GeometryReader { proxy in
                let cardSize = heroCardSize(availableWidth: proxy.size.width)

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 10) {
                        ForEach(featuredItems) { item in
                            heroCard(item: item, size: cardSize)
                                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .onTapGesture {
                                    onSelectItem(item)
                                }
                                .id(item.id)
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.horizontal, 27)
                    .frame(height: StorefrontHeroMetrics.mediaHeight)
                    .frame(maxHeight: .infinity, alignment: .center)
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $currentItemID, anchor: .center)
                .onAppear {
                    guard !featuredItems.isEmpty else { return }
                    if currentItemID == nil {
                        currentItemID = featuredItems.first?.id
                    }
                }
            }
            .frame(height: StorefrontHeroMetrics.mediaHeight)

            pageIndicator
        }
    }

    private func heroCard(item: StorefrontItem, size: CGSize) -> some View {
        ZStack(alignment: .bottom) {
            heroMedia(
                item: item,
                size: size,
                ratio: density == .expanded ? "0-16x9" : "0-2x3",
                cornerRadius: 16
            )
            .overlay(
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.08),
                        Color.clear,
                        Color.black.opacity(0.28),
                        Color.black.opacity(0.92),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(heroCardBorder, lineWidth: 1)
            )

            VStack(spacing: 12) {
                if let tagText = item.customTag.nilIfEmpty {
                    heroTag(tagText)
                }
                heroTitle(for: item)
                metadataRow(for: item)
                ctaRow(for: item)
            }
            .padding(.bottom, 26)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
        }
        .frame(width: size.width, height: size.height)
    }

    private func heroTag(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .bold))
            .tracking(0.6)
            .textCase(.uppercase)
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 14)
            .frame(height: 32)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FF5E00"), Color(hex: "7818B4")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 0.5)
                    )
            )
            .shadow(color: Color(hex: "FF5E00").opacity(0.45), radius: 10, x: 0, y: 4)
    }

    private func heroCardSize(availableWidth: CGFloat) -> CGSize {
        switch density {
        case .expanded:
            let width = min(max(availableWidth - 54, 560), 900)
            return CGSize(width: width, height: width * 9 / 16)
        case .tabletPortrait:
            let width = min(max(availableWidth * 0.62, 358), 460)
            return CGSize(width: width, height: width * 1.5)
        case .phone:
            return CGSize(width: 358, height: 537)
        }
    }

    private var heroCardBorder: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(hex: "361828"), location: 0.0),
                .init(color: Color.white.opacity(0.30), location: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    @ViewBuilder
    private func heroTitle(for item: StorefrontItem) -> some View {
        if let titleImageURL = item.titleImageURL(width: 720) {
            PosterImageView(
                url: titleImageURL,
                size: CGSize(width: 252, height: 86),
                cornerRadius: 0,
//                contentMode: .fit
            )
            .frame(width: 252, height: 86)
            .padding(.horizontal, 18)
        } else {
            Text(item.title.uppercased())
                .font(.system(size: 46, weight: .ultraLight))
                .tracking(5.8)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .minimumScaleFactor(0.65)
                .padding(.horizontal, 18)
        }
    }

    private func heroMedia(item: StorefrontItem, size: CGSize, ratio: String, cornerRadius: CGFloat) -> some View {
        Group {
            PosterImageView(
                url: item.imageURL(for: ratio, width: Int(size.width * 3)),
                size: size,
                cornerRadius: cornerRadius
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private func metadataRow(for item: StorefrontItem) -> some View {
        HStack(spacing: 8) {
            if cohort != .entertainment {
                Image(systemName: item.contentType.lowercased().contains("movie") ? "briefcase.fill" : "tv.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.92))
            }

            if let year = item.year {
                heroMetaText(year)
                heroDot
            }

            let genreText = item.genres.prefix(2).joined(separator: ", ")
            heroMetaText(genreText.isEmpty ? item.contentType.capitalized : genreText)

            if item.rating != nil {
                heroDot
                heroMetaText(item.rating ?? "")
            }
        }
    }

    private func ctaRow(for item: StorefrontItem) -> some View {
        HStack(spacing: 8) {
            Button {
                if item.canOpenDetail {
                    onSelectItem(item)
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: cohort == .entertainment ? AppIcons.Action.play : "info.circle.fill")
                        .font(.system(size: 15, weight: .bold))
                        .frame(width: 24, height: 24)

                    Text(cohort == .entertainment ? item.watchLabel : "Watch Now")
                        .font(.system(size: 16, weight: .semibold))
                        .lineLimit(1)
                }
                .foregroundStyle(.white)
                .frame(minWidth: 129)
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(heroLiquidCapsule)
                .clipShape(Capsule(style: .continuous))
            }
            .buttonStyle(LiquidButtonPressStyle())

            Button {
                onToggleFavorite(item)
            } label: {
                Image(systemName: favoriteIDs.contains(item.id) ? "checkmark" : AppIcons.Action.plus)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .padding(10)
                    .background(heroLiquidCircle)
                    .clipShape(Circle())
            }
            .buttonStyle(LiquidButtonPressStyle())
        }
    }

    private var heroLiquidCapsule: some View {
        Capsule(style: .continuous)
            .fill(heroLiquidFill)
            .background(.ultraThinMaterial, in: Capsule(style: .continuous))
            .overlay(
                Capsule(style: .continuous)
                    .stroke(heroLiquidBorder, lineWidth: 1.15)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 0.5)
                    .padding(1)
            )
            .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 8)
            .shadow(color: Color.white.opacity(0.11), radius: 2, x: -1, y: -1)
    }

    private var heroLiquidCircle: some View {
        Circle()
            .fill(heroLiquidFill)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(
                Circle()
                    .stroke(heroLiquidBorder, lineWidth: 1.15)
            )
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.14), lineWidth: 0.5)
                    .padding(1)
            )
            .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 8)
            .shadow(color: Color.white.opacity(0.11), radius: 2, x: -1, y: -1)
    }

    private var heroLiquidFill: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.28),
                Color(hex: "8F8F8F").opacity(0.19),
                Color.black.opacity(0.38)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var heroLiquidBorder: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.86),
                Color(hex: "CFCFCF").opacity(0.48),
                Color.white.opacity(0.18)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(featuredItems.indices, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(index == currentIndex ? Color(hex: "FBBF1B") : Color.white.opacity(0.2))
                    .frame(width: index == currentIndex ? 24 : 6, height: 6)
            }
        }
    }

    private func heroMetaText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(.white.opacity(0.92))
            .lineLimit(1)
    }

    private var heroDot: some View {
        Circle()
            .fill(Color.white.opacity(0.55))
            .frame(width: 4, height: 4)
    }
}
