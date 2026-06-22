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
- [x] New & Hot now uses its own dedicated storefront view model with a placeholder storefront source.
- [x] Micro Drama no longer appears as a synthetic storefront menu tab.

## In Progress

- [ ] Micro Drama final surface confirmation.
Status:
Current implementation uses Micro Drama preference/affinity to route the Home storefront to a separate placeholder storefront source. Replace with the final product-approved surface behavior if it differs.

## Open

- [ ] Micro Drama storefront URL swap.
Status:
Replace placeholder storefront URL with final Micro Drama storefront URL when shared.

- [ ] New & Hot storefront URL wiring.
Status:
Replace placeholder storefront/API path with the final New & Hot source when shared.

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
Current override logic uses recent content-selection history and applies an override once a bucket reaches 6+ interactions. Needs final product confirmation for whether Micro Drama should continue to redirect Home storefront content.
