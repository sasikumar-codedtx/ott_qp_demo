# UI Registry

## Shared Components

- `AppBackgroundView`
- `BottomNavigationBar`
- `CachedAsyncImage`
- `EmptyStateView`
- `ErrorView`
- `LoadingView`
- `PosterImageView`
- `ProfileAvatarView`
- `SearchFieldView`
- `SectionHeaderView`
- `StatusBarView`
- `StorefrontCardView`
- `StorefrontSectionView`

## Usage Rules

- Prefer shared components before creating new feature-local components.
- Feature-local components should stay inside the feature's `Presentation/Views/`.
- Use `PosterImageView` for CDN-backed posters and thumbnails.
- Reuse `StorefrontSectionView` and `StorefrontCardView` for profile, storefront, search-adjacent rails instead of building duplicate row UIs.
