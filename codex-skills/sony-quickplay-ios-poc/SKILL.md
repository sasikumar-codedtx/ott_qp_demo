---
name: sony-quickplay-ios-poc
description: Use when working on this Sony LIV-style Quickplay iOS POC. Follow its Clean Architecture folders, Figma-to-SwiftUI parity workflow, storefront/cohort rules, navigation policy, image URL/caching conventions, mocked auth/profile behavior, and validation steps.
---

# Sony Quickplay iOS POC

## When To Use

Use this skill for code changes, reviews, refactors, or implementation plans inside the `Qp_platform_iOS` SwiftUI app.

## First Steps

1. Read the relevant reference before editing:
   - Architecture or feature placement: `references/architecture.md`
   - Figma/UI parity work: `references/ui-figma.md`
   - Storefront, tabs, cohorts, and content routing: `references/storefront-data.md`
   - Verification and QA: `references/validation.md`
2. Inspect the current code before deciding. Prefer `rg` and targeted `sed`.
3. Preserve existing user changes. The repo is often dirty during design iteration.
4. For any Figma URL, use the Figma MCP workflow: `get_design_context` and `get_screenshot` before editing.

## Core Rules

- Keep feature code in `Features/<Feature>/{Data,Domain,Presentation}`.
- Keep app-wide utilities in `Core/` and reusable UI in `Shared/Components/`.
- Prefer existing shared components before creating new views.
- Avoid hardcoded backend/image URLs, auth tokens, or product data in presentation code.
- Use `QuickplayRuntimeConfig`, `ImageURLBuilder`, repositories, and mapping layers for runtime data.
- Use mocked auth/profile/favorites where the POC intentionally mocks behavior.
- Do not model Micro Drama as a cohort. It is a tab/surface/preference signal.
- Use native SwiftUI `NavigationStack` push semantics and toolbar items for pushed screens.
- Preserve iOS swipe-back behavior.
- Keep edge-to-edge artwork/gradients under the status bar and behind translucent chrome.
- For images, use `PosterImageView`/Kingfisher and config-built URLs.
- For rails, reuse section/card components; do not duplicate horizontal row logic.
- Run the iOS build after code changes when feasible.

## Build Command

Use:

```bash
xcodebuild -project Qp_platform_iOS.xcodeproj -scheme Qp_platform_iOS -destination 'id=68734945-9042-47FC-8155-A83039B94734' build
```

If the destination is unavailable, inspect simulators and pick an available iPhone destination.

