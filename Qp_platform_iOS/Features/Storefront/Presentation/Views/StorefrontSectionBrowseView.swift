import SwiftUI

struct StorefrontSectionBrowseView: View {
    @ObservedObject var viewModel: StorefrontSectionBrowseViewModel
    let onBack: () -> Void
    let onSelectItem: (StorefrontItem) -> Void

    var body: some View {
        GeometryReader { proxy in
            let containerWidth = proxy.size.width - 32
            let layout = viewModel.section?.browseGridLayout(containerWidth: containerWidth) ?? StorefrontCardLayout(
                size: CGSize(width: 124, height: 186),
                overlayHeight: 0,
                visibleCount: 3
            )
            let style = viewModel.section?.browseGridStyle() ?? .poster
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
                    header(topInset: proxy.safeAreaInsets.top)

                    if viewModel.isInitialLoading && viewModel.items.isEmpty {
                        skeleton(columns: columns, layout: layout)
                    } else if let errorMessage = viewModel.errorMessage, viewModel.items.isEmpty {
                        ErrorView(title: viewModel.title.nilIfEmpty ?? AppStrings.Storefront.unavailableTitle, message: errorMessage, onRetry: {
                            Task { await viewModel.loadIfNeeded() }
                        })
                    } else {
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVGrid(columns: columns, alignment: .center, spacing: 4) {
                                if viewModel.isRefreshing {
                                    StorefrontBrowseRefreshIndicator()
                                        .gridCellColumns(layout.visibleCount)
                                        .padding(.bottom, 8)
                                }

                                ForEach(viewModel.items) { item in
                                    StorefrontCardView(
                                        item: item,
                                        style: style,
                                        layout: layout,
                                        rank: nil,
                                        onSelect: onSelectItem
                                    )
                                    .onAppear {
                                        Task {
                                            await viewModel.loadMoreIfNeeded(currentItem: item)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 32)

                            if viewModel.isLoadingMore {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.bottom, 24)
                            }
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    private func header(topInset: CGFloat) -> some View {
        ZStack {
            HStack {
                Button(action: onBack) {
                    Image(systemName: AppIcons.Navigation.back)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 46, height: 46)
                        .background(
                            UnevenRoundedRectangle(
                                cornerRadii: .init(topLeading: 8, bottomLeading: 8, bottomTrailing: 18, topTrailing: 18),
                                style: .continuous
                            )
                            .fill(Color.black.opacity(0.1))
                            .overlay(
                                UnevenRoundedRectangle(
                                    cornerRadii: .init(topLeading: 8, bottomLeading: 8, bottomTrailing: 18, topTrailing: 18),
                                    style: .continuous
                                )
                                .stroke(Color.white.opacity(0.2), lineWidth: 1.2)
                            )
                        )
                }
                .buttonStyle(.plain)

                Spacer()
            }

            HStack(spacing: 6) {
                Text(viewModel.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                Image(systemName: AppIcons.Navigation.next)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.82))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, topInset + 12)
        .padding(.bottom, 10)
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
