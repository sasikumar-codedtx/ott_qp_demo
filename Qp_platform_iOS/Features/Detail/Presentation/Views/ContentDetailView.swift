import SwiftUI

struct ContentDetailView: View {
    @ObservedObject var viewModel: ContentDetailViewModel
    let onBack: () -> Void
    let onPlay: (ContentDetail, StorefrontItem?) -> Void
    let onSelectRecommendation: (StorefrontItem) -> Void
    @State private var isDescriptionExpanded = false

    private let recommendationColumns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 3)
    private let detailTabs = [
        AppStrings.Detail.moreLikeThis,
        AppStrings.Detail.moments,
        AppStrings.Detail.castAndMore
    ]

    var body: some View {
        GeometryReader { proxy in
            content(width: proxy.size.width)
                .ignoresSafeArea(edges: .top)
                .task(id: viewModel.requestKey) {
                    isDescriptionExpanded = false
                    await viewModel.loadIfNeeded()
                }
        }
    }

    @ViewBuilder
    private func content(width: CGFloat) -> some View {
        if let detail = viewModel.detail {
            ZStack(alignment: .top) {
                Color(hex: "0A0A0A").ignoresSafeArea()

                hero(detail, width: width)
                    .frame(height: heroHeight(for: width))
                    .frame(maxHeight: .infinity, alignment: .top)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        Spacer()
                            .frame(height: max(heroHeight(for: width) - 64, 300))

                        detailContent(detail, width: width)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 42)
                }
            }
        } else if viewModel.isLoading {
            LoadingView()
        } else {
            ErrorView(
                title: AppStrings.Detail.unavailableTitle,
                message: viewModel.errorMessage ?? AppStrings.Storefront.retryMessage,
                onRetry: {
                    Task { await viewModel.load() }
                }
            )
        }
    }

    private func hero(_ detail: ContentDetail, width: CGFloat) -> some View {
        ZStack(alignment: .top) {
            PosterImageView(
                url: detail.imageURL(for: "0-2x3", width: Int(width * 3)),
                size: CGSize(width: width, height: heroHeight(for: width)),
                cornerRadius: 0
            )

            LinearGradient(
                colors: [
                    Color(hex: "0A0A0A").opacity(0.8),
                    Color(hex: "0A0A0A").opacity(0.35),
                    Color(hex: "0A0A0A").opacity(0),
                    Color(hex: "0A0A0A").opacity(0.36),
                    Color(hex: "0A0A0A")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(width: width, height: heroHeight(for: width))
        .clipped()
    }

    private func heroHeight(for width: CGFloat) -> CGFloat {
        max(413, width)
    }

    private func detailContent(_ detail: ContentDetail, width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            titleArt(detail)
            metaLine(detail)
            watchButton(detail)
            descriptionBlock(detail)
            previewLabel(detail)
            actionButtonRow
            sponsorRow(detail)
            tabRow
            tabContent(detail, width: width)
        }
    }

    private func titleArt(_ detail: ContentDetail) -> some View {
        Text(detail.title.uppercased())
            .font(.system(size: 41, weight: .black, design: .rounded))
            .tracking(-1.5)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.58)
            .foregroundStyle(
                LinearGradient(
                    colors: [Color(hex: "FFF75A"), Color(hex: "F5A623"), Color.white],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .shadow(color: Color.black.opacity(0.55), radius: 8, x: 0, y: 3)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 78)
            .padding(.bottom, 8)
    }

    private func metaLine(_ detail: ContentDetail) -> some View {
        Text(detail.metaLine)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(Color(hex: "BBBBBB"))
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .frame(maxWidth: .infinity)
    }

    private func watchButton(_ detail: ContentDetail) -> some View {
        Button {
            onPlay(detail, viewModel.seed)
        } label: {
            Text(viewModel.seed?.progress != nil ? "Resume" : AppStrings.Detail.watchNow)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(hex: "1E1E1E"))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(LiquidGlassBackground(cornerRadius: 10, tone: .light, isHighlighted: true))
        }
        .buttonStyle(LiquidButtonPressStyle())
    }

    private func descriptionBlock(_ detail: ContentDetail) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(detail.description)
                .font(.system(size: 14, weight: .regular))
                .lineSpacing(2)
                .foregroundStyle(Color(hex: "FEFEFE"))
                .lineLimit(isDescriptionExpanded ? nil : 2)
                .animation(.easeInOut(duration: 0.2), value: isDescriptionExpanded)

            if detail.description.count > 88 {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isDescriptionExpanded.toggle()
                    }
                } label: {
                    Text(isDescriptionExpanded ? "View Less" : "View More")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .buttonStyle(LiquidButtonPressStyle())
            }
        }
    }

    @ViewBuilder
    private func previewLabel(_ detail: ContentDetail) -> some View {
        if detail.hasFreePreview || detail.previewURL != nil {
            Text("Free preview Available ( 10 mins)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color(hex: "F5A623"))
                .lineLimit(1)
        }
    }

    private var actionButtonRow: some View {
        HStack(spacing: 8) {
            DetailActionButton(systemImage: "movieclapper", cornerStyle: .leading, action: {})
            DetailActionButton(systemImage: AppIcons.Action.download, action: {})
            DetailActionButton(systemImage: "bookmark.badge.plus", action: {})
            DetailActionButton(systemImage: "hand.thumbsup", action: {})
            DetailActionButton(systemImage: AppIcons.Action.share, iconSize: 22, action: {})
            DetailActionButton(systemImage: AppIcons.Action.sparkles, cornerStyle: .trailing, isHighlighted: true, action: {})
        }
        .overlay(alignment: .bottomTrailing) {
            if viewModel.detail?.momentSearchEnabled == true {
                searchMomentsPill
                    .offset(x: 34, y: 36)
            }
        }
    }

    private var searchMomentsPill: some View {
        HStack(spacing: 4) {
            Image(systemName: AppIcons.Action.sparkles)
                .font(.system(size: 13, weight: .bold))
            Text("Search Moments")
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(Color(hex: "202020"))
        .padding(.horizontal, 8)
        .frame(height: 28)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.5), radius: 4, x: 0, y: 4)
        )
    }

    private func sponsorRow(_ detail: ContentDetail) -> some View {
        HStack(spacing: 5) {
            Text("SPONSORED BY")
                .font(.system(size: 7, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.78))
            Text(detail.sponsorNames.first ?? "KFC")
                .font(.system(size: 15, weight: .black))
                .italic()
                .foregroundStyle(.white)
        }
        .frame(height: 30)
    }

    private var tabRow: some View {
        HStack(spacing: 0) {
            ForEach(detailTabs, id: \.self) { tab in
                Button {
                    viewModel.selectedTab = tab
                } label: {
                    VStack(spacing: 13) {
                        Text(tab)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        Rectangle()
                            .fill(viewModel.selectedTab == tab ? Color.white : Color.clear)
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 13)
                    .padding(.top, 14)
                }
                .buttonStyle(LiquidButtonPressStyle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func tabContent(_ detail: ContentDetail, width: CGFloat) -> some View {
        switch viewModel.selectedTab {
        case AppStrings.Detail.moreLikeThis:
            recommendationSection(width: width)
        case AppStrings.Detail.moments:
            momentsSection(detail)
        default:
            castSection(detail)
        }
    }

    private func recommendationSection(width: CGFloat) -> some View {
        let cardWidth = max(96, (width - 40) / 3)
        let cardHeight = cardWidth * 1.5
        let visibleItems = Array(viewModel.recommendations.prefix(6))
        let featuredItem = Array(viewModel.recommendations.dropFirst(6)).first ?? viewModel.recommendations.first

        return VStack(spacing: 4) {
            if viewModel.recommendations.isEmpty {
                EmptyStateView(title: AppStrings.Detail.moreLikeThis, message: AppStrings.Detail.noRecommendations, systemImage: AppIcons.Action.film)
                    .padding(.top, 18)
            } else {
                LazyVGrid(columns: recommendationColumns, spacing: 4) {
                    ForEach(visibleItems) { item in
                        DetailRecommendationCard(
                            item: item,
                            size: CGSize(width: cardWidth, height: cardHeight),
                            onSelect: onSelectRecommendation
                        )
                    }
                }

                if let featuredItem {
                    Button {
                        onSelectRecommendation(featuredItem)
                    } label: {
                        DetailFeaturedRecommendationCard(item: featuredItem, width: width - 32)
                    }
                    .buttonStyle(LiquidButtonPressStyle())
                }
            }
        }
    }

    private func momentsSection(_ detail: ContentDetail) -> some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.md) {
            Text("Search exact scenes, songs, and standout moments from \(detail.title).")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.76))

            Text(detail.momentSearchEnabled ? AppStrings.Detail.notReady : AppStrings.Detail.notAvailable)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(UIConstants.Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LiquidGlassBackground(cornerRadius: UIConstants.CornerRadius.lg, tone: .dark))
        }
        .padding(.top, 8)
    }

    private func castSection(_ detail: ContentDetail) -> some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.lg) {
            if !detail.directorNames.isEmpty {
                VStack(alignment: .leading, spacing: UIConstants.Spacing.sm) {
                    Text("Director")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.white.opacity(0.56))

                    Text(detail.directorNames.joined(separator: ", "))
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }

            if detail.cast.isEmpty {
                EmptyStateView(title: AppStrings.Detail.castAndMore, message: "Cast information will appear here once we connect the full credits flow.", systemImage: "person.2")
            } else {
                LazyVGrid(columns: recommendationColumns, spacing: UIConstants.Spacing.md) {
                    ForEach(detail.cast) { person in
                        VStack(spacing: UIConstants.Spacing.sm) {
                            CastAvatarTile(person: person, size: UIConstants.Size.posterWidth)
                            Text(person.name)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
            }
        }
        .padding(.top, 8)
    }
}

private struct DetailActionButton: View {
    enum CornerStyle {
        case leading
        case middle
        case trailing
    }

    let systemImage: String
    var iconSize: CGFloat = 24
    var cornerStyle: CornerStyle = .middle
    var isHighlighted = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(backgroundShape)
                .contentShape(shape)
        }
        .buttonStyle(LiquidButtonPressStyle())
    }

    private var shape: some Shape {
        UnevenRoundedRectangle(
            topLeadingRadius: cornerStyle == .leading ? 20 : 8,
            bottomLeadingRadius: cornerStyle == .leading ? 20 : 8,
            bottomTrailingRadius: cornerStyle == .trailing ? 20 : 8,
            topTrailingRadius: cornerStyle == .trailing ? 20 : 8,
            style: .continuous
        )
    }

    private var backgroundShape: some View {
        shape
            .fill(.ultraThinMaterial)
            .overlay(shape.fill(Color.white.opacity(0.1)))
            .overlay(
                shape.stroke(
                    isHighlighted ? Color(hex: "FF5E00") : Color.white.opacity(0.08),
                    lineWidth: isHighlighted ? 2 : 1
                )
            )
            .overlay(
                shape.fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "FF5E00").opacity(isHighlighted ? 0.42 : 0.08),
                            Color(hex: "7818B4").opacity(isHighlighted ? 0.36 : 0.05),
                            Color.clear
                        ],
                        center: .bottomTrailing,
                        startRadius: 1,
                        endRadius: 44
                    )
                )
                .blendMode(.screen)
            )
            .shadow(color: Color.black.opacity(0.32), radius: 7, x: 0, y: 4)
    }
}

private struct DetailRecommendationCard: View {
    let item: StorefrontItem
    let size: CGSize
    let onSelect: (StorefrontItem) -> Void

    var body: some View {
        Button {
            onSelect(item)
        } label: {
            ZStack(alignment: .bottom) {
                PosterImageView(
                    url: item.imageURL(for: "0-2x3", width: Int(size.width * 3)),
                    size: size,
                    cornerRadius: 0
                )

                if item.isPremium || item.contentType.lowercased().contains("episode") {
                    Text(item.contentType.lowercased().contains("episode") ? "New Episode" : "New Movie")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .frame(height: 18)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color(hex: "4732FF").opacity(0.9))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(Color(hex: "CFCFCF"), lineWidth: 1)
                                )
                        )
                        .padding(.bottom, 8)
                }
            }
            .frame(width: size.width, height: size.height)
            .clipped()
        }
        .buttonStyle(LiquidButtonPressStyle())
    }
}

private struct DetailFeaturedRecommendationCard: View {
    let item: StorefrontItem
    let width: CGFloat

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            PosterImageView(
                url: item.imageURL(for: "0-2x3", width: Int(width * 3)),
                size: CGSize(width: width, height: width * 1.78),
                cornerRadius: 0
            )

            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.2), Color.black.opacity(0.92)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 9) {
                Text(item.title.uppercased())
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(item.description.nilIfEmpty ?? item.primaryMetaText.nilIfEmpty ?? "A gripping story with powerful performances and unexpected twists.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.82))
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(item.watchLabel == "Watch Now" ? "Watch Full Movie" : item.watchLabel)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 12)
                        .frame(height: 34)
                        .background(LiquidGlassBackground(cornerRadius: 999, tone: .light, isHighlighted: true))

                    Image(systemName: "info.circle")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(LiquidGlassCircleBackground(tone: .dark))
                }
            }
            .padding(.horizontal, 15)
            .padding(.bottom, 18)
        }
        .frame(width: width, height: width * 1.78)
        .clipped()
    }
}

private struct CastAvatarTile: View {
    let person: ContentPerson
    let size: CGFloat

    var body: some View {
        ZStack {
            if let url = person.imageURL(width: Int(size * 3)) {
                PosterImageView(
                    url: url,
                    size: CGSize(width: size, height: size),
                    cornerRadius: UIConstants.CornerRadius.lg
                )
            } else {
                fallbackAvatar
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: UIConstants.CornerRadius.lg, style: .continuous))
    }

    private var fallbackAvatar: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "2B173A"),
                    Color(hex: "141018"),
                    Color(hex: "3A170D")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color(hex: "F5A623").opacity(0.18))
                .blur(radius: 18)
                .offset(x: -18, y: -16)

            Circle()
                .fill(Color(hex: "7818B4").opacity(0.2))
                .blur(radius: 18)
                .offset(x: 18, y: 16)

            Text(person.initials)
                .font(.system(size: 28, weight: .black))
                .foregroundStyle(.white)
        }
        .overlay(
            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.lg, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}
