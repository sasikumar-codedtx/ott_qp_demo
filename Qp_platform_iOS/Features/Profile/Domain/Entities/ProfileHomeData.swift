import Foundation

struct ProfileHomeData {
    let continueWatching: [StorefrontItem]
    let likedItems: [StorefrontItem]
    let favorites: [StorefrontItem]
    let clips: [StorefrontItem]   // API recommendations — not user-generated
}
