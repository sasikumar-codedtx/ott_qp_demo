# Storefront, Cohort, And Data Reference

## App Bottom Tabs vs Storefront Menu Tabs

Bottom app tabs are product-level destinations:
- Home / Storefront
- Search
- Shorts
- New & Hot
- Profile entry

This is controlled by `AppFlowViewModel.MainTab` and `BottomNavigationSelection`.

Storefront menu tabs are backend-driven tabs inside a storefront response.
They are controlled by `StorefrontViewModel.selectedTabID`.

Do not mix these two tab systems.

## Cohorts

Current app cohorts:
- `entertainment`
- `sports`
- `kids`
- `realityShows`

Configured storefront IDs:
- Entertainment: `EBFB096C-CA11-4E32-A231-8A7FA15B5E13`
- Sports: `DCBF412C-437B-404F-BE31-F18D7F4BEB87`
- Reality: `383C7B3E-0BC0-4629-B80C-BC074EA96753`
- Kids: temporarily uses reality ID until final kids URL/source is provided.

## Preference To Cohort

- Entertainment preference -> entertainment cohort.
- Sports preference -> sports cohort.
- Reality Shows preference -> realityShows cohort.
- Microdramas preference -> entertainment cohort.
- Kids profile -> kids cohort.

Micro Drama is not a cohort.

## Cohort Override

When content is selected:
1. Classify the content into a preference bucket.
2. Store it in recent per-profile history.
3. If a bucket reaches 6+ recent interactions, it becomes the dominant signal.

Sports and reality can override the effective cohort.
Micro Drama remains a preference signal and does not become a cohort.

## Storefront Rules

- Fetch storefront based on active cohort.
- Render all backend tabs received.
- Render sections based on data objects, not hardcoded rails.
- Hero is the main exception: demo variants may be hardcoded by cohort/tab for visual review.
- Use section aspect ratio/image ratio to size cards.
- If a section is Continue Watching, use local continue-watching data; hide it if empty.
- `View All` should open a pushed grid page using the section image aspect ratio and lazy loading.
- Keep old data visible while refreshing after the first load.
- Use soft shimmer/animation for loading.

## Dedicated Surfaces

- New & Hot has a dedicated storefront view model/surface.
- New & Hot currently uses a placeholder source and prefers Micro Drama tab when present.
- Micro Drama final storefront URL is still pending.
- Shorts currently uses a mock feed and buffering; future API is pending.
- Kids storefront final source is pending; fallback exists for demo safety.

## Images

- Do not use hardcoded image base URLs in views/entities.
- Build image URLs through `ImageURLBuilder` using runtime config.
- Use `PosterImageView`/Kingfisher for remote images and cache behavior.
- Choose image ratio based on content/section ratio: 16:9, 2:3, landscape/portrait, etc.

## Content Navigation

Entitlement checks are removed for demo.

Content taps should route by content type:
- Playable short-form/player content can go direct to player if playback URL exists.
- Detail-worthy movie/show content should push detail.
- Unknown/missing `cty` should degrade safely to detail when possible and be logged/handled as unsupported.

