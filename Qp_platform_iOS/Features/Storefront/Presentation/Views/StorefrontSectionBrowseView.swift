import SwiftUI

struct StorefrontSectionBrowseView: View {
    @ObservedObject var viewModel: StorefrontSectionBrowseViewModel
    let onBack: () -> Void
    let onSelectItem: (StorefrontItem) -> Void

    var body: some View {
        GeometryReader { proxy in
            let containerWidth = proxy.size.width - 32
            let density = cardDensity(for: proxy.size)
            let layout = viewModel.section?.browseGridLayout(
                containerWidth: containerWidth,
                density: density
            ) ?? StorefrontCardLayout(
                size: CGSize(width: 124, height: 186),
                overlayHeight: 0,
                visibleCount: density.portraitVisibleCount
            )
            let style = viewModel.section?.browseGridStyle() ?? .poster
            let showsCardTitles = viewModel.shouldShowCardTitles
            let columns = Array(
                repeating: GridItem(.fixed(layout.size.width), spacing: 4, alignment: .top),
                count: layout.visibleCount
            )

            ZStack(alignment: .top) {
                Color(hex: "0A0A0A")
                    .ignoresSafeArea()

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "525992"), Color(hex: "424781")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 130)
                    .blur(radius: 155)
                    .opacity(0.92)
                    .offset(y: -10)

                VStack(spacing: 0) {
                    if viewModel.shouldShowInitialSkeleton {
                        skeleton(columns: columns, layout: layout)
                    } else if let errorMessage = viewModel.errorMessage, viewModel.items.isEmpty {
                        ErrorView(title: viewModel.title.nilIfEmpty ?? AppStrings.Storefront.unavailableTitle, message: errorMessage, onRetry: {
                            Task { await viewModel.loadIfNeeded() }
                        })
                    } else if viewModel.isRecommendedSection {
                        recommendedBrowsePage
                    } else {
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVGrid(columns: columns, alignment: .center, spacing: 4) {
                                if viewModel.isRefreshing {
                                    StorefrontBrowseRefreshIndicator()
                                        .gridCellColumns(layout.visibleCount)
                                        .padding(.bottom, 8)
                                }

                                ForEach(viewModel.items) { item in
                                    browseGridCard(
                                        item: item,
                                        style: style,
                                        layout: layout,
                                        showsTitle: showsCardTitles
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 6)
                            .padding(.bottom, 8)

                            if viewModel.isLoadingMore {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.vertical, 24)
                            } else if viewModel.hasMoreItems {
                                Color.clear
                                    .frame(height: 1)
                                    .onAppear {
                                        Task { await viewModel.loadMoreIfNeeded() }
                                    }
                            } else {
                                Color.clear.frame(height: 32)
                            }
                        }
                    }
                }
                .padding(.top, proxy.safeAreaInsets.top + 16)
            }
        }
        .task(id: viewModel.loadIdentity) {
            await viewModel.loadAfterPushAnimationIfNeeded()
        }
        .navigationBarBackButtonHidden(true)
        .routeNavigationOverlay(title: viewModel.title, onBack: onBack)
    }

    private func browseGridCard(
        item: StorefrontItem,
        style: StorefrontCardStyle,
        layout: StorefrontCardLayout,
        showsTitle: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            StorefrontCardView(
                item: item,
                style: style,
                layout: layout,
                rank: nil,
                onSelect: onSelectItem
            )

            if showsTitle {
                Text(item.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.92))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(width: layout.size.width, alignment: .leading)
            }
        }
        .frame(width: layout.size.width, alignment: .topLeading)
    }

    private func cardDensity(for size: CGSize) -> StorefrontCardDensity {
        let idiom = UIDevice.current.userInterfaceIdiom
        guard idiom != .phone else { return .phone }
        return size.width > size.height ? .expanded : .tabletPortrait
    }

    private var recommendedBrowsePage: some View {
        GeometryReader { proxy in
            let density = cardDensity(for: proxy.size)
            let horizontalPadding: CGFloat = 18
            let containerWidth = proxy.size.width - (horizontalPadding * 2)
            let featureHeight = containerWidth * 9 / 16
            let columnCount = density.landscapeVisibleCount
            let totalSpacing = CGFloat(columnCount - 1) * 10
            let gridWidth = (containerWidth - totalSpacing) / CGFloat(columnCount)
            let layout = StorefrontCardLayout(
                size: CGSize(width: gridWidth, height: gridWidth * 9 / 16),
                overlayHeight: 54,
                visibleCount: columnCount
            )
            let featureItem = viewModel.items.first
            let gridItems = featureItem.map { first in viewModel.items.filter { $0.id != first.id } } ?? viewModel.items

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    if viewModel.isRefreshing {
                        StorefrontBrowseRefreshIndicator()
                            .frame(maxWidth: .infinity)
                    }

                    if let featureItem {
                        recommendedFeatureCard(item: featureItem, width: containerWidth, height: featureHeight)
                            .padding(.horizontal, horizontalPadding)
                    }

                    recommendedChipRow

                    LazyVGrid(
                        columns: Array(
                            repeating: GridItem(.fixed(gridWidth), spacing: 10, alignment: .top),
                            count: columnCount
                        ),
                        alignment: .center,
                        spacing: 14
                    ) {
                        ForEach(gridItems) { item in
                            StorefrontCardView(
                                item: item,
                                style: .landscape,
                                layout: layout,
                                rank: nil,
                                onSelect: onSelectItem
                            )
                        }
                    }
                    .padding(.horizontal, horizontalPadding)

                    if viewModel.isLoadingMore {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                    } else if viewModel.hasMoreItems {
                        Color.clear
                            .frame(height: 1)
                            .onAppear {
                                Task { await viewModel.loadMoreIfNeeded() }
                            }
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 38)
            }
        }
    }

    private func recommendedFeatureCard(item: StorefrontItem, width: CGFloat, height: CGFloat) -> some View {
        Button {
            onSelectItem(item)
        } label: {
            ZStack(alignment: .bottomLeading) {
                PosterImageView(
                    url: item.imageURL(for: "0-16x9", width: Int(width * 3)),
                    size: CGSize(width: width, height: height),
                    cornerRadius: 18
                )

                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.34), Color.black.opacity(0.92)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommended")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(hex: "F5B919"))
                        .padding(.horizontal, 10)
                        .frame(height: 24)
                        .background(Capsule().fill(Color.black.opacity(0.48)))

                    Text(item.title)
                        .font(.system(size: 24, weight: .black))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    if !item.primaryMetaText.isEmpty {
                        Text(item.primaryMetaText)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.74))
                            .lineLimit(1)
                    }
                }
                .padding(18)
            }
            .frame(width: width, height: height)
        }
        .buttonStyle(LiquidButtonPressStyle())
    }

    private var recommendedChipRow: some View {
        let chips = viewModel.recommendationFilterTitles
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(chips, id: \.self) { chip in
                    Text(chip)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(chip == chips.first ? .black : .white.opacity(0.78))
                        .padding(.horizontal, 16)
                        .frame(height: 34)
                        .background(
                            Capsule(style: .continuous)
                                .fill(chip == chips.first ? Color.white : Color.white.opacity(0.08))
                                .overlay(
                                    Capsule(style: .continuous)
                                        .stroke(Color.white.opacity(chip == chips.first ? 0 : 0.12), lineWidth: 1)
                                )
                        )
                }
            }
            .padding(.horizontal, 18)
        }
    }

    private func skeleton(columns: [GridItem], layout: StorefrontCardLayout) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: columns, alignment: .center, spacing: 4) {
                ForEach(0..<18, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                        .overlay { ShimmerView() }
                        .frame(width: layout.size.width, height: layout.size.height)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
    }
}

private struct StorefrontBrowseRefreshIndicator: View {
    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
                .tint(.white)

            Text("Refreshing")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.82))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.white.opacity(0.08), in: Capsule())
    }
}
