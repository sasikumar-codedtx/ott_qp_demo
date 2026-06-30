import SwiftUI
import Kingfisher

struct NewAndHotRouteView: View {
    @ObservedObject var viewModel: StorefrontViewModel
    let onShowDetails: (StorefrontItem) -> Void
    let onPlay: (StorefrontItem) -> Void
    let onToggleFavorite: (StorefrontItem) -> Void

    var body: some View {
        GeometryReader { proxy in
            NewAndHotFeedView(
                sections: viewModel.firstTabSections,
                topInset: proxy.safeAreaInsets.top,
                bottomInset: proxy.safeAreaInsets.bottom,
                isRefreshing: viewModel.isRefreshing,
                scrollToTopToken: viewModel.scrollToTopToken,
                favoriteIDs: viewModel.favoriteIDs,
                onShowDetails: onShowDetails,
                onPlay: onPlay,
                onToggleFavorite: onToggleFavorite
            )
        }
        // ignoresSafeArea must sit on the GeometryReader so proxy.safeAreaInsets reports the
        // real top/bottom insets (otherwise they read 0 and content tucks under the nav title).
        .ignoresSafeArea(edges: [.top, .bottom])
        .task {
            await viewModel.loadInitialIfNeeded()
        }
    }
}

struct NewAndHotFeedView: View {
    let sections: [StorefrontSection]
    let topInset: CGFloat
    let bottomInset: CGFloat
    let isRefreshing: Bool
    let scrollToTopToken: UUID
    let favoriteIDs: Set<String>
    let onShowDetails: (StorefrontItem) -> Void
    let onPlay: (StorefrontItem) -> Void
    let onToggleFavorite: (StorefrontItem) -> Void

    @State private var selectedSectionID: String?
    private static let scrollTopID = "new-and-hot-scroll-top"
    private static let routeNavigationHeight: CGFloat = 58
    private static let contentTopGap: CGFloat = 56   // 16 base + 40 extra clearance below the nav title

    // New & Hot mirrors the current storefront's first tab. Keep only playable/detail cards here;
    // collection and shorts are handled by their own flows.
    private var displaySections: [StorefrontSection] {
        sections.compactMap { section in
            guard !Self.isShortsSection(section) else { return nil }
            guard !Self.isContinueWatchingSection(section) else { return nil }

            let filteredItems = section.items.filter {
                !Self.isCollectionItem($0) &&
                !$0.isShortFormContent &&
                !Self.isContinueWatchingItem($0)
            }
            guard !filteredItems.isEmpty else { return nil }

            return StorefrontSection(
                id: section.id,
                title: section.title,
                ratio: section.ratio,
                items: filteredItems,
                isHero: false,
                backgroundImageURL: section.backgroundImageURL,
                backgroundColorHex: section.backgroundColorHex,
                viewAllContentIDs: section.viewAllContentIDs
            )
        }
    }

    private static func isShortsSection(_ section: StorefrontSection) -> Bool {
        section.ratio == "0-9x16" || section.title.lowercased().contains("short")
    }

    private static func isContinueWatchingSection(_ section: StorefrontSection) -> Bool {
        let values = [section.id, section.title]
            .map {
                $0
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
                    .replacingOccurrences(of: " ", with: "")
                    .replacingOccurrences(of: "_", with: "")
                    .replacingOccurrences(of: "-", with: "")
            }

        return values.contains { $0.contains("continuewatching") || $0.contains("watchingnow") }
    }

    private static func isContinueWatchingItem(_ item: StorefrontItem) -> Bool {
        (item.progress ?? 0) > 0.01
    }

    private static func isCollectionItem(_ item: StorefrontItem) -> Bool {
        let normalizedValues = [
            item.contentType,
            item.cardType ?? ""
        ]
            .map {
                $0
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
            }

        return normalizedValues.contains("collection")
    }

    private var activeSection: StorefrontSection? {
        displaySections.first { $0.id == selectedSectionID } ?? displaySections.first
    }

    var body: some View {
        ScrollViewReader { scrollProxy in
            ZStack(alignment: .bottom) {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                        // Top inset lives in this spacer (not .padding(.top)) so scrollTo(.top)
                        // pins the spacer — keeping content below the nav title after a tab switch.
                        Color.clear
                            .frame(height: topInset + Self.routeNavigationHeight + Self.contentTopGap)
                            .id(Self.scrollTopID)

                        if isRefreshing {
                            StorefrontRefreshIndicator()
                                .padding(.top, 4)
                                .frame(maxWidth: .infinity)
                        }

                        if let section = activeSection {
                            ForEach(section.items) { item in
                                NewHotCard(
                                    item: item,
                                    isSaved: favoriteIDs.contains(item.id),
                                    onPlay: { onPlay(item) },
                                    onShowDetails: { onShowDetails(item) },
                                    onToggleSave: { onToggleFavorite(item) }
                                )
                            }
                        } else if !isRefreshing {
                            NewHotEmptyState()
                                .padding(.top, 80)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, bottomInset + 116)
                }
                .onChange(of: scrollToTopToken) { _, _ in scrollToTop(using: scrollProxy) }
                .onChange(of: selectedSectionID) { _, _ in
                    DispatchQueue.main.async {
                        scrollToTop(using: scrollProxy)
                    }
                }
                .onChange(of: displaySections.map(\.id)) { _, ids in
                    guard let selectedSectionID, ids.contains(selectedSectionID) else {
                        selectedSectionID = ids.first
                        DispatchQueue.main.async {
                            scrollToTop(using: scrollProxy)
                        }
                        return
                    }
                }

                if displaySections.count > 1 {
                    NewHotFilterBar(
                        sections: displaySections,
                        selectedID: activeSection?.id,
                        onSelect: { id in
                            // Instant switch — no animation (it slid content up from the bottom
                            // and briefly tucked it under the nav while the scroll reset).
                            guard id != selectedSectionID else { return }
                            var tx = Transaction()
                            tx.disablesAnimations = true
                            withTransaction(tx) { selectedSectionID = id }
                        }
                    )
                    .padding(.bottom, bottomInset + 32)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [Color.clear, Color(hex: "0A0A0A").opacity(0.92), Color(hex: "0A0A0A")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: bottomInset + 110)
                        .allowsHitTesting(false),
                        alignment: .bottom
                    )
                }
            }
            .onAppear {
                if selectedSectionID == nil {
                    selectedSectionID = displaySections.first?.id
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

// MARK: - Bottom filter bar (one chip per section)

private struct NewHotFilterBar: View {
    let sections: [StorefrontSection]
    let selectedID: String?
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(sections) { section in
                    let isSelected = section.id == selectedID
                    Button {
                        onSelect(section.id)
                    } label: {
                        Text(section.title)
                            .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                            .foregroundStyle(isSelected ? Color(hex: "202020") : Color(hex: "F0F0F0"))
                            .lineLimit(1)
                            .padding(.horizontal, 16)
                            .frame(height: 40)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(isSelected ? Color.white : Color(hex: "202020"))
                                    .overlay(Capsule(style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 32)
        }
        .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Empty state

private struct NewHotEmptyState: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 30, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.28))
            Text("Nothing here yet")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 220)
    }
}

// MARK: - Card

private struct NewHotCard: View {
    let item: StorefrontItem
    let isSaved: Bool
    let onPlay: () -> Void
    let onShowDetails: () -> Void
    let onToggleSave: () -> Void
    @Environment(\.displayScale) private var displayScale

    private enum CardAction { case resume, watch, viewMore }

    private var cardAction: CardAction {
        if (item.progress ?? 0) > 0.01 { return .resume }
        if ContentNavigationPolicy.destination(for: item) == .player { return .watch }
        return .viewMore
    }

    // Resume / Watch play directly; View More opens details.
    private var playsDirectly: Bool { cardAction != .viewMore }

    private var primaryTitle: String {
        switch cardAction {
        case .resume:   return "Resume"
        case .watch:    return "Watch"
        case .viewMore: return "View More"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            playerArea
            contentBlock
        }
        .background(
            LinearGradient(
                stops: [
                    .init(color: Color(hex: "1D1D1D").opacity(0.5), location: 0.0),
                    .init(color: Color(hex: "1D1D1D").opacity(0.5), location: 0.45),
                    .init(color: Color(hex: "070708"), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onTapGesture { onShowDetails() }
    }

    // 16:9 image-only poster card.
    private var playerArea: some View {
        Color.black
            .aspectRatio(380.0 / 213.0, contentMode: .fit)
            .overlay {
                GeometryReader { proxy in
                    ZStack(alignment: .top) {
                        PosterImageView(
                            url: item.imageURL(for: "0-16x9", width: max(Int(proxy.size.width * displayScale), 900)),
                            size: CGSize(width: proxy.size.width, height: proxy.size.height),
                            cornerRadius: 0
                        )
                    }
                }
            }
    }

    private var contentBlock: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                // Data-driven tag (from lodtg → customTag); same gradient as the trending cards.
                if !item.customTag.isEmpty {
                    Text(item.customTag)
                        .font(.system(size: 11, weight: .semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .frame(height: 22)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "EC2027"), Color(hex: "5612CA")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                        )
                }

                titleArt

                Text(item.description)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .lineSpacing(1)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            actionRow
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var titleArt: some View {
        if let logo = item.titleImageURL(width: 600) {
            KFImage.url(logo)
                .placeholder { fallbackTitle }
                .loadDiskFileSynchronously()
                .cancelOnDisappear(true)
                .fade(duration: 0.2)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: 70, alignment: .leading)
        } else {
            fallbackTitle
        }
    }

    private var fallbackTitle: some View {
        Text(item.title)
            .font(.system(size: 24, weight: .heavy))
            .foregroundStyle(.white)
            .lineLimit(2)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .bottomLeading)
    }

    private var actionRow: some View {
        HStack(spacing: 8) {
            Button {
                playsDirectly ? onPlay() : onShowDetails()
            } label: {
                HStack(spacing: 6) {
                    if playsDirectly {
                        Image(systemName: "play.fill")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    Text(primaryTitle)
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .frame(height: 48)
                .background(
                    Capsule(style: .continuous)
                        .fill(LinearGradient(
                            colors: [Color.white.opacity(0.2), Color(hex: "CECECE").opacity(0.2)],
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        ))
                        .overlay(Capsule(style: .continuous).stroke(Color.white.opacity(0.18), lineWidth: 1))
                )
            }
            .buttonStyle(LiquidButtonPressStyle())

            circleButton(systemImage: isSaved ? "checkmark" : AppIcons.Action.plus, action: onToggleSave)

            // Info shortcut to details — only when the primary button plays directly.
            if playsDirectly {
                circleButton(systemImage: "info", action: onShowDetails)
            }
        }
    }

    private func circleButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.white.opacity(0.2)))
                .shadow(color: Color(hex: "CACACA").opacity(0.13), radius: 3, x: -1, y: 1)
        }
        .buttonStyle(LiquidButtonPressStyle())
    }
}
