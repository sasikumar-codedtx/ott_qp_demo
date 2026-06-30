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
    var onSubscribe: () -> Void = {}
    var isSubscribed: Bool = false
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
                    StorefrontHeaderView(topInset: proxy.safeAreaInsets.top, mode: .standard, isSubscribed: isSubscribed, onSubscribe: onSubscribe)
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
            StorefrontLoadingSkeletonView(
                topInset: topInset,
                additionalTopChromeHeight: additionalTopChromeHeight
            )
        } else if let errorMessage = viewModel.errorMessage, viewModel.sections.isEmpty {
            ErrorView(title: AppStrings.Storefront.unavailableTitle, message: errorMessage, onRetry: {
                Task { await viewModel.loadInitialIfNeeded() }
            })
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

struct StorefrontRefreshIndicator: View {
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
    let topInset: CGFloat
    let additionalTopChromeHeight: CGFloat

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .overlay { ShimmerView() }
                    .frame(height: StorefrontHeroMetrics.slotHeight)
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
            // Start below the status bar + storefront header so the hero shimmer lines up
            // with where the real hero renders.
            .padding(.top, StorefrontHeroMetrics.topChromeHeight(topInset: topInset) + additionalTopChromeHeight)
            .padding(.bottom, 24)
        }
    }
}
