#!/usr/bin/env python3
import csv
import json
import sys
import time
from pathlib import Path
from urllib.parse import urlencode
from urllib.request import Request, urlopen


OUTPUT_DIR = Path("Artifacts/exports")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

CATALOG_BASE = "https://catalog-service.cms-qp.opt.quickplay.com/catalog/storefront/landingscreen"
CLIENT = "sony-sony-androidmobile"
DEVICE_TYPE = "androidmobile"
CHRT = "Sony1"
PAGE_SIZE = 10
MAX_PAGES_PER_TAB = 80

STOREFRONTS = [
    ("Entertainment", "regular"),
    ("Sports", "kids"),
    ("Reality", "Preschool"),
]

FIELDNAMES = [
    "storefront_name",
    "pf",
    "storefront_id",
    "tab_index",
    "tab_id",
    "tab_title",
    "page_number",
    "section_index",
    "section_id",
    "section_title",
    "section_ty",
    "section_lo",
    "section_iar",
    "section_bg_style_ia",
    "section_bg_style_color",
    "section_source_type",
    "section_source_count",
    "section_source_q",
    "section_source_cu",
    "card_index",
    "card_id",
    "card_title",
    "card_ty",
    "card_cty",
    "card_cust_sc",
    "card_cust_id",
    "series_id",
    "stl_id",
    "setl_id",
    "ex_stl_id",
    "card_ia",
    "card_nu",
    "card_urn",
    "card_raw_keys",
]


def fetch_json(url: str) -> dict:
    request = Request(
        url,
        headers={
            "Accept": "application/json",
            "Origin": "https://www.sonyliv.com",
            "Referer": "https://www.sonyliv.com/",
            "User-Agent": "Mozilla/5.0",
        },
    )
    with urlopen(request, timeout=30) as response:
        return json.loads(response.read().decode("utf-8"))


def landing_url(pf: str, storefront_id: str | None = None, tab_id: str | None = None, page_number: int = 1) -> str:
    params = {
        "ipr": "true",
        "ivg": "false",
        "sfInfo": "true",
        "reg": "in",
        "dt": DEVICE_TYPE,
        "cPageNumber": str(page_number),
        "cPageSize": str(PAGE_SIZE),
        "client": CLIENT,
        "pf": pf,
        "chrt": CHRT,
    }
    if storefront_id:
        params["sfid"] = storefront_id
    if tab_id:
        params["tid"] = tab_id
    return f"{CATALOG_BASE}?{urlencode(params)}"


def preferred_text(localized) -> str:
    if isinstance(localized, list):
        for item in localized:
            if isinstance(item, dict) and item.get("lang") == "en" and item.get("n") is not None:
                value = item.get("n")
                return ", ".join(value) if isinstance(value, list) else str(value)
        if localized and isinstance(localized[0], dict) and localized[0].get("n") is not None:
            value = localized[0].get("n")
            return ", ".join(value) if isinstance(value, list) else str(value)
    if isinstance(localized, str):
        return localized
    return ""


def bg_style_ia(bg_style) -> str:
    if not isinstance(bg_style, dict):
        return ""
    value = bg_style.get("ia")
    if isinstance(value, list):
        return ",".join(str(item) for item in value)
    return str(value) if value is not None else ""


def bg_style_color(bg_style) -> str:
    if not isinstance(bg_style, dict):
        return ""
    for key in ("color", "colour", "hex", "bg", "bg_color", "background_color", "background_colour"):
        value = bg_style.get(key)
        if isinstance(value, dict):
            value = value.get("value") or value.get("v") or value.get("hex")
        if value:
            return str(value)
    return ""


def source_value(sources, key: str) -> str:
    if not isinstance(sources, list):
        return ""
    values = []
    for source in sources:
        if isinstance(source, dict) and source.get(key):
            values.append(str(source.get(key)))
    return " | ".join(values)


def card_title(card: dict) -> str:
    return preferred_text(card.get("lon") or card.get("lodn") or card.get("lostl"))


def computed_series_id(card: dict) -> str:
    for key in ("stl_id", "setl_id", "ex_stl_id", "series_id"):
        if card.get(key):
            return str(card.get(key))
    cty = str(card.get("cty") or "").lower()
    if "series" in cty:
        return str(card.get("id") or "")
    return ""


def rows_for_page(storefront_name: str, pf: str, storefront_id: str, tab_index: int, tab: dict, page_number: int, page: dict) -> list[dict]:
    rows = []
    sections = tab.get("c") or []
    for section_index, section in enumerate(sections):
        sources = section.get("i") or []
        cards = section.get("cd") or []
        base = {
            "storefront_name": storefront_name,
            "pf": pf,
            "storefront_id": storefront_id,
            "tab_index": tab_index,
            "tab_id": tab.get("id", ""),
            "tab_title": preferred_text(tab.get("lon")) or tab.get("title", ""),
            "page_number": page_number,
            "section_index": section_index,
            "section_id": section.get("id", ""),
            "section_title": preferred_text(section.get("lon")),
            "section_ty": section.get("ty", ""),
            "section_lo": section.get("lo", ""),
            "section_iar": section.get("iar", ""),
            "section_bg_style_ia": bg_style_ia(section.get("bg_style")),
            "section_bg_style_color": bg_style_color(section.get("bg_style")),
            "section_source_type": source_value(sources, "type"),
            "section_source_count": source_value(sources, "count"),
            "section_source_q": source_value(sources, "q"),
            "section_source_cu": source_value(sources, "cu"),
        }
        if not cards:
            row = dict(base)
            for field in FIELDNAMES:
                row.setdefault(field, "")
            rows.append(row)
            continue
        for card_index, card in enumerate(cards):
            row = dict(base)
            row.update(
                {
                    "card_index": card_index,
                    "card_id": card.get("id", ""),
                    "card_title": card_title(card),
                    "card_ty": card.get("ty", ""),
                    "card_cty": card.get("cty", ""),
                    "card_cust_sc": card.get("cust_sc", ""),
                    "card_cust_id": card.get("cust_id", ""),
                    "series_id": computed_series_id(card),
                    "stl_id": card.get("stl_id", ""),
                    "setl_id": card.get("setl_id", ""),
                    "ex_stl_id": card.get("ex_stl_id", ""),
                    "card_ia": ",".join(card.get("ia") or []),
                    "card_nu": card.get("nu", ""),
                    "card_urn": card.get("urn", ""),
                    "card_raw_keys": ",".join(sorted(card.keys())),
                }
            )
            for field in FIELDNAMES:
                row.setdefault(field, "")
            rows.append(row)
    return rows


def first_storefront(response: dict) -> dict | None:
    data = response.get("data")
    if isinstance(data, list):
        return data[0] if data else None
    if isinstance(data, dict):
        return data
    return None


def tab_has_content(tab: dict) -> bool:
    sections = tab.get("c") or []
    return any((section.get("cd") or section.get("i")) for section in sections)


def main() -> int:
    timestamp = time.strftime("%Y%m%d_%H%M%S")
    csv_path = OUTPUT_DIR / f"storefront_full_export_{timestamp}.csv"
    summary_path = OUTPUT_DIR / f"storefront_full_export_{timestamp}_summary.json"

    all_rows = []
    summary = []

    for storefront_name, pf in STOREFRONTS:
        first_url = landing_url(pf)
        first_response = fetch_json(first_url)
        storefront = first_storefront(first_response)
        if not storefront:
            summary.append({"storefront_name": storefront_name, "pf": pf, "error": "No storefront data"})
            continue

        storefront_id = storefront.get("id") or ""
        tabs = storefront.get("t") or []
        storefront_summary = {
            "storefront_name": storefront_name,
            "pf": pf,
            "storefront_id": storefront_id,
            "tabs": [],
        }

        for tab_index, tab_manifest in enumerate(tabs):
            tab_id = tab_manifest.get("id") or ""
            tab_title = preferred_text(tab_manifest.get("lon")) or tab_manifest.get("title", "")
            tab_row_count = 0
            section_count = 0
            card_count = 0

            for page_number in range(1, MAX_PAGES_PER_TAB + 1):
                page_url = landing_url(pf, storefront_id=storefront_id, tab_id=tab_id, page_number=page_number)
                page_response = fetch_json(page_url)
                page_storefront = first_storefront(page_response)
                page_tabs = page_storefront.get("t") if page_storefront else []
                selected_tab = None
                for candidate in page_tabs or []:
                    if candidate.get("id") == tab_id:
                        selected_tab = candidate
                        break
                if selected_tab is None and page_tabs:
                    selected_tab = page_tabs[0]

                if not selected_tab or not tab_has_content(selected_tab):
                    break

                page_rows = rows_for_page(storefront_name, pf, storefront_id, tab_index, selected_tab, page_number, page_response)
                if not page_rows:
                    break

                all_rows.extend(page_rows)
                tab_row_count += len(page_rows)
                sections = selected_tab.get("c") or []
                section_count += len(sections)
                card_count += sum(len(section.get("cd") or []) for section in sections)

                if sum(len(section.get("cd") or []) for section in sections) == 0:
                    break

            storefront_summary["tabs"].append(
                {
                    "tab_index": tab_index,
                    "tab_id": tab_id,
                    "tab_title": tab_title,
                    "rows": tab_row_count,
                    "sections": section_count,
                    "cards": card_count,
                }
            )

        summary.append(storefront_summary)

    with csv_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=FIELDNAMES)
        writer.writeheader()
        writer.writerows(all_rows)

    summary_path.write_text(json.dumps(summary, indent=2), encoding="utf-8")

    print(json.dumps({"csv": str(csv_path), "summary": str(summary_path), "rows": len(all_rows), "summary_data": summary}, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
