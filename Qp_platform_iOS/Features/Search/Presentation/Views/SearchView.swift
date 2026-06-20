import SwiftUI

struct SearchView: View {
    @ObservedObject var viewModel: SearchViewModel
    let profileName: String
    let onSelectItem: (StorefrontItem) -> Void
    let onOpenHome: () -> Void
    let onOpenHot: () -> Void
    let onProfileTap: () -> Void
    @FocusState private var isSearchFocused: Bool

    private let columns = [
        GridItem(.flexible(), spacing: UIConstants.Spacing.xs),
        GridItem(.flexible(), spacing: UIConstants.Spacing.xs),
        GridItem(.flexible(), spacing: UIConstants.Spacing.xs)
    ]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: UIConstants.Spacing.lg) {
                StatusBarView()
                    .padding(.horizontal, UIConstants.Spacing.xl)
                    .padding(.top, UIConstants.Spacing.sm + 2)

                SearchFieldView(text: $viewModel.query, isFocused: $isSearchFocused)
                    .padding(.horizontal, UIConstants.Spacing.lg)
            }

            ZStack(alignment: .bottomTrailing) {
                content
                floatingButton
            }

            BottomNavigationBar(
                selection: .search,
                profileImageName: ProfileArtworkResolver.imageName(forName: profileName),
                onHomeTap: onOpenHome,
                onSearchTap: {},
                onHotTap: onOpenHot,
                onProfileTap: onProfileTap
            )
        }
        .task {
            try? await Task.sleep(for: .milliseconds(150))
            isSearchFocused = true
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.normalizedQuery.isEmpty {
            ScrollView {
                VStack(alignment: .leading, spacing: UIConstants.Spacing.md) {
                    SectionHeaderView(title: AppStrings.Search.popular)
                        .padding(.horizontal, UIConstants.Spacing.lg)
                        .padding(.top, UIConstants.Spacing.xl)

                    if viewModel.popularItems.isEmpty {
                        EmptyStateView(title: AppStrings.Search.popular, message: AppStrings.Search.emptyPopular, systemImage: "sparkles.tv")
                    } else {
                        LazyVGrid(columns: columns, spacing: UIConstants.Spacing.xs) {
                            ForEach(viewModel.popularItems) { item in
                                SearchPosterCard(item: item, onSelect: onSelectItem)
                            }
                        }
                        .padding(.horizontal, UIConstants.Spacing.lg)
                    }
                }
                .padding(.bottom, 120)
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: UIConstants.Spacing.lg) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: UIConstants.Spacing.xs + 2) {
                            ForEach(SearchCategory.allCases) { category in
                                Button {
                                    viewModel.selectedCategory = category
                                } label: {
                                    Text(category.rawValue)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(viewModel.selectedCategory == category ? .black : .white.opacity(0.62))
                                        .padding(.horizontal, 18)
                                        .frame(height: 34)
                                        .background(
                                            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.sm, style: .continuous)
                                                .fill(viewModel.selectedCategory == category ? .white : Color.white.opacity(0.08))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, UIConstants.Spacing.lg)
                    }
                    .padding(.top, UIConstants.Spacing.lg)

                    if viewModel.isLoading && viewModel.results.isEmpty {
                        LoadingView()
                    } else if let errorMessage = viewModel.errorMessage, viewModel.results.isEmpty {
                        ErrorView(title: AppStrings.Search.unavailableTitle, message: errorMessage, onRetry: nil)
                    } else if viewModel.displayedResults.isEmpty {
                        EmptyStateView(title: AppStrings.Search.noResults, message: viewModel.normalizedQuery, systemImage: AppIcons.Navigation.search)
                    } else {
                        let featureTitle = viewModel.displayedResults.first?.title ?? viewModel.normalizedQuery.capitalized

                        VStack(alignment: .leading, spacing: UIConstants.Spacing.xl - 4) {
                            SectionHeaderView(title: featureTitle)
                                .padding(.horizontal, UIConstants.Spacing.lg)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: UIConstants.Spacing.xs) {
                                    ForEach(Array(viewModel.displayedResults.prefix(8))) { item in
                                        SearchPosterCard(item: item, onSelect: onSelectItem)
                                    }
                                }
                                .padding(.horizontal, UIConstants.Spacing.lg)
                            }

                            SectionHeaderView(title: "\"\(featureTitle)\" From Movies")
                                .padding(.horizontal, UIConstants.Spacing.lg)

                            LazyVGrid(columns: columns, spacing: UIConstants.Spacing.xs) {
                                ForEach(Array(viewModel.displayedResults.dropFirst(min(6, viewModel.displayedResults.count)))) { item in
                                    SearchPosterCard(item: item, onSelect: onSelectItem)
                                }
                            }
                            .padding(.horizontal, UIConstants.Spacing.lg)
                        }
                    }
                }
                .padding(.bottom, 120)
            }
        }
    }

    private var floatingButton: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "6B1F73"), Color(hex: "1B102A")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Circle().stroke(Color.white.opacity(0.24), lineWidth: 1)
                )

            Circle()
                .stroke(Color(hex: "F29B38"), lineWidth: 1.5)
                .frame(width: 26, height: 26)

            Image(systemName: AppIcons.Action.mic)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: UIConstants.Size.floatingAction, height: UIConstants.Size.floatingAction)
        .padding(.trailing, UIConstants.Spacing.lg + 2)
        .padding(.bottom, 90)
    }
}

private struct SearchPosterCard: View {
    let item: StorefrontItem
    let onSelect: (StorefrontItem) -> Void

    var body: some View {
        Button {
            onSelect(item)
        } label: {
            ZStack {
                PosterImageView(
                    url: item.imageURL(for: "0-2x3", width: 480),
                    size: CGSize(width: UIConstants.Size.posterWidth, height: UIConstants.Size.posterHeight),
                    cornerRadius: UIConstants.CornerRadius.xs
                )

                RoundedRectangle(cornerRadius: UIConstants.CornerRadius.xs, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.15), Color.black.opacity(0.38)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Image(systemName: AppIcons.Action.playCircle)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white.opacity(0.92), .white.opacity(0.22))
            }
        }
        .buttonStyle(.plain)
    }
}
