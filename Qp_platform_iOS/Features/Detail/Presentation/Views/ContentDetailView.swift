import SwiftUI

struct ContentDetailView: View {
    @ObservedObject var viewModel: ContentDetailViewModel
    let onBack: () -> Void
    let onSelectRecommendation: (StorefrontItem) -> Void

    private let recommendationColumns = [
        GridItem(.flexible(), spacing: UIConstants.Spacing.xs),
        GridItem(.flexible(), spacing: UIConstants.Spacing.xs),
        GridItem(.flexible(), spacing: UIConstants.Spacing.xs)
    ]

    var body: some View {
        content
            .task(id: viewModel.requestKey) {
                await viewModel.loadIfNeeded()
            }
    }

    @ViewBuilder
    private var content: some View {
        if let detail = viewModel.detail {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    hero(detail)
                    detailContent(detail)
                }
                .padding(.bottom, UIConstants.Spacing.xl)
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

    private func hero(_ detail: ContentDetail) -> some View {
        ZStack(alignment: .top) {
            PosterImageView(
                url: detail.imageURL(for: "0-16x9", width: 1400),
                size: CGSize(width: UIScreen.main.bounds.width, height: 362),
                cornerRadius: 0
            )

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.62), Color.clear, Color.black.opacity(0.95)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 362)

            VStack(spacing: 0) {
                StatusBarView()
                    .padding(.horizontal, UIConstants.Spacing.xl)
                    .padding(.top, UIConstants.Spacing.sm + 2)

                HStack {
                    Button(action: onBack) {
                        topButton(icon: AppIcons.Navigation.back)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    HStack(spacing: UIConstants.Spacing.sm) {
                        topButton(icon: AppIcons.Action.tv)
                        topButton(icon: AppIcons.Action.share)
                    }
                }
                .padding(.horizontal, UIConstants.Spacing.lg)
                .padding(.top, UIConstants.Spacing.xs)

                Spacer()

                Text(detail.title)
                    .font(.largeTitle.weight(.black))
                    .foregroundStyle(Color(hex: "F5C132"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, UIConstants.Spacing.xl)
                    .padding(.bottom, 34)
            }
            .frame(height: 362)
        }
    }

    private func detailContent(_ detail: ContentDetail) -> some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.lg) {
            if !detail.metaLine.isEmpty {
                Text(detail.metaLine)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, UIConstants.Spacing.lg)
            }

            Button(action: {}) {
                Text(AppStrings.Detail.watchNow)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: UIConstants.CornerRadius.md, style: .continuous)
                            .fill(.white)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, UIConstants.Spacing.lg)

            Text(detail.description)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.94))
                .padding(.horizontal, UIConstants.Spacing.lg)

            if detail.hasFreePreview {
                Text("Free preview available")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color(hex: "F5A623"))
                    .padding(.horizontal, UIConstants.Spacing.lg)
            }

            HStack(spacing: 0) {
                ForEach([AppStrings.Detail.moreLikeThis, AppStrings.Detail.moments, AppStrings.Detail.castAndMore], id: \.self) { tab in
                    Button {
                        viewModel.selectedTab = tab
                    } label: {
                        VStack(spacing: UIConstants.Spacing.sm) {
                            Text(tab)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(viewModel.selectedTab == tab ? 1 : 0.74))

                            Rectangle()
                                .fill(viewModel.selectedTab == tab ? .white : .clear)
                                .frame(height: 1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, UIConstants.Spacing.lg)

            switch viewModel.selectedTab {
            case AppStrings.Detail.moreLikeThis:
                recommendationSection
            case AppStrings.Detail.moments:
                momentsSection(detail)
            default:
                castSection(detail)
            }
        }
    }

    @ViewBuilder
    private var recommendationSection: some View {
        if viewModel.recommendations.isEmpty {
            EmptyStateView(title: AppStrings.Detail.moreLikeThis, message: AppStrings.Detail.noRecommendations, systemImage: AppIcons.Action.film)
        } else {
            LazyVGrid(columns: recommendationColumns, spacing: UIConstants.Spacing.xs) {
                ForEach(viewModel.recommendations) { item in
                    Button {
                        onSelectRecommendation(item)
                    } label: {
                        VStack(alignment: .leading, spacing: UIConstants.Spacing.sm) {
                            PosterImageView(
                                url: item.imageURL(for: "0-2x3", width: 420),
                                size: CGSize(width: UIConstants.Size.posterWidth, height: UIConstants.Size.posterHeight),
                                cornerRadius: UIConstants.CornerRadius.xs
                            )
                            Text(item.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, UIConstants.Spacing.lg)
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
                .background(
                    RoundedRectangle(cornerRadius: UIConstants.CornerRadius.lg, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                )
        }
        .padding(.horizontal, UIConstants.Spacing.lg)
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
                            PosterImageView(
                                url: person.imageURL(width: 240),
                                size: CGSize(width: UIConstants.Size.posterWidth, height: UIConstants.Size.posterWidth),
                                cornerRadius: UIConstants.CornerRadius.lg
                            )
                            Text(person.name)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, UIConstants.Spacing.lg)
    }

    private func topButton(icon: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.lg + 2, style: .continuous)
                .fill(Color.black.opacity(0.22))
                .overlay(
                    RoundedRectangle(cornerRadius: UIConstants.CornerRadius.lg + 2, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )

            Image(systemName: icon)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .frame(width: 45, height: 45)
    }
}
