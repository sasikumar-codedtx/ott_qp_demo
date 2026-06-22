# Architecture

Last updated: 2026-06-22

## 1. Guiding Principles

This Sony LIV Quickplay POC is structured to behave like a production-ready app foundation rather than a throwaway demo.

The core architectural rules are:

- follow clean architecture boundaries
- keep Sony branding and OTT UI primitives reusable
- isolate network contracts inside feature data layers
- make mocked and live-backed behavior explicit
- preserve a clear upgrade path from demo state to production integrations

## 2. Project Structure

The app follows a feature-first clean architecture layout:

```text
Core/
  Config/
  Constants/
  DI/
  Networking/
  Session/
  Utils/

Features/{Feature}/
  Data/
    DataSources/
    Models/
    Networking/
    Repositories/
  Domain/
    Entities/
    Repositories/
    UseCases/
  Presentation/
    ViewModels/
    Views/

Shared/
  Components/
```

## 3. Dependency Direction

Dependencies flow one way:

```text
Presentation -> Domain -> Data -> Core
```

Rules:

- SwiftUI views render state and trigger intents only.
- View models orchestrate screen logic and call use cases.
- Use cases depend on repository contracts from the domain layer.
- Repository implementations live in the data layer and translate DTOs into domain entities.
- Request construction, transport, and response decoding stay out of presentation code.

## 4. Application Shell

`Qp_platform_iOSApp` is intentionally thin:

- configures the shared image cache at launch
- mounts `ContentView`
- delegates app flow ownership to `AppRootView`

`AppRootView` is the app shell. It:

- owns the top-level screen switch
- applies the correct background style for each surface
- composes feature screens from a single source of truth

`AppFlowViewModel` is the flow coordinator. It manages:

- app start
- auth progression
- active profile selection
- storefront/search/profile/detail routing
- voice AI preference state
- return targets when leaving detail or profile areas

## 5. Dependency Injection

`AppContainer` is the central composition root.

It wires:

- auth repository
- profile repository
- profile hub repository
- storefront repository
- search repository
- detail repository

Important rule:

- screens do not create repositories directly
- repositories do not leak transport concerns into view models

## 6. Runtime Split

The POC intentionally uses a hybrid runtime model:

- Sony Quickplay-backed services provide content discovery and metadata
- local/mock-backed repositories provide user-specific demo state

This split keeps the browsing experience realistic while avoiding fragile dependencies on unfinished auth/account services.

### Sony-backed areas

- runtime config bootstrap
- storefront tabs and sections
- content search
- content detail
- recommendations
- image URL generation

### Local/mock-backed areas

- auth completion state
- profile CRUD
- active cohort persistence for the session
- continue watching rail content
- favourites rail content
- settings subpages and support flows
- voice search execution behavior

## 7. Feature Responsibilities

### AppFlow

- owns top-level navigation and screen switching
- coordinates cross-feature state like active profile and return path

### Auth

- handles phone entry, OTP entry, invalid OTP, and mock success states

### Profile

- owns profile selection, creation, editing, avatar choice, and profile-home composition

### Storefront

- fetches Sony Quickplay storefront payloads
- normalizes containers into reusable `StorefrontSection` and `StorefrontItem` models
- supports lazy loading and cohort-aware tab switching

### Search

- handles popular/default state
- text search
- mocked voice-search mode and AI result presentation

### Detail

- loads metadata for a selected item
- resolves recommendation rails
- presents edge-to-edge premium content layout

## 8. Session and Personalization

`DemoSessionStore` is the session-scoped holder for:

- active `QuickplayCohort`
- whether voice AI search is preferred

This keeps profile-driven behavior out of view code and allows multiple features to read the same session-level state.

## 9. Cohort Model

Profile selection is the current source of truth for cohort choice.

Flow:

1. User selects or switches a profile.
2. Profile maps to a `QuickplayCohort`.
3. `AppFlowViewModel` updates `DemoSessionStore`.
4. Storefront, search, and detail use the active cohort when building requests.

Current design intent:

- cohorts can alter feed style and top-level discovery behavior
- reusable rail rendering stays shared across cohorts
- only hero/header treatment should vary where needed

## 10. Navigation Model

Navigation follows native iOS behavior as closely as possible for the POC.

Main branches:

- auth: splash -> login -> OTP
- profile setup: selection -> avatar picker -> profile editor
- browsing: storefront -> search/profile/detail
- account: profile hub -> settings and subpages

Key rules:

- keep bottom navigation at the shell level
- push deeper pages in stack-like journeys
- preserve swipe-back expectations where screens are navigated as detail flows
- remember return surfaces when opening detail from different origins

## 11. Reuse Rules

These rules matter because the OTT surface can become unmaintainable quickly without them.

- `StorefrontSection` and `StorefrontItem` are the shared rail primitives
- hero is the main exception; downstream rails should be data-driven
- card rendering should be configured from content metadata, especially aspect ratio
- recommendation and continue-watching style rails should reuse shared layout primitives
- views never decode DTOs
- view models never build raw requests

## 12. Networking Pattern

Each feature owns its request building and remote parsing:

- `Router`
  request construction
- `APIClient`
  transport execution
- `RemoteDataSource`
  remote fetch orchestration
- `RepositoryImpl`
  mapping into domain entities

This keeps upstream contract changes localized.

## 13. Caching and Media

Image rendering is standardized through shared image components.

Current policy:

- Kingfisher-backed image loading
- 500 MB disk cache target
- bounded memory usage
- user-triggered cache clearing through settings

Reasoning:

- avoids maintaining a custom image pipeline
- improves scroll performance on media-heavy OTT surfaces
- gives demo devices a simple reset mechanism

## 14. Current Strengths

- clean architecture boundaries are in place
- Quickplay runtime config is centralized
- rail and card reuse has been prioritized
- session-level cohort and voice preference state is shared correctly
- app-flow orchestration is centralized rather than scattered across screens

## 15. Known Gaps

- some profile/account flows are intentionally mock-first
- some settings destinations are hardcoded demo pages
- final pixel polish for a few Figma surfaces remains
- more automated UI/view-model testing is still needed

## 16. Recommended Next Steps

1. Complete any remaining section-layout normalization so non-hero storefront rails are entirely configuration-driven.
2. Move mock profile/account sources behind real service adapters when production contracts stabilize.
3. Add tests around app flow, storefront pagination, and cohort switching.
4. Tighten final navigation-stack behavior where deeper settings/profile screens are presented.
