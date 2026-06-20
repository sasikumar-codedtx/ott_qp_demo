import CoreGraphics
import Foundation

struct StorefrontSection: Identifiable, Equatable, Hashable {
    let id: String
    let title: String
    let ratio: String
    let items: [StorefrontItem]
    let isHero: Bool

    func cardStyle(isHomeTab: Bool) -> StorefrontCardStyle {
        if isHero {
            return isHomeTab ? .homeHero : .featuredHero
        }

        switch ratio {
        case "0-1x1":
            return .square
        case "0-9x16":
            return .short
        case "0-2x3", "0-16x18":
            return .poster
        default:
            return .landscape
        }
    }

    func cardLayout(isHomeTab: Bool, containerWidth: CGFloat) -> StorefrontCardLayout {
        cardStyle(isHomeTab: isHomeTab).layout(containerWidth: containerWidth)
    }
}

enum StorefrontCardStyle {
    case homeHero
    case featuredHero
    case landscape
    case poster
    case square
    case short

    var imageRatio: String {
        switch self {
        case .homeHero, .featuredHero, .landscape:
            return "0-16x9"
        case .poster:
            return "0-2x3"
        case .square:
            return "0-1x1"
        case .short:
            return "0-9x16"
        }
    }

    func layout(containerWidth: CGFloat) -> StorefrontCardLayout {
        switch self {
        case .homeHero:
            let width = max(containerWidth - 8, 280)
            return StorefrontCardLayout(size: CGSize(width: width, height: width * 1.54), overlayHeight: 0, visibleCount: 1)
        case .featuredHero:
            let width = max(containerWidth - 20, 280)
            return StorefrontCardLayout(size: CGSize(width: width, height: width * 1.2), overlayHeight: 0, visibleCount: 1)
        case .landscape:
            let width = max((containerWidth - UIConstants.Spacing.md) / 2, 160)
            return StorefrontCardLayout(size: CGSize(width: width, height: width * 9 / 16), overlayHeight: 50, visibleCount: 2)
        case .poster:
            let width = max((containerWidth - (UIConstants.Spacing.md * 2)) / 3, 108)
            return StorefrontCardLayout(size: CGSize(width: width, height: width * 1.5), overlayHeight: 0, visibleCount: 3)
        case .square:
            let width = max((containerWidth - (UIConstants.Spacing.md * 2)) / 3, 108)
            return StorefrontCardLayout(size: CGSize(width: width, height: width), overlayHeight: 0, visibleCount: 3)
        case .short:
            let width = max((containerWidth - (UIConstants.Spacing.md * 2)) / 3, 108)
            return StorefrontCardLayout(size: CGSize(width: width, height: width * 16 / 9), overlayHeight: 0, visibleCount: 3)
        }
    }
}

struct StorefrontCardLayout {
    let size: CGSize
    let overlayHeight: CGFloat
    let visibleCount: Int
}
