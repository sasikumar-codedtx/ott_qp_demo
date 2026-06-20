# Architecture

## Current Standard

This app follows a feature-first Clean Architecture structure:

```
Features/{Feature}/
  Data/
  Domain/
  Presentation/
Core/
Shared/
```

## Layer Rules

- `Presentation` depends on `Domain`
- `Data` depends on `Domain`
- `Domain` depends on nothing app-specific
- Views never call `URLSession`
- ViewModels never decode DTOs
- Repository implementations map DTOs into domain entities

## Navigation

The app uses a root flow coordinator style via `AppFlowViewModel`.

Key flow branches currently include:
- auth: splash -> login -> otp
- profile setup: profile selection -> editor -> avatar picker
- viewing: storefront/search/profile hub -> detail
- account: profile hub -> settings

Navigation state should preserve the calling surface when drilling into detail screens.

## Image Loading

All remote images should use `CachedAsyncImage`.
