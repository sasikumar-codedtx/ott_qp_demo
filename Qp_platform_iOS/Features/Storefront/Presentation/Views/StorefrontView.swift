import SwiftUI

struct StorefrontView: View {
    @ObservedObject var viewModel: StorefrontViewModel
    let bottomSelection: BottomNavigationSelection
    let profileName: String
    let onSelectItem: (StorefrontItem) -> Void
    let onOpenHome: () -> Void
    let onOpenSearch: () -> Void
    let onOpenShorts: () -> Void
    let onOpenHot: () -> Void
    let onProfileTap: () -> Void
    let onViewAllSection: (StorefrontSection) -> Void
    @State private var isTabMenuPresented = false

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                StorefrontHeaderView(topInset: proxy.safeAreaInsets.top)

                content
                }

                bottomChrome
                    .padding(.bottom, max(proxy.safeAreaInsets.bottom - 12, 0))
                    .ignoresSafeArea(.container, edges: .bottom)
            }
            .ignoresSafeArea(edges: [.top, .bottom])
        }
        .task {
            await viewModel.loadInitialIfNeeded()
        }
        .sheet(isPresented: $isTabMenuPresented) {
            StorefrontAllTabsSheet(
                tabs: viewModel.tabs,
                selectedTabID: viewModel.selectedTabID,
                onSelectTab: { tab in
                    isTabMenuPresented = false
                    Task { await viewModel.selectTab(tab) }
                }
            )
            .presentationDetents([.fraction(0.32)])
            .presentationDragIndicator(.visible)
        }
    }

    private var bottomChrome: some View {
        VStack(spacing: 8) {
                StorefrontTabDockView(
                    tabs: viewModel.tabs,
                    selectedTabID: viewModel.selectedTabID,
                    onSelectTab: { tab in
                        Task { await viewModel.selectTab(tab) }
                    },
                    onOpenMore: {
                        isTabMenuPresented = true
                    }
                )

                BottomNavigationBar(
                    selection: bottomSelection,
                    profileImageName: ProfileArtworkResolver.imageName(forName: profileName),
                    onHomeTap: onOpenHome,
                    onSearchTap: onOpenSearch,
                    onShortsTap: onOpenShorts,
                    onHotTap: onOpenHot,
                    onProfileTap: onProfileTap
                )
            }
        .background(
            ZStack(alignment: .bottom) {
                Color.black.opacity(0.22)
                    .frame(height: 128)
                    .blur(radius: 18)

                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.58), Color.black.opacity(0.94)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
                .allowsHitTesting(false)
        )
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isInitialLoading && viewModel.sections.isEmpty {
            StorefrontLoadingSkeletonView()
        } else if let errorMessage = viewModel.errorMessage, viewModel.sections.isEmpty {
            ErrorView(title: AppStrings.Storefront.unavailableTitle, message: errorMessage, onRetry: {
                Task { await viewModel.loadInitialIfNeeded() }
            })
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 18) {
                    if viewModel.isRefreshing {
                        StorefrontRefreshIndicator()
                            .padding(.top, 4)
                    }

                    ForEach(viewModel.sections) { section in
                        StorefrontSectionView(
                            section: section,
                            isHomeTab: viewModel.selectedTabTitle == AppStrings.Common.home,
                            cohort: viewModel.activeCohort,
                            heroVariant: viewModel.demoHeroVariant,
                            onViewAll: onViewAllSection,
                            onSelectItem: onSelectItem
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
                .padding(.bottom, 118)
            }
        }
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
