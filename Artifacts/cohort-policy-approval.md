# Storefront Cohort Policy Proposal

## Objective

The app should not curate storefront rails or manually reorder content. The app only records user behavior signals per profile and sends the correct `chrt` policy attribute in API requests. The backend owns storefront layout, rail boosting, and final content ordering.

## What The App Stores

The app stores a small per-profile click table locally.

| Profile ID | Reality Clicks | Sports Clicks |
|---|---:|---:|
| `<profile-id>` | `0...n` | `0...n` |

Only click counts are stored. Storefront responses, rail order, and boosted rails are not stored by the app.

## Runtime Click Capture

When a user taps a content card, the app reads the card signal.

| Card Signal | Counter Updated |
|---|---|
| `cust_sc = shows` or reality-related value | `realityClicks += 1` |
| `cust_sc = sports` or sports-related value | `sportsClicks += 1` |
| Any other value | No cohort-policy counter change |

The current session storefront is not immediately rebuilt from these clicks. The click table is persisted and used when the profile/storefront is opened again.

## Policy Resolution On App Open Or Profile Selection

When the app launches or a profile is selected, the app reads that profile's click table and resolves the `chrt` value.

| Resolved Policy | `chrt` value | Condition |
|---|---|---|
| Entertainment Default | `entertainment` | No meaningful Reality/Sports threshold reached |
| Reality + Entertainment | `sony2` | `realityClicks >= 2` and `< 5`, before Sports transition |
| Reality Transitioned | `reality` | `realityClicks >= 5` and Sports transition not reached |
| Reality + Sports | `sony3` | `realityClicks >= 5` and `sportsClicks >= 2` and `< 5` |
| Sports + Entertainment | `sony1` | `sportsClicks >= 2` and `< 5`, before full Sports transition |
| Sports Transitioned | `sports` | `sportsClicks >= 5` |

Sports full transition has highest priority once `sportsClicks >= 5`.

## URL Curation

All APIs that need storefront policy should use the resolved `chrt`.

Example:

```text
GET /catalog/storefront/landingscreen?...&pf=regular&chrt=sony2
```

or:

```text
GET /catalog/storefront/{sfid}/{tid}/containers?...&pf=regular&chrt=sports
```

## Important Separation

`pf` is profile type, not the content cohort policy.

| Field | Responsibility |
|---|---|
| `pf` | Profile type or entitlement/profile context, e.g. regular/kids if truly required |
| `chrt` | Storefront policy attribute: entertainment, sony2, reality, sony3, sony1, sports |

Entertainment, Sports, and Reality storefront behavior should be controlled by `chrt`, not by changing `pf`.

## Backend Responsibility

The backend uses `chrt` to decide:

- 100% Entertainment storefront
- subtle Reality rail boost
- 100% Reality storefront
- subtle Sports rail boost
- 100% Sports storefront

The app renders whatever rails and cards are returned by the backend.
