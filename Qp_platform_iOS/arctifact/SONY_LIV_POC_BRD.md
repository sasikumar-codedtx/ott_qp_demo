# Sony LIV Quickplay POC BRD

Last updated: 2026-06-22
Owner: Product + Engineering POC team
Status: Working business requirements baseline

## 1. Overview

This proof of concept demonstrates a Sony LIV mobile experience on top of a Quickplay-backed architecture, with Sony-first branding, Sony-style navigation, and a business flow that covers the critical OTT surfaces needed for stakeholder review.

The POC is intended to answer one question well:

Can we present a Sony LIV-shaped consumer experience, with reusable architecture and configurable rails, before full backend, identity, and personalization integrations are finalized?

## 2. Problem Statement

The current product exploration needs a high-confidence demo layer that can:

- show a Sony-branded OTT experience end to end
- validate navigation, content discovery, profile switching, and content-detail behavior
- de-risk future Quickplay API integration by separating reusable platform concerns from screen-specific UI work
- let product, business, and design stakeholders review interaction quality before all services are production-ready

## 3. Goals

- Deliver a Sony LIV branded iOS experience across launch, auth, storefront, search, detail, profile, settings, and onboarding/profile-creation flows.
- Support a configurable storefront where hero treatment is special-cased and the remaining sections are data-driven from section metadata.
- Reuse rail, card, image, and navigation patterns so later cohort and API additions do not cause UI duplication.
- Keep mocked areas realistic enough for demos while making the integration seams explicit for later API hookup.
- Produce documentation that can be used for internal handoff, design review, and engineering planning.

## 4. Non-Goals

- Production authentication and entitlement logic
- Real payment or subscription fulfillment
- Final recommendation tuning or ML ranking behavior
- Production speech-to-text or AI search backend integration
- Complete settings/legal/account backend coverage
- Final analytics, A/B experimentation, or release readiness

## 5. Target Users

- Anonymous or pre-auth demo user evaluating the launch, login, and OTP journey
- Signed-in subscriber exploring storefront, detail, search, and profile surfaces
- Household user switching between multiple profiles and cohorts
- Internal product, design, partner, and business stakeholders reviewing Sony LIV UX direction

## 6. Core User Journeys

### Journey A: First open to sign-in

1. User lands on Sony LIV launch screen.
2. User moves to login.
3. User enters phone number.
4. User enters 6-digit OTP.
5. Success state confirms sign-in and subscription mock.

### Journey B: Sign-in to profile selection

1. After auth, user lands on profile selection.
2. User chooses an existing profile or creates a new one.
3. Selected profile determines cohort styling and content feed context.

### Journey C: Storefront browsing

1. User opens Home.
2. User sees Sony-style top header, tab dock, and bottom nav.
3. Hero section is rendered with special layout treatment.
4. Remaining sections are rendered from section metadata and item aspect ratio.
5. Additional sections lazy load as the user scrolls.

### Journey D: Search and AI search

1. User taps Search from bottom nav.
2. User sees popular search or recent/entry state.
3. User can search by text.
4. If voice mode is enabled in profile/settings, tapping mic moves the user into mocked voice capture flow.
5. Search results are shown in Sony-style result layout.

### Journey E: Title discovery to detail

1. User taps a content card.
2. User lands on an edge-to-edge detail page.
3. User sees metadata, artwork, CTA state, similar-content recommendations, and supporting rails.
4. Resume/favorite/watch-state hooks exist at architecture level and can be upgraded with real APIs.

### Journey F: Profile and settings

1. User opens Profile from bottom nav.
2. User sees selected profile, continue watching, favorites, recommendations, and settings entry points.
3. User can move into profile switch, edit profile, create profile, settings subpages, and mocked account/support screens.

## 7. Functional Scope

### In scope

- Sony LIV launch screen
- Login, OTP, invalid OTP, signed-in success
- Profile selection
- Create profile and edit profile mocked flows
- Cohort selection experience
- Sony storefront with bottom nav and tab dock
- Data-driven content rails with reusable card system
- Lazy loading for storefront sections
- Detail page
- Search page, text search, mocked voice search, result screens
- Profile hub and settings stack
- Image caching
- Knowledge base and handoff documentation

### Partially in scope

- Continue Watching: UI and architecture wired, full production state still pending service hardening
- Favorites: UI and architecture wired, still mockable depending on auth/runtime availability
- Recommendations: shared recommendation patterns exist, ranking/source refinement still pending
- Profile management backend sync: local/mock-first today, real persistence later

### Out of scope for this phase

- Billing purchase journey
- DRM playback
- Downloads backend
- Real notifications and device linking
- Full accessibility certification
- Offline-first data sync

## 8. Business Rules

- Sony branding must be consistent across primary consumer-facing surfaces.
- Storefront hero may use custom treatment, but all downstream rails should be driven by section configuration.
- Rail rendering must be reusable and derived from content shape, especially aspect ratio metadata.
- Navigation should support native push/back behavior where screens are entered through stacks.
- Top-level demo flow should remain coherent even when backend data is mocked.
- Profile context should influence storefront/search/detail personalization hooks.

## 9. UX Principles

- Edge-to-edge visual presentation on premium surfaces
- Strong Sony identity in navigation, header, and high-impact surfaces
- Reusable rail language rather than one-off section implementations
- Fast-scroll browsing optimized for OTT discovery behavior
- Clear handoff between mocked and integrated business states

## 10. Success Criteria

- Stakeholders can complete the primary end-to-end demo without dead ends.
- No visible Aha-branded copy remains in the Sony demo experience.
- Home, Search, New & Hot, Shorts, and Profile surfaces feel coherent as one product.
- Profile/settings/auth flows feel sufficiently complete for business review.
- Engineering can clearly identify which flows are integrated, mocked, or staged for next iteration.

## 11. Risks

- Some backend endpoints remain Quickplay-configured and not yet finalized as production Sony contracts.
- Authenticated states such as favorites/bookmarks may depend on runtime token availability.
- Voice search is mocked until speech and semantic-search APIs are finalized.
- Rail rendering quality depends on section metadata consistency from upstream content services.

## 12. Open Items

- Final Sony-approved asset pack for icons, logos, and typography
- Production auth token lifecycle and secure session persistence
- Real profile list/update/delete APIs
- Final New & Hot content source
- AI search service contract for text and voice mode
- Playback/resume contract and entitlement-gated CTA logic

## 13. Current POC Readiness Summary

- Brand migration: largely complete in code-level copy and UI labels
- Storefront architecture: reusable and data-driven
- Profile/settings breadth: broad enough for demo, still partly mocked
- Search/detail/profile integration seams: established
- Documentation: available for business and technical handoff
