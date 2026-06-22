# UI Registry

## Shared Components

- `AppBackgroundView`
- `BottomNavigationBar`
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
  It is backed by `Kingfisher` with shared memory+disk caching.
- Reuse `StorefrontSectionView` and `StorefrontCardView` for profile, storefront, search-adjacent rails instead of building duplicate row UIs.
