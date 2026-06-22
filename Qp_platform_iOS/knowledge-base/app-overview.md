# App Overview

Last updated: 2026-06-22

## 1. Product Summary

This app is a Sony LIV Quickplay iOS proof of concept focused on demonstrating a premium OTT browsing experience with Sony-style branding, reusable discovery rails, clean architecture, and a controlled mix of live and mocked business behavior.

It is intended for:

- internal business demos
- product/design review
- architecture validation
- future production integration planning

## 2. Current App Surfaces

### Launch and Auth

- splash
- login
- OTP
- invalid OTP state
- successful sign-in state

### Profile Flows

- profile selection
- create profile
- edit profile
- avatar picker
- cohort preference flow
- profile switch

### Discovery and Consumption

- storefront home
- storefront tab switcher
- search
- text AI search result flow
- mocked voice AI search flow
- content detail

### Account and Utilities

- profile hub
- settings
- cache clear action
- mocked support/account/legal destinations

## 3. Primary User Flow

The default business demo flow is:

1. launch splash
2. login
3. OTP verification
4. profile selection
5. storefront browsing
6. detail/search/profile exploration

The app also supports branching into:

- settings from profile hub
- detail from storefront, search, or profile hub
- profile editing from profile selection and settings

## 4. Navigation Model

The app uses a top-level screen coordinator in `AppFlowViewModel`.

This means:

- screen changes are centrally managed
- return destinations from detail/profile surfaces are remembered
- the app shell can preserve consistent background and navigation treatment

Bottom navigation currently represents the main Sony browsing shell:

- Home
- Search
- Shorts
- New & Hot
- Profile

## 5. Branding Direction

The codebase has been shifted to Sony LIV-first visible branding.

That includes:

- Sony-visible copy
- Sony Quickplay request headers and runtime constants
- Sony-style bottom navigation labels
- Sony-focused business and technical documentation

Important caveat:

Some backend integrations are still generalized Quickplay endpoints and some user-account flows are still mock-backed, which is expected for the current POC phase.

## 6. Content Model Strategy

The storefront is designed around reusable content primitives rather than many one-off section implementations.

Core idea:

- hero can be treated specially
- all other rails should be driven by section metadata and card aspect ratio

This reduces duplication and supports multiple cohorts without copying entire screen implementations.

## 7. What Is Real vs Mocked

### Real or close to real

- runtime bootstrap
- storefront feeds
- search feed
- detail metadata
- recommendation fetch with fallback
- remote image rendering and caching

### Mocked or local-first

- auth verification outcome
- subscription state
- profile persistence
- continue watching and favorites user state
- voice-search backend
- some settings/business action screens

## 8. Reuse Expectations

The app is expected to keep reusing:

- shared card views
- shared section/rail structures
- shared image components
- shared session state
- shared navigation patterns

New screens should follow the same rule unless there is a true product reason to diverge.

## 9. Current Documentation Set

Use these docs together:

- `architecture.md`
  system structure and engineering boundaries
- `api-integration.md`
  providers, endpoints, status, and integration gaps
- `ui-registry.md`
  shared UI building blocks

This file is the high-level product and app-surface lens over those lower-level technical docs.

## 10. Next Recommended Product/Engineering Steps

1. Finalize remaining Sony Figma pixel polish for the storefront shell and profile/settings screens.
2. Replace mocked auth and profile services with production-ready endpoints.
3. Wire real user-state APIs for favorites, resume, and continue watching.
4. Finalize voice/text AI search contracts.
5. Add deeper test coverage for primary demo journeys.
