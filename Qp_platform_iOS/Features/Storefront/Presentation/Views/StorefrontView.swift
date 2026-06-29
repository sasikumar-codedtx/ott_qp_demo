import SwiftUI

struct StorefrontView: View {
    @ObservedObject var viewModel: StorefrontViewModel
    let bottomSelection: BottomNavigationSelection
    let profileName: String
    let profileImageName: String?
    let onSelectItem: (StorefrontItem) -> Void
    let onOpenHome: () -> Void
    let onOpenSearch: () -> Void
    let onOpenShorts: () -> Void
    let onOpenHot: () -> Void
    let onProfileTap: () -> Void
    let onViewAllSection: (StorefrontSection) -> Void
    var hidesFirstStorefrontTabInDock = false
    var showsStorefrontHeader = true
    var showsBottomChrome = true
    var loadsInitialOnAppear = true
    var scrollsToTopOnTabChange = true
    var additionalTopChromeHeight: CGFloat = 0
    var onOpenStorefrontTab: ((StorefrontTab) -> Void)?
    @State private var isTabMenuPresented = false
    private var isHotPresentation: Bool { bottomSelection == .hot }
    private static let scrollTopID = "storefront-scroll-top"

    private var dockTabs: [StorefrontTab] {
        hidesFirstStorefrontTabInDock ? Array(viewModel.tabs.dropFirst()) : viewModel.tabs
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                Color(hex: "0A0A0A")
                    .ignoresSafeArea()

                content(topInset: proxy.safeAreaInsets.top)

                if !isHotPresentation, showsStorefrontHeader {
                    StorefrontHeaderView(topInset: proxy.safeAreaInsets.top, mode: isImmersiveHeroActive ? .immersive : .standard)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .allowsHitTesting(true)
                }

                if showsBottomChrome {
                    bottomChrome
                        .padding(.bottom, max(proxy.safeAreaInsets.bottom - 12, 0))
                        .ignoresSafeArea(.container, edges: .bottom)
                }
            }
            .ignoresSafeArea(edges: [.top, .bottom])
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            guard loadsInitialOnAppear else { return }
            await viewModel.loadInitialIfNeeded()
        }
        .sheet(isPresented: $isTabMenuPresented) {
            StorefrontAllTabsSheet(
                tabs: dockTabs,
                selectedTabID: viewModel.selectedTabID,
                onSelectTab: { tab in
                    isTabMenuPresented = false
                    openStorefrontTab(tab)
                }
            )
            .presentationDetents([.fraction(0.32)])
            .presentationDragIndicator(.visible)
        }
    }

    private var isImmersiveHeroActive: Bool {
        viewModel.demoHeroVariant == .immersive
    }

    private var bottomChrome: some View {
        VStack(alignment: .center, spacing: 8) {
            if !isHotPresentation {
                StorefrontTabDockView(
                    tabs: dockTabs,
                    selectedTabID: viewModel.selectedTabID,
                    onSelectTab: { tab in
                        openStorefrontTab(tab)
                    },
                    onOpenMore: {
                        isTabMenuPresented = true
                    }
                )
            }

            BottomNavigationBar(
                selection: bottomSelection,
                profileImageName: profileImageName,
                onHomeTap: onOpenHome,
                onSearchTap: onOpenSearch,
                onShortsTap: onOpenShorts,
                onHotTap: onOpenHot,
                onProfileTap: onProfileTap
            )
        }
    }

    private func openStorefrontTab(_ tab: StorefrontTab) {
        if let onOpenStorefrontTab {
            onOpenStorefrontTab(tab)
        } else {
            Task { await viewModel.selectTab(tab) }
        }
    }

    @ViewBuilder
    private func content(topInset: CGFloat) -> some View {
        if viewModel.isInitialLoading && viewModel.sections.isEmpty {
            StorefrontLoadingSkeletonView()
        } else if let errorMessage = viewModel.errorMessage, viewModel.sections.isEmpty {
            ErrorView(title: AppStrings.Storefront.unavailableTitle, message: errorMessage, onRetry: {
                Task { await viewModel.loadInitialIfNeeded() }
            })
        } else if isHotPresentation {
            StorefrontHotAndNewView(
                sections: viewModel.sections,
                topInset: topInset,
                isRefreshing: viewModel.isRefreshing,
                isLoadingMore: viewModel.isLoadingMore,
                scrollToTopToken: viewModel.scrollToTopToken,
                cohort: viewModel.heroPresentationCohort,
                heroVariant: viewModel.demoHeroVariant,
                favoriteIDs: viewModel.favoriteIDs,
                onSelectItem: onSelectItem,
                onLoadMore: { sectionID in
                    Task {
                        await viewModel.loadMoreIfNeeded(currentSectionID: sectionID)
                    }
                },
                onToggleFavorite: { item in
                    Task { await viewModel.toggleFavorite(item) }
                }
            )
        } else {
            ScrollViewReader { scrollProxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 18) {
                        Color.clear
                            .frame(height: 0)
                            .id(Self.scrollTopID)

                        if viewModel.isRefreshing {
                            StorefrontRefreshIndicator()
                                .padding(.top, 4)
                        }

                        ForEach(viewModel.sections) { section in
                            StorefrontSectionView(
                                section: section,
                                isHomeTab: viewModel.selectedTabTitle == AppStrings.Common.home,
                                cohort: viewModel.heroPresentationCohort,
                                heroVariant: viewModel.demoHeroVariant,
                                topChromeHeight: StorefrontHeroMetrics.topChromeHeight(topInset: topInset) + additionalTopChromeHeight,
                                favoriteIDs: viewModel.favoriteIDs,
                                onViewAll: onViewAllSection,
                                onSelectItem: onSelectItem,
                                onToggleFavorite: { item in
                                    Task {
                                        await viewModel.toggleFavorite(item)
                                    }
                                }
                            )
                            .onAppear {
                                Task {
                                    await viewModel.loadMoreIfNeeded(currentSectionID: section.id)
                                }
                            }
                        }

                        if viewModel.isLoadingMore {
                            ProgressView()
                                .tint(.white)
                                .padding(.vertical, UIConstants.Spacing.md)
                        }
                    }
                    .padding(.bottom, showsBottomChrome ? 188 : 32)
                }
                .onChange(of: viewModel.scrollToTopToken) { _, _ in
                    scrollToTop(using: scrollProxy)
                }
                .onChange(of: viewModel.selectedTabID) { _, _ in
                    guard scrollsToTopOnTabChange else { return }
                    scrollToTop(using: scrollProxy)
                }
            }
        }
    }

    private func scrollToTop(using proxy: ScrollViewProxy) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            proxy.scrollTo(Self.scrollTopID, anchor: .top)
        }
    }
}

private struct StorefrontHotAndNewView: View {
    let sections: [StorefrontSection]
    let topInset: CGFloat
    let isRefreshing: Bool
    let isLoadingMore: Bool
    let scrollToTopToken: UUID
    let cohort: QuickplayCohort
    let heroVariant: StorefrontHeroVariant
    let favoriteIDs: Set<String>
    let onSelectItem: (StorefrontItem) -> Void
    let onLoadMore: (String) -> Void
    let onToggleFavorite: (StorefrontItem) -> Void
    @State private var activeSectionID: String?
    private static let scrollTopID = "hot-and-new-scroll-top"

    private var heroSections: [StorefrontSection] {
        sections.filter { $0.isHero && !$0.items.isEmpty }
    }

    private var displaySections: [StorefrontSection] {
        sections.filter { !$0.isHero && !$0.items.isEmpty }
    }

    var body: some View {
        ScrollViewReader { scrollProxy in
            ZStack(alignment: .top) {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 22) {
                        Color.clear
                            .frame(height: 0)
                            .id(Self.scrollTopID)

                        if isRefreshing {
                            StorefrontRefreshIndicator()
                                .padding(.top, 4)
                                .frame(maxWidth: .infinity)
                        }

                        ForEach(heroSections) { section in
                            StorefrontSectionView(
                                section: section,
                                isHomeTab: false,
                                cohort: cohort,
                                heroVariant: heroVariant,
                                topChromeHeight: StorefrontHeroMetrics.topChromeHeight(topInset: topInset),
                                favoriteIDs: favoriteIDs,
                                onViewAll: nil,
                                onSelectItem: onSelectItem,
                                onToggleFavorite: onToggleFavorite
                            )
                        }

                        ForEach(displaySections) { section in
                            HotAndNewSection(
                                section: section,
                                onSelectItem: onSelectItem
                            )
                            .id(section.id)
                            .background(sectionPositionReader(section.id))
                            .onAppear {
                                onLoadMore(section.id)
                            }
                        }

                        if isLoadingMore {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, UIConstants.Spacing.md)
                        }
                    }
                    .padding(.top, topInset + 54)
                    .padding(.bottom, 148)
                }
                .coordinateSpace(name: HotAndNewCoordinateSpace.name)
                .onPreferenceChange(HotAndNewSectionPositionKey.self) { positions in
                    updateActiveSection(with: positions)
                }

                HotAndNewChipBar(
                    sections: displaySections,
                    activeSectionID: activeSectionID ?? displaySections.first?.id,
                    topInset: topInset,
                    onSelect: { section in
                        withAnimation(.easeInOut(duration: 0.34)) {
                            activeSectionID = section.id
                            scrollProxy.scrollTo(section.id, anchor: .top)
                        }
                    }
                )
            }
            .onAppear {
                activeSectionID = activeSectionID ?? displaySections.first?.id
            }
            .onChange(of: scrollToTopToken) { _, _ in
                activeSectionID = displaySections.first?.id
                scrollToTop(using: scrollProxy)
            }
        }
    }

    private func scrollToTop(using proxy: ScrollViewProxy) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            proxy.scrollTo(Self.scrollTopID, anchor: .top)
        }
    }

    private func sectionPositionReader(_ id: String) -> some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: HotAndNewSectionPositionKey.self,
                value: [HotAndNewSectionPosition(id: id, minY: proxy.frame(in: .named(HotAndNewCoordinateSpace.name)).minY)]
            )
        }
    }

    private func updateActiveSection(with positions: [HotAndNewSectionPosition]) {
        guard !positions.isEmpty else { return }
        let targetY = topInset + 62
        let visible = positions
            .filter { $0.minY <= targetY + 24 }
            .max(by: { $0.minY < $1.minY })
            ?? positions.min(by: { abs($0.minY - targetY) < abs($1.minY - targetY) })

        guard let nextID = visible?.id, nextID != activeSectionID else { return }
        withAnimation(.easeInOut(duration: 0.18)) {
            activeSectionID = nextID
        }
    }
}

private struct HotAndNewChipBar: View {
    let sections: [StorefrontSection]
    let activeSectionID: String?
    let topInset: CGFloat
    let onSelect: (StorefrontSection) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(sections) { section in
                        Button {
                            onSelect(section)
                        } label: {
                            HStack(spacing: 6) {
                                if section.id == activeSectionID {
                                    Circle()
                                        .fill(Color(hex: "FF4B2B"))
                                        .frame(width: 7, height: 7)
                                }

                                Text(section.title)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(section.id == activeSectionID ? .white : .white.opacity(0.72))
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 10)
                            .frame(height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(section.id == activeSectionID ? Color.white.opacity(0.16) : Color.white.opacity(0.07))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .stroke(Color.white.opacity(section.id == activeSectionID ? 0.22 : 0.1), lineWidth: 1)
                                    )
                            )
                        }
                        .id(section.id)
                        .buttonStyle(LiquidButtonPressStyle())
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .frame(height: 42)
            .padding(.top, topInset)
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0.92), Color.black.opacity(0.72), Color.black.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: topInset + 72)
                .allowsHitTesting(false),
                alignment: .top
            )
            .onChange(of: activeSectionID) { _, newValue in
                guard let newValue else { return }
                withAnimation(.easeInOut(duration: 0.22)) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }
}

private struct HotAndNewSection: View {
    let section: StorefrontSection
    let onSelectItem: (StorefrontItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(section.items) { item in
                HotAndNewContentCard(item: item, onSelect: onSelectItem)
            }
        }
        .padding(.horizontal, 12)
    }
}

private struct HotAndNewContentCard: View {
    let item: StorefrontItem
    let onSelect: (StorefrontItem) -> Void
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        Button {
            onSelect(item)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                GeometryReader { proxy in
                    ZStack(alignment: .bottomLeading) {
                        PosterImageView(
                            url: item.imageURL(for: "0-16x9", width: max(Int(proxy.size.width * displayScale), 720)),
                            size: CGSize(width: proxy.size.width, height: proxy.size.height),
                            cornerRadius: 8
                        )

                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.72)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        if item.showsInlinePlayCTA {
                            Image(systemName: AppIcons.Action.play)
                                .font(.system(size: 14, weight: .black))
                                .foregroundStyle(.white)
                                .frame(width: 34, height: 34)
                                .background(Color.white.opacity(0.22), in: Circle())
                                .padding(12)
                        }

                        if item.isPremium {
                            Text("A")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 16, height: 16)
                                .background(Color.black.opacity(0.52), in: RoundedRectangle(cornerRadius: 3, style: .continuous))
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                                .padding(8)
                        }
                    }
                }
                .aspectRatio(16 / 9, contentMode: .fit)

                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(item.description.nilIfEmpty ?? item.primaryMetaText.nilIfEmpty ?? item.contentType.capitalized)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(.white.opacity(0.74))
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        if item.watchLabel.lowercased().contains("watch") || item.watchLabel.lowercased().contains("play") {
                            HotAndNewActionButton(title: item.watchLabel, systemImage: AppIcons.Action.play, isPrimary: true)
                        } else {
                            HotAndNewActionButton(title: "Play", systemImage: AppIcons.Action.play, isPrimary: true)
                        }

                        HotAndNewActionButton(title: "My List", systemImage: AppIcons.Action.plus, isPrimary: false)
                    }
                    .padding(.top, 2)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
            }
            .background(Color(hex: "050505"))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(LiquidButtonPressStyle())
    }
}

private struct HotAndNewActionButton: View {
    let title: String
    let systemImage: String
    let isPrimary: Bool

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(isPrimary ? Color.black : Color.white)
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 12)
            .frame(height: 30)
            .background(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(isPrimary ? Color.white : Color.white.opacity(0.14))
            )
    }
}

private enum HotAndNewCoordinateSpace {
    static let name = "HotAndNewScroll"
}

private struct HotAndNewSectionPosition: Equatable {
    let id: String
    let minY: CGFloat
}

private struct HotAndNewSectionPositionKey: PreferenceKey {
    static var defaultValue: [HotAndNewSectionPosition] = []

    static func reduce(value: inout [HotAndNewSectionPosition], nextValue: () -> [HotAndNewSectionPosition]) {
        value.append(contentsOf: nextValue())
    }
}

private struct StorefrontRefreshIndicator: View {
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

private struct StorefrontLoadingSkeletonView: View {
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                RoundedRectangle(cornerRadius: UIConstants.CornerRadius.hero, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .overlay { ShimmerView() }
                    .frame(height: 440)
                    .padding(.horizontal, 16)

                ForEach(0..<3, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 12) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                            .overlay { ShimmerView() }
                            .frame(width: 128, height: 18)
                            .padding(.horizontal, 16)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(0..<3, id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.white.opacity(0.04))
                                        .overlay { ShimmerView() }
                                        .frame(width: 124, height: 186)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }
}
