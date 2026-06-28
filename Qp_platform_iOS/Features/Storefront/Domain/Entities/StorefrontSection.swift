import CoreGraphics
import Foundation

struct StorefrontSection: Identifiable, Equatable, Hashable {
    let id: String
    let title: String
    let ratio: String
    let items: [StorefrontItem]
    let isHero: Bool
    let backgroundImageURL: URL?
    let backgroundColorHex: String?
    let viewAllContentIDs: [String]?

    init(
        id: String,
        title: String,
        ratio: String,
        items: [StorefrontItem],
        isHero: Bool,
        backgroundImageURL: URL? = nil,
        backgroundColorHex: String? = nil,
        viewAllContentIDs: [String]? = nil
    ) {
        self.id = id
        self.title = title
        self.ratio = ratio
        self.items = items
        self.isHero = isHero
        self.backgroundImageURL = backgroundImageURL
        self.backgroundColorHex = backgroundColorHex
        self.viewAllContentIDs = viewAllContentIDs
    }

    var allowsViewAll: Bool {
        !isGenreCollection
    }

    private var isGenreCollection: Bool {
        guard !items.isEmpty else { return false }

        let hasOnlyCollectionCards = items.allSatisfy { item in
            let type = item.contentType.lowercased()
            let cardType = item.cardType?.lowercased() ?? ""
            return type == "collection" || cardType == "collection"
        }

        guard hasOnlyCollectionCards else { return false }

        let searchText = ([title] + items.map(\.title) + items.compactMap(\.customSearchCategory))
            .joined(separator: " ")
            .lowercased()

        return searchText.contains("genre")
    }

    func cardStyle(isHomeTab: Bool, cohort: QuickplayCohort) -> StorefrontCardStyle {
        if isHero {
            if cohort == .sports {
                return .sportsHero
            }
            return isHomeTab ? .homeHero : .featuredHero
        }

        let aspect = ratioAspect
        if abs(aspect - 1) < 0.05 {
            return .square
        }
        if ratio == "0-9x16" {
            return .short
        }
        return aspect < 1 ? .poster : .landscape
    }

    func cardLayout(
        isHomeTab: Bool,
        cohort: QuickplayCohort,
        containerWidth: CGFloat,
        density: StorefrontCardDensity = .phone
    ) -> StorefrontCardLayout {
        cardStyle(isHomeTab: isHomeTab, cohort: cohort).layout(
            containerWidth: containerWidth,
            ratio: ratioAspect,
            density: density
        )
    }

    func browseGridStyle() -> StorefrontCardStyle {
        let aspect = ratioAspect
        if abs(aspect - 1) < 0.05 {
            return .square
        }
        if ratio == "0-9x16" {
            return .short
        }
        return aspect < 1 ? .poster : .landscape
    }

    func browseGridLayout(containerWidth: CGFloat, density: StorefrontCardDensity = .phone) -> StorefrontCardLayout {
        browseGridStyle().layout(
            containerWidth: containerWidth,
            ratio: ratioAspect,
            density: density
        )
    }

    private var ratioAspect: CGFloat {
        ratio.quickplayAspectRatio ?? (16 / 9)
    }
}

enum StorefrontCardStyle {
    case homeHero
    case featuredHero
    case sportsHero
    case landscape
    case poster
    case square
    case short

    var imageRatio: String {
        switch self {
        case .homeHero, .featuredHero, .sportsHero, .landscape:
            return "0-16x9"
        case .poster:
            return "0-2x3"
        case .square:
            return "0-1x1"
        case .short:
            return "0-9x16"
        }
    }

    func layout(containerWidth: CGFloat, ratio: CGFloat, density: StorefrontCardDensity = .phone) -> StorefrontCardLayout {
        switch self {
        case .homeHero:
            let width = max(containerWidth - 14, 320)
            return StorefrontCardLayout(size: CGSize(width: width, height: width * 1.52), overlayHeight: 0, visibleCount: 1)
        case .featuredHero:
            let width = max(containerWidth - 18, 320)
            return StorefrontCardLayout(size: CGSize(width: width, height: width * 1.2), overlayHeight: 0, visibleCount: 1)
        case .sportsHero:
            return StorefrontCardLayout(size: CGSize(width: 349, height: 420), overlayHeight: 0, visibleCount: 1)
        case .landscape:
            let visibleCount = density.landscapeVisibleCount
            let totalSpacing = StorefrontRailMetrics.cardGap * CGFloat(visibleCount - 1)
            let width = max((containerWidth - totalSpacing) / CGFloat(visibleCount), 86)
            return StorefrontCardLayout(
                size: CGSize(width: width, height: width / max(ratio, 1.0)),
                overlayHeight: max(42, width * 0.3),
                visibleCount: visibleCount
            )
        case .poster:
            let visibleCount = density.portraitVisibleCount
            let totalSpacing = StorefrontRailMetrics.cardGap * CGFloat(visibleCount - 1)
            let width = max((containerWidth - totalSpacing) / CGFloat(visibleCount), 72)
            return StorefrontCardLayout(
                size: CGSize(width: width, height: width / max(ratio, 0.01)),
                overlayHeight: 0,
                visibleCount: visibleCount
            )
        case .square:
            let visibleCount = density.portraitVisibleCount
            let totalSpacing = StorefrontRailMetrics.cardGap * CGFloat(visibleCount - 1)
            let width = max((containerWidth - totalSpacing) / CGFloat(visibleCount), 72)
            return StorefrontCardLayout(size: CGSize(width: width, height: width), overlayHeight: 0, visibleCount: visibleCount)
        case .short:
            let visibleCount = density.shortVisibleCount
            let totalSpacing = StorefrontRailMetrics.cardGap * CGFloat(visibleCount - 1)
            let width = max((containerWidth - totalSpacing) / CGFloat(visibleCount), 84)
            return StorefrontCardLayout(size: CGSize(width: width, height: width / max(ratio, 0.01)), overlayHeight: 0, visibleCount: visibleCount)
        }
    }
}

enum StorefrontCardDensity: Equatable {
    case phone
    case tabletPortrait
    case expanded

    var landscapeVisibleCount: Int {
        switch self {
        case .phone:
            return 2
        case .tabletPortrait:
            return 4
        case .expanded:
            return 6
        }
    }

    var portraitVisibleCount: Int {
        switch self {
        case .phone:
            return 3
        case .tabletPortrait:
            return 4
        case .expanded:
            return 6
        }
    }

    var shortVisibleCount: Int {
        switch self {
        case .phone:
            return 2
        case .tabletPortrait:
            return 4
        case .expanded:
            return 6
        }
    }
}

enum StorefrontRailMetrics {
    static let headerToCardsGap: CGFloat = 8
    static let cardGap: CGFloat = 4
    static let cardCornerRadius: CGFloat = 8
}

struct StorefrontCardLayout {
    let size: CGSize
    let overlayHeight: CGFloat
    let visibleCount: Int
}

private extension String {
    var quickplayAspectRatio: CGFloat? {
        let parts = split(separator: "-")
        guard
            let dimensions = parts.last?.split(separator: "x"),
            dimensions.count == 2,
            let width = Double(dimensions[0]),
            let height = Double(dimensions[1]),
            width > 0,
            height > 0
        else {
            return nil
        }

        return CGFloat(width / height)
    }
}
