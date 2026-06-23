# Validation Reference

## Before Editing

- Check `git status --short`.
- Assume the worktree may already contain user changes.
- Do not revert unrelated changes.
- Read the exact files you will modify.

## After Editing

Run:

```bash
xcodebuild -project Qp_platform_iOS.xcodeproj -scheme Qp_platform_iOS -destination 'id=68734945-9042-47FC-8155-A83039B94734' build
```

If build is not feasible, state why.

## UI QA Checklist

- Figma node fetched with both design context and screenshot.
- Shared component updated if the UI pattern is reused.
- Edge-to-edge artwork starts under status bar when required.
- Pushed screens use navigation toolbar back/right items.
- Swipe-back is preserved.
- Bottom app bar and storefront menu tabs do not affect each other's selected states.
- Remote images use config-driven URLs and cache.
- Keyboard dismissal works on text forms before opening sheets/pickers.
- Loading states are soft and not visually harsh.
- Mocks include realistic loading/activity delays when expected.

## Data QA Checklist

- No hardcoded auth tokens.
- No hardcoded service URLs in presentation/domain entities.
- Mock-only data is clearly isolated.
- Storefront tabs/sections are data-driven.
- Continue Watching uses local profile-scoped state.
- Favorites are mocked unless backend is explicitly added.
- Pending backend URLs are tracked in `Qp_platform_iOS/task-tracker/FUTURE_REQUIRED_URLS.md`.

