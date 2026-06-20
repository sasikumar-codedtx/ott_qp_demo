# API Integration

## Providers

Current implementation uses Aha CDN endpoints for:
- storefront
- search
- content detail
- recommendations

Authenticated Aha endpoints are also used for:
- profile continue watching via bookmark list
- profile favorites via favorite list
- profile recommendations via the same recommendation service used by detail rails

## Header Defaults

- `Origin: https://www.aha.video`
- `Referer: https://www.aha.video/`
- `User-Agent: Mozilla/5.0`

## Query Defaults

Storefront and detail use:
- `reg=in`
- `acl=te,ta`
- `dt=web`
- `ipr=true`
- `itvod=true`
- `pf=profile`

Search uses:
- `mode=detail`
- `st=published`
- `pageNumber=1`
- `pageSize=50`
- `pl=ta`

Profile rail requests use:
- `contentInfo=true`
- `pageSize=20`
- `reg=in`
- `acl=te,ta`
- `dt=web`
- `ipr=true`
- `itvod=true`
- `pf=profile`
- `pl=ta`

## Authenticated Session Notes

- Temporary bearer and `X-Authorization` values are centralized in `Core/Config/AppEnvironment.swift`.
- This is a staging step only; once login is live they should move behind a secure session store.
- Evergent account-profile endpoints were rejected with the provided token, so the subscription summary remains config-backed for now.

## Future Work

- wire authenticated favorite state
- wire bookmark/resume state
- replace hardcoded authenticated session values after login integration
- move config values behind environments if backend changes
