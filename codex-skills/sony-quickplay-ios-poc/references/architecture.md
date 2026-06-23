# Architecture Reference

## Project Layout

- `Core/Config`: environment and runtime config, including `QuickplayRuntimeConfig`, `QuickplayConfigurationStore`, and `QuickplayCohort`.
- `Core/DI`: `AppContainer` wires dependencies.
- `Core/Networking`: shared request/client behavior.
- `Core/Session`: local demo/session state such as profile, cohort, and continue-watching state.
- `Core/Utils`: shared helpers such as `ImageURLBuilder`, `DemoRailComposer`, and profile artwork.
- `Core/Playback`: preview/full-player support.
- `Features/<Feature>/Data`: API clients, DTOs, data sources, repository implementations.
- `Features/<Feature>/Domain`: entities, repositories, use cases, navigation policies.
- `Features/<Feature>/Presentation`: SwiftUI views and view models.
- `Shared/Components`: reusable UI.

## Clean Architecture Rules

- Presentation must not construct backend URLs directly.
- Domain entities should stay simple and not reach into async config stores or globals.
- Runtime config should be resolved in data, repository, mapping, or injected helper layers.
- Repositories hide remote vs mock behavior.
- View models coordinate use cases and UI state; views should not own business decisions.
- For demo-only behavior, keep mocks named clearly and isolated in `Data` or `Core/Session`.

## Dependency Wiring

`AppContainer` is the composition root. Add new repositories/use cases there rather than constructing them inside views.

Current wiring style:
- Auth is mocked.
- Profiles are mocked/local.
- Profile home data is mocked.
- Storefront/search/detail use remote repositories.
- Shorts currently uses a mock repository with buffering/playback behavior.

## Navigation Rules

- Use `NavigationStack` and typed routes where possible.
- Pushed screens should use `.toolbar` with `NavigationChromeButton`/`NavigationChromeTitle`.
- Avoid custom in-view back buttons on pushed screens.
- Do not hide native navigation in ways that break swipe-back.
- Full player can be full-screen when playback requires it.

## Local State Rules

`DemoSessionStore` owns demo state:
- Active profile id.
- Active preference/cohort.
- Voice AI search preference.
- Content-selection history for cohort override.
- Continue watching by profile.

Do not scatter these values across unrelated `UserDefaults` keys.

