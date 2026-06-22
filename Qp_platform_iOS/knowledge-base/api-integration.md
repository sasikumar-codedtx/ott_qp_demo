# API Integration

Last updated: 2026-06-22

## 1. Integration Strategy

The app deliberately separates external content APIs from local demo state.

### Live or integration-ready providers

- Sony Quickplay runtime config
- Sony Quickplay storefront
- Sony Quickplay search
- Sony Quickplay detail metadata
- Sony Quickplay recommendation lookup
- Sony Quickplay image rendering

### Local or mock-backed providers

- OTP success/failure behavior
- profile CRUD
- active profile storage for the running demo
- continue watching data
- favourites data
- some settings/account subpages
- voice AI execution flow

This approach is intentional and should remain explicit in future handoffs.

## 2. Request Conventions

Most remote requests use shared Sony request conventions from `AppEnvironment` and `URLRequest.applyQuickplayHeaders()`.

Current request-level constants:

- `Origin=https://www.sonyliv.com`
- `Referer=https://www.sonyliv.com/`
- `client=sony-sony-androidmobile`
- `dt=androidmobile`
- `chrt=Sony1`
- `reg=IN`

Headers commonly applied:

- `Accept: */*`
- `Origin`
- `Referer`
- `User-Agent`

## 3. Runtime Bootstrap

### Purpose

Load environment-specific base URLs before feature APIs execute.

### Endpoint

`GET https://config-service-cdn.cms-qp.opt.quickplay.com/launch/config?device=androidmobile&client=sony-sony-androidmobile`

### Consumed by

- `QuickplayConfigurationStore`
- `QuickplayRuntimeConfig`

### Fallback behavior

If bootstrap fails, the app falls back to the hardcoded Sony POC endpoints in `Core/Config/AppEnvironment.swift`.

### Fallback bases

- `catalogURL`
- `storefrontURL`
- `vodMetaDataURL`
- `searchURL`
- `recommendURL`
- `imageResizeURL`
- `personalisationURL`

## 4. Cohort and Profile Flag Mapping

The active profile determines the active `QuickplayCohort`.

That cohort ultimately resolves into a `pf` value used in Sony Quickplay requests.

Current mapping intent:

- Entertainment -> `regular`
- Sports -> mapped to the sports-oriented demo path currently represented in code
- Kids -> `kids`
- unsupported or placeholder cohorts -> fallback to Entertainment behavior

Important note:

This mapping is currently part business rule and part demo constraint. It should be revisited once final Sony cohort contracts are confirmed.

## 5. API Catalog

### 5.1 Storefront

#### Purpose

Load top-level tabs, hero, and content rails for the active cohort.

#### Request

`GET <storefrontURL>/storefront/list?reg=all&dt=androidmobile&client=sony-sony-androidmobile&pf=<pf>&chrt=Sony1`

#### Code path

- `Features/Storefront/Data/Networking/StorefrontRouter.swift`
- `StorefrontAPIClient`
- `StorefrontRemoteDataSource`
- `StorefrontRepositoryImpl`

#### Notes

- response is container-driven
- repository normalizes payloads into `StorefrontSection` and `StorefrontItem`
- app follows source/container URLs returned by Sony payloads
- storefront supports lazy loading

#### Status

Integrated

### 5.2 Storefront Source Follow-up URLs

#### Purpose

Resolve tab-specific or section-specific content using Sony-provided source URLs.

#### Request

`GET <source-url-from-storefront-payload>`

#### Notes

- source URLs are normalized before decoding
- allows the app to stay payload-driven instead of hardcoding every section

#### Status

Integrated

### 5.3 Search

#### Purpose

Return searchable Sony content results for typed queries.

#### Request

`GET <searchURL>/content/search?mode=detail&st=published&term=<term>&pageNumber=1&pageSize=50&reg=IN&dt=androidmobile&client=sony-sony-androidmobile&pf=<pf>&chrt=Sony1`

#### Code path

- `Features/Search/Data/Networking/SearchRouter.swift`
- `SearchAPIClient`
- `SearchRemoteDataSource`
- `SearchRepositoryImpl`

#### Status

Integrated

### 5.4 Detail

#### Purpose

Load metadata for a selected content item.

#### Request

`GET <vodMetaDataURL>/content?ids=<content-id>&mode=detail&st=published&reg=IN&dt=androidmobile&client=sony-sony-androidmobile&pf=<pf>&chrt=Sony1`

#### Code path

- `Features/Detail/Data/Networking/ContentDetailRouter.swift`
- `ContentDetailAPIClient`
- `ContentDetailRemoteDataSource`
- `ContentDetailRepositoryImpl`

#### Status

Integrated

### 5.5 Recommendations

#### Purpose

Fetch “more like this” recommendations for the current title.

#### Request

`GET <recommendURL>/recommend/lookup?query=<base64-json-payload>`

#### Current payload shape

- `item`
- `type=more-like-this`
- fields for `dt`, `reg`, `client`, `pf`, `chrt`, and `cty`

#### Status

Integrated with fallback

### 5.6 Recommendation Search Fallback

#### Purpose

Keep the recommendation rail populated if the recommendation endpoint fails or returns nothing.

#### Request

`GET <searchURL>/content/search?mode=detail&st=published&term=<term>&pageNumber=1&pageSize=24&reg=IN&dt=androidmobile&client=sony-sony-androidmobile&pf=<pf>&chrt=Sony1`

#### Status

Integrated fallback path

### 5.7 Images

#### Purpose

Render posters, thumbnails, and card artwork.

#### Request pattern

`<imageResizeURL>/image/<id>/<ratio>.png?width=<width>`

#### Client behavior

- rendered through shared poster/image views
- cached with Kingfisher
- 500 MB disk-cache target

#### Status

Integrated

## 6. Local Demo Data Sources

These are not remote integrations today and should be documented that way.

### Auth

- `AuthMockDataSource`
- simulates OTP request and verification

### Profiles

- `ProfileMockDataSource`
- owns create/edit/list profile demo state

### Profile Home Personalization

- `ProfileHubRepositoryImpl`
- derives continue watching, favorites, and recommendations from reusable demo rail composition

### Session State

- `DemoSessionStore`
- owns current cohort and AI voice-search preference

## 7. Integration Status by Surface

### Storefront

- tabs: integrated
- sections: integrated
- lazy loading: integrated
- final content-to-layout configuration tuning: pending polish

### Search

- text search: integrated
- voice search backend: mocked
- popular search entry state: local/demo composed

### Detail

- metadata: integrated
- recommendations: integrated with fallback
- favorite/resume production state: pending future service hookup

### Profile

- profile home content: mock-composed
- profile CRUD persistence: local/mock
- profile-driven cohort updates: integrated at app-session layer

### Settings

- navigable UI: implemented
- business/legal/account backend actions: mostly mocked

## 8. Known Gaps

- no production auth token lifecycle yet
- no production profile service integration yet
- favorites and continue-watching are not yet backed by final live user APIs
- voice-search semantic execution is mocked
- some business pages remain UI-complete but backend-incomplete

## 9. Suggested Next API Steps

1. Replace auth mock with real OTP/session service.
2. Replace profile mock store with real profile list/create/update/delete endpoints.
3. Introduce real user-state APIs for favorites and continue watching.
4. Finalize cohort-to-`pf` contract with Sony business rules.
5. Add structured logging around storefront source URL resolution and recommendation fallback behavior.
