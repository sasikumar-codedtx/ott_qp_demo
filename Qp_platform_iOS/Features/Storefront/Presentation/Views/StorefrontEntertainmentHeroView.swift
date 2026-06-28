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
                    .stroke(Color(hex: "361828"), lineWidth: 1)
            )

            VStack(spacing: 12) {
                if let badgeTitle {
                    Text(badgeTitle)
                        .font(.system(size: 12, weight: .black))
                        .tracking(0.8)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "EC2027"), Color(hex: "5612CA")],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 4, style: .continuous)
                        )
                }

                heroTitle(for: item)

                metadataRow(for: item)

                if !item.description.isEmpty, cohort != .entertainment {
                    Text(item.description)
                        .font(.system(size: 15, weight: .regular))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.white.opacity(0.78))
                        .lineLimit(3)
                        .padding(.horizontal, 16)
                }

                ctaRow(for: item)

                if cohort != .entertainment {
                    Text(secondaryHeroLine(for: item))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.46))
                }
            }
            .padding(.bottom, 26)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
        }
        .frame(width: size.width, height: size.height)
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
                .lineLimit(2)
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
                heroMetaText("A")
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

                    Text(cohort == .entertainment ? item.watchLabel : "More Info")
                        .font(.system(size: 16, weight: .semibold))
                        .lineLimit(1)
                }
                .foregroundStyle(.white)
                .frame(minWidth: 129)
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(heroControlBackground)
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
                    .background(heroControlBackground)
                    .clipShape(Circle())
                    .shadow(color: Color(hex: "CACACA").opacity(0.13), radius: 3, x: -1, y: 1)
            }
            .buttonStyle(LiquidButtonPressStyle())
        }
    }

    private var heroControlBackground: some View {
        LinearGradient(
            colors: [
                Color.white.opacity(0.2),
                Color(hex: "CECECE").opacity(0.2)
            ],
            startPoint: .top,
            endPoint: .bottom
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

    private var badgeTitle: String? {
        switch cohort {
        case .entertainment:
            return "NEW MOVIE"
        case .realityShows:
            return "TRENDING NOW"
        case .kids:
            return "KIDS PICK"
        case .sports:
            return nil
        }
    }

    private func secondaryHeroLine(for item: StorefrontItem) -> String {
        if item.isPremium {
            return "Included with Premium"
        }

        if let runtimeSeconds = item.runtimeSeconds, runtimeSeconds > 0 {
            let minutes = max(runtimeSeconds / 60, 1)
            return "\(minutes) mins"
        }

        return "Watch on Sony LIV"
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
