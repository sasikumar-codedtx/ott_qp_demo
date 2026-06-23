# OTT Task List

Last updated: 2026-06-22

## Completed

- [x] Storefront "View All" opens a full-page grid with lazy loading.
- [x] Storefront and browse pages show shimmer on initial load.
- [x] Browse pages keep previous data visible while refreshing.
- [x] Shorts feed still uses local buffering and cached playback URLs.
- [x] Kids profile no longer hard-fails on storefront load; it falls back to entertainment storefront when the kids storefront is empty or unavailable.
- [x] Storefront menu tabs now use backend tab order as-is.
- [x] Storefront menu arrow now appears only when more than 4 tabs are returned.
- [x] Bottom app tabs are now separated from storefront menu-tab selection.
- [x] New & Hot now uses its own dedicated storefront view model and prefers the `Micro Drama` tab when present.
- [x] Micro Drama no longer appears as a synthetic storefront menu tab.
- [x] Home storefront no longer gets replaced by Micro Drama preference routing.
- [x] Pushed screens use SwiftUI navigation toolbar items for primary back/right actions.
- [x] Storefront hero demo variants are hardcoded by selected tab/cohort so carousel, stacked, and immersive hero types can be reviewed.
- [x] Card taps now route through content-type navigation policy with entitlement checks removed for demo.
- [x] Player-type content such as shorts, trailers, promos, channels, live events, events, clips, and highlights now opens player directly when a playback URL exists.

## In Progress

- [ ] Micro Drama final surface confirmation.
Status:
Current implementation keeps Micro Drama in backend storefront tabs as-is and reuses the placeholder storefront source for the bottom `New & Hot` surface. Replace with the final product-approved surface behavior if it differs.

## Open

- [ ] Micro Drama storefront URL swap.
Status:
Replace placeholder storefront URL with final Micro Drama storefront URL when shared.

- [ ] New & Hot storefront URL wiring.
Status:
Replace placeholder storefront/API path with the final New & Hot source when shared if it is different from the Micro Drama-backed demo behavior.

- [ ] Kids storefront final URL confirmation.
Status:
Current app uses fallback behavior. Once the dedicated kids storefront URL/source is confirmed, replace fallback logic.

- [ ] Search Figma parity review.
Status:
Search has been reworked against the provided video reference. It still needs final product QA against the intended motion and visual polish.

- [ ] Settings Figma parity review.
Status:
Needs a focused visual review pass against Figma before it can be marked complete.

- [ ] Cohort override behavior verification.
Status:
Current override logic uses recent content-selection history and applies an override once a bucket reaches 6+ interactions. Sports and reality can change the effective cohort; Micro Drama remains a preference signal only and does not reroute Home anymore.

- [ ] Confirm backend behavior for missing `cty` values.
Status:
The app currently defaults missing content type to `content`, logs it as unsupported, and falls back to detail if possible. If the backend intentionally sends `cty=content`, confirm whether it should route to detail or player.
