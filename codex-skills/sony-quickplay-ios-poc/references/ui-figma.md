# UI And Figma Reference

## Figma Workflow

For every Figma-backed UI change:
1. Parse the file key and node id from the Figma URL.
2. Call `get_design_context`.
3. Call `get_screenshot`.
4. Inspect the existing SwiftUI component.
5. Patch the shared component when the pattern is reused.
6. Build after changes.

Do not implement from memory when a Figma node is provided.

## Visual System

- Target Sony LIV-style dark, glassy, edge-to-edge UI.
- Use local Figma-derived assets from `Assets.xcassets` when present.
- Use `LiquidGlassBackground`, `LiquidButtonPressStyle`, `LogoGlowView`, and `SonyGlassControls` where the existing app uses them.
- Use `LogoGlowView` behind logos on auth/profile/settings-style screens.
- Avoid default-looking SwiftUI controls unless wrapped/styled for this visual system.

## Shared Components

Prefer:
- `BottomNavigationBar` for app tabs.
- `StorefrontTabDockView` for backend storefront menu tabs.
- `StorefrontSectionView` and `StorefrontCardView` for rails.
- `StorefrontTrendingRankedSectionView` for ranked/trending rails.
- `PosterImageView` for CDN images.
- `ProfileAvatarView` for profile avatars.
- `SearchFieldView` for search inputs.
- `NavigationChromeButton` and `NavigationChromeTitle` for pushed toolbar chrome.

## Bottom Navigation

The bottom app bar is different from storefront menu tabs.

Figma target:
- 380pt pill max width.
- 5 items: Home, Search, Shorts, New & Hot, Profile.
- 24pt icons.
- 12pt labels with 0.48 tracking.
- Selected color `#DAB316`.
- Inactive color `#B4B4B4`.
- Selected label has soft yellow glow.
- Use local assets under `Assets.xcassets/tabbar` for Home/Search/Shorts/New & Hot icons.

## Storefront Menu Tabs

- Render backend tabs in returned order.
- Do not remove backend tabs.
- If more than 4 tabs are returned, show the arrow/more affordance.
- Home may appear in both app bottom tab and storefront menu; do not conflate those layers.
- Menu tabs should sit above the app bottom bar and use Figma glass-chip styling.

## Profile UI

- Profile selection uses `sliceBg`, centered Sony logo, `Who's Watching?`, and profile cards.
- Profile selection tap should animate selection before entering storefront.
- Create/edit profile flows share the same editor.
- Avatar grid should show 3 columns and size from available width.
- Selected avatar preview should be centered in create/edit.
- Gender/date picker taps must dismiss keyboard.

## Search UI

- Search is pushed without bottom tab bar.
- Back should follow navigation stack semantics.
- Keyboard should not push the main bottom bar on screens that still use it.
- Search result filter heads should derive from data, not hardcoded labels.
- AI search currently uses native speech-to-text and the same search API until a future AI endpoint is provided.

