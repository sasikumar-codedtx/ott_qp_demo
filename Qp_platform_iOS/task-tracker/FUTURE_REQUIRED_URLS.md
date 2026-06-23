# Future Required URLs

Last updated: 2026-06-22

## Provided now

- `Kids storefront`
Current behavior:
No dedicated confirmed URL is wired yet. App currently falls back to entertainment storefront if kids storefront data is empty or unavailable.

- `Micro Drama storefront`
Current placeholder:
`https://storefront.cms-qp.opt.quickplay.com/storefront/list?reg=all&dt=androidmobile&client=sony-sony-androidmobile&pf=regular&chrt=Sony1`
Current usage:
Placeholder only. Currently used by the bottom `New & Hot` demo surface, which prefers the `Micro Drama` tab when that tab exists in the returned storefront.

- `New & Hot storefront`
Current placeholder:
`https://storefront.cms-qp.opt.quickplay.com/storefront/list?reg=all&dt=androidmobile&client=sony-sony-androidmobile&pf=regular&chrt=Sony1`
Current usage:
Same placeholder is currently reused for the dedicated `New & Hot` surface in this demo.

## Needed from product/backend

- `Kids storefront URL`
Purpose:
Dedicated storefront source for kids profiles instead of current fallback behavior.

- `Micro Drama storefront URL`
Purpose:
Dedicated storefront source for the Micro Drama bottom tab.

- `New & Hot storefront URL`
Purpose:
Dedicated storefront source for the New & Hot bottom tab.

- `Shorts feed API`
Purpose:
Replace current hardcoded shorts repository with backend-driven vertical feed content.
