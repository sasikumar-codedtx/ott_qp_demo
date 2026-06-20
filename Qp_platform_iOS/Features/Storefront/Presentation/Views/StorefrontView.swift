import SwiftUI

struct StorefrontView: View {
    @ObservedObject var viewModel: StorefrontViewModel
    let profileName: String
    let onSelectItem: (StorefrontItem) -> Void
    let onOpenSearch: () -> Void
    let onProfileTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            StorefrontHeaderView(
                tabs: viewModel.tabs,
                selectedTabID: viewModel.selectedTabID,
                profileName: profileName,
                onSelectTab: { tab in
                    Task { await viewModel.selectTab(tab) }
                },
                onProfileTap: onProfileTap
            )

            content

            BottomNavigationBar(
                selection: viewModel.selectedTabTitle == AppStrings.Common.home ? .home : .hot,
                profileImageName: ProfileArtworkResolver.imageName(forName: profileName),
                onHomeTap: { Task { await viewModel.selectHomeTabIfNeeded() } },
                onSearchTap: onOpenSearch,
                onHotTap: { Task { await viewModel.selectHotTabIfNeeded() } },
                onProfileTap: onProfileTap
            )
        }
        .task {
            await viewModel.loadInitialIfNeeded()
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isInitialLoading && viewModel.sections.isEmpty {
            LoadingView()
        } else if let errorMessage = viewModel.errorMessage, viewModel.sections.isEmpty {
            ErrorView(title: AppStrings.Storefront.unavailableTitle, message: errorMessage, onRetry: {
                Task { await viewModel.loadInitialIfNeeded() }
            })
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 18) {
                    ForEach(viewModel.sections) { section in
                        StorefrontSectionView(section: section, isHomeTab: viewModel.selectedTabTitle == AppStrings.Common.home, onSelectItem: onSelectItem)
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
                .padding(.bottom, UIConstants.Spacing.lg)
            }
        }
    }
}
