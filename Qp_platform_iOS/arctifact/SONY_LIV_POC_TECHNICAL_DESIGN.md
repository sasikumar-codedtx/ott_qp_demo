# Sony LIV Quickplay POC Technical Design

Last updated: 2026-06-22
Owner: iOS engineering
Status: Active implementation design

## 1. Purpose

This document describes how the Sony LIV Quickplay POC is structured, what is integrated today, what remains mocked, and how the project is intended to scale without rewriting core UI flows.

## 2. Architectural Goals

- Follow clean architecture boundaries so API churn does not leak into presentation code.
- Keep reusable OTT primitives centralized: cards, rails, navigation, header, caching, and session state.
- Separate screen orchestration from transport details.
- Make Sony branding a presentation/configuration concern, not an ad hoc string replacement exercise.
- Preserve a safe path from mocked data to live integration.

## 3. Architecture Style

The project follows a feature-first clean architecture:

- `Core`
  Shared configuration, networking, session, dependency injection, utilities, and constants.
- `Features/<Feature>/Data`
  DTOs, routers, API clients, remote/local data sources, repository implementations.
- `Features/<Feature>/Domain`
  Entities, repository contracts, and use cases.
- `Features/<Feature>/Presentation`
  SwiftUI views and view models.
- `Shared`
  Reusable cross-feature components and styles.

This keeps the dependency direction consistent:

Presentation -> Domain -> Data -> Core

Concrete implementations are assembled in the app container and injected into view models/use cases.

## 4. Current Module Coverage

### App flow

- Root routing
- launch-to-auth-to-profile-to-main-app transitions
- selected profile and high-level navigation state

### Auth

- mobile number entry
- 6-digit OTP entry
- invalid OTP state
- mock signed-in success state

### Storefront

- tab discovery and selection
- hero section specialization
- reusable rail rendering
- lazy loading for additional sections
- cohort-aware presentation

### Detail

- content detail fetch
- recommendation fetch
- favorite/resume hooks
- edge-to-edge layout

### Search

- popular/default state
- text query flow
- mocked voice capture flow
- AI-style result presentation

### Profile

- profile selection
- profile hub
- edit/create profile flows
- avatar selection
- mock cohort/preferences configuration

### Settings

- hardcoded but navigable settings surface
- reusable stack-based navigation behavior
- mock account/support/legal destinations
- cache clear action

## 5. Data Strategy

The codebase uses a hybrid approach:

- live or semi-live Quickplay-backed content APIs for storefront/detail/search-oriented data
- local or mock-backed profile/account/demo state where production contracts are not ready

This allows realistic browsing and content demos while keeping unstable account flows controllable.

## 6. API and Runtime Configuration

Runtime endpoint configuration is modeled through:

- `QuickplayRuntimeConfig`
- `QuickplayConfigurationStore`
- `AppEnvironment`

The app is Sony-oriented at the request-surface level:

- Sony web origin/referer headers
- Sony Quickplay client/device configuration
- Sony branding in presentation copy

Endpoint resolution remains configuration-driven so environments can be swapped without rewriting feature code.

## 7. Networking Pattern

Each feature owns its own transport definitions:

- `Router`
  Builds `URLRequest`
- `APIClient`
  Executes transport calls
- `RemoteDataSource`
  Converts remote responses into DTOs
- `RepositoryImpl`
  Maps DTOs into domain entities

This allows service contract changes to stay localized within the feature data layer.

## 8. Storefront Design System Approach

The storefront is intentionally reusable rather than section-by-section hardcoded.

### Key decisions

- Hero is treated as the only layout exception.
- Downstream rails are driven by section metadata and aspect ratio.
- A reusable card view is used across rails instead of one custom card per section.
- Cohort-specific header treatment can vary while the rail system remains shared.

### Why this matters

This makes future cohort rollout cheaper:

- Entertainment, Sports, and future cohorts can share the same rail engine.
- Only top-level hero/header treatments need targeted customization.
- New section types can be mapped through configuration instead of view duplication.

## 9. Navigation Model

Navigation follows native stack behavior where detail/settings/editor flows are pushed.

### Principles

- Push deeper screens when they belong to a stack journey.
- Preserve swipe-back behavior on pushed routes.
- Keep bottom navigation at the app shell level.
- Keep modal usage limited to cases like tab overflow or temporary flows.

This matches the user’s requested navigation principle and makes the demo feel closer to a production iOS app.

## 10. Edge-to-Edge Rendering

Premium surfaces such as detail and media-led pages are designed to render edge to edge.

### Rules

- Background and gradient treatment should begin behind the status bar.
- Avoid visible black gaps above hero gradients unless intentionally designed.
- Header overlays should sit on top of content rather than carve out separate black bands.

## 11. Session and Personalization Hooks

The codebase keeps room for:

- selected profile context
- cohort selection
- bookmark/resume/favorite state
- voice-search mode preference

These are deliberately modeled as reusable app/session concerns so storefront, detail, search, and profile can all consume the same state without duplicate business logic.

## 12. Image Handling

Image delivery is centralized through reusable poster/image components.

### Current implementation

- Kingfisher-backed image loading and caching
- disk cache cap targeted at 500 MB
- explicit clear-cache affordance in settings

### Why this is preferred

- battle-tested caching behavior
- less custom image-pipeline code to maintain
- easier path to placeholder, retry, resizing, and memory tuning

## 13. Mock vs Integrated Areas

### Integrated or integration-ready

- storefront fetch structure
- detail fetch structure
- search fetch structure
- recommendation fetch structure
- runtime config loading

### Mock-first by design

- auth completion
- subscription state
- profile CRUD persistence
- some settings/account pages
- voice input recognition and semantic AI search orchestration

The project intentionally exposes these seams so the next integration pass can replace mocks without reworking view structure.

## 14. Reuse Rules

- One card primitive should serve multiple rail types through configuration.
- One rail/section renderer should handle most storefront sections.
- Recommendation rails should be shared across detail and profile-oriented discovery surfaces when possible.
- Continue Watching and similar horizontal content treatments should reuse layout primitives, not fork into custom implementations.

These rules reduce UI drift and directly support the “do not duplicate rails” requirement.

## 15. Current Known Gaps

- Final Sony-approved iconography and some pixel-level polish remain
- full production profile APIs are not wired yet
- AI voice/text orchestration remains mocked
- some business pages in settings are demo-safe placeholders
- rail sizing logic may still need tuning against final aspect-ratio mapping rules

## 16. Recommended Next Steps

1. Finalize bottom-nav and top-header pixel polish against latest Figma.
2. Normalize storefront section rendering rules into a single configuration map if any hardcoded exceptions still remain outside hero/header.
3. Replace remaining mock profile/account services with real APIs.
4. Unify recommendation and continue-watching feeds as shared reusable rail sources.
5. Add targeted UI and view-model tests for auth, storefront pagination, and profile routing.

## 17. Summary

The current codebase is set up as a professional-grade POC foundation rather than a throwaway demo. Clean architecture boundaries are in place, reusable OTT primitives are established, Sony branding is now the visible surface, and the remaining work is primarily API completion and final design polish rather than structural rework.
