# Cohort Logic

Last updated: 2026-06-22

## Purpose

This file explains how cohort selection, profile preference, storefront routing, and content-behavior override currently work in the app.

## Current concepts

### Bottom app tabs

These are product-level destinations.

Examples:
- Home / Storefront
- Search
- Shorts
- New & Hot
- Profile entry

This layer is controlled by `AppFlowViewModel.MainTab`.

### Storefront menu tabs

These are backend-driven tabs inside the storefront screen.

They come from the storefront response and decide which set of sections/rails is rendered inside storefront.

This layer is controlled by `StorefrontViewModel.selectedTabID`.

### Cohort

Cohort is the top-level backend routing bucket used by storefront, search, and detail/recommendation APIs.

Current app cohorts:
- `entertainment`
- `sports`
- `kids`
- `realityShows`

## Profile preference to cohort mapping

Profile preference and cohort are not exactly the same.

Current mapping:
- `entertainment` preference -> `entertainment` cohort
- `sports` preference -> `sports` cohort
- `realityShows` preference -> `realityShows` cohort
- `microdramas` preference -> `entertainment` cohort
- `kids profile = true` -> always `kids` cohort

So Micro Drama is currently a preference, not a real cohort.

## Current session behavior

When a profile is selected, the app stores:
- profile id
- selected preference
- selected base cohort

This session state is maintained in `DemoSessionStore`.

## Content-selection override logic

When user selects content, the app classifies that content into a preference bucket and stores the interaction in local per-profile history.

Current buckets:
- `entertainment`
- `sports`
- `realityShows`
- `microdramas`

If one bucket reaches `6+` recent interactions, it becomes the dominant preference signal.

Current override rules:
- dominant `sports` -> effective cohort becomes `sports`
- dominant `realityShows` -> effective cohort becomes `realityShows`
- dominant `entertainment` -> effective cohort becomes `entertainment`
- dominant `microdramas` -> effective cohort remains `entertainment`

## Kids behavior right now

The app does not currently rely on a confirmed final kids storefront source.

Current behavior:
- try kids cohort storefront first
- if kids storefront is empty or unavailable, fall back to entertainment storefront

This is a temporary safety fallback and should be replaced once the final kids storefront URL/source is confirmed.

## Important product clarification

Micro Drama should not be modeled as a cohort.

Current implemented model:
- Storefront menu tabs reflect only what backend storefront returns
- Micro Drama is not injected as a synthetic storefront menu tab
- Micro Drama remains a preference/affinity bucket, not a cohort
- Home storefront stays backend-driven and is not replaced by Micro Drama routing
- New & Hot has its own dedicated storefront surface and currently reuses the placeholder Micro Drama storefront source
- The New & Hot surface prefers the `Micro Drama` tab when that tab exists in the returned storefront
- Cohort remains a backend routing bucket

## Pending architecture corrections

- Replace placeholder Micro Drama storefront source with the final product-approved source/behavior
- Replace placeholder New & Hot storefront source with the final backend source
- Replace kids fallback with final kids storefront source when provided
