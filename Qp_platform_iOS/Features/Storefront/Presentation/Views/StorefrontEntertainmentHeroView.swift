import SwiftUI

struct StorefrontEntertainmentHeroView: View {
    let items: [StorefrontItem]
    let cohort: QuickplayCohort
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
        VStack(spacing: 14) {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    ForEach(featuredItems) { item in
                    Button {
                        onSelectItem(item)
                    } label: {
                        heroCard(item: item)
                    }
                    .buttonStyle(LiquidButtonPressStyle())
                    .id(item.id)
                }
            }
                .scrollTargetLayout()
                .padding(.horizontal, 27)
            }
            .frame(height: 578)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $currentItemID, anchor: .center)
            .onAppear {
                guard !featuredItems.isEmpty else { return }
                if currentItemID == nil {
                    currentItemID = featuredItems.first?.id
                }
            }

            pageIndicator
        }
    }

    private func heroCard(item: StorefrontItem) -> some View {
        ZStack(alignment: .bottom) {
            heroMedia(item: item, size: CGSize(width: 358, height: 537), ratio: "0-2x3", cornerRadius: 16)
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

                Text(item.title.uppercased())
                    .font(.system(size: 46, weight: .ultraLight))
                    .tracking(5.8)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.65)
                    .padding(.horizontal, 18)

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
        .frame(width: 358, height: 537)
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
        HStack(spacing: 10) {
            SonyGlassPrimaryButton(
                title: cohort == .entertainment ? item.watchLabel : "More Info",
                systemImage: cohort == .entertainment ? AppIcons.Action.play : "info.circle.fill",
                minWidth: cohort == .entertainment ? 208 : 196,
                height: 56
            ) {
                if item.canOpenDetail {
                    onSelectItem(item)
                }
            }

            SonyGlassIconButton(
                systemImage: AppIcons.Action.plus,
                size: 56,
                iconSize: 24,
                cornerStyle: .circle,
                action: {}
            )
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(featuredItems.indices, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(index == currentIndex ? Color(hex: "FBBF1B") : Color.white.opacity(0.22))
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
