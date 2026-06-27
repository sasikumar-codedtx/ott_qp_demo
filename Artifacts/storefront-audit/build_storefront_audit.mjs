import fs from "node:fs/promises";
import path from "node:path";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const outputDir = path.resolve("Artifacts/storefront-audit/output");
const catalogBaseURL = "https://catalog-service-cdn.cms-qp.opt.quickplay.com";
const dt = "androidmobile";
const client = "sony-sony-androidmobile";
const pf = "regular";
const pageSize = 5;

const storefrontPolicies = [
  { storefrontName: "Entertainment", chrt: "entertainment" },
  { storefrontName: "Reality + Entertainment", chrt: "sony2" },
  { storefrontName: "Reality", chrt: "reality" },
  { storefrontName: "Reality + Sports", chrt: "sony3" },
  { storefrontName: "Sports + Entertainment", chrt: "sony1" },
  { storefrontName: "Sports", chrt: "sports" },
];

const contentHeaders = [
  "storefront_name",
  "pf",
  "chrt",
  "storefront_id",
  "storefront_title",
  "tab_index",
  "tab_id",
  "tab_name",
  "page_number",
  "section_index",
  "section_id",
  "section_title",
  "section_lo",
  "section_ty",
  "section_iar",
  "section_bg_style_ia",
  "section_bg_style_iar",
  "section_bg_style_color",
  "card_index",
  "card_id",
  "card_title",
  "card_ty",
  "card_cty",
  "card_cust_sc",
  "card_cust_id",
  "stl_id",
  "setl_id",
  "series_id_resolved",
  "card_nu",
  "card_urn",
  "card_ia",
  "card_year",
  "card_genres",
  "card_rating",
  "card_preview_url",
  "source_url",
];

const sectionHeaders = [
  "storefront_name",
  "pf",
  "chrt",
  "storefront_id",
  "tab_id",
  "tab_name",
  "page_number",
  "section_index",
  "section_id",
  "section_title",
  "section_lo",
  "section_ty",
  "section_iar",
  "section_bg_style_ia",
  "section_bg_style_iar",
  "section_bg_style_color",
  "card_count",
  "source_url",
];

const tabHeaders = [
  "storefront_name",
  "pf",
  "chrt",
  "storefront_id",
  "storefront_title",
  "tab_index",
  "tab_id",
  "tab_name",
  "pages_fetched",
  "section_count",
  "content_count",
];

function pickName(localized) {
  if (!Array.isArray(localized) || localized.length === 0) return "";
  return localized.find((item) => item?.lang === "en")?.n ?? localized[0]?.n ?? "";
}

function pickList(localizedList) {
  if (!Array.isArray(localizedList) || localizedList.length === 0) return "";
  const value = localizedList.find((item) => item?.lang === "en")?.n ?? localizedList[0]?.n ?? [];
  return Array.isArray(value) ? value.join(", ") : "";
}

function bgStyleValue(bgStyle, key) {
  if (!bgStyle || typeof bgStyle !== "object") return "";
  const value = bgStyle[key];
  if (Array.isArray(value)) return value.join(", ");
  return value ?? "";
}

function sectionType(container) {
  return container?.ty ?? container?.src_ty ?? container?.srcType ?? "";
}

function cardYear(card) {
  const value = card?.rdt ?? card?.yearDate ?? "";
  return typeof value === "string" ? value.slice(0, 4) : "";
}

function resolvedSeriesID(card) {
  return [card?.stl_id, card?.setl_id, card?.id].find((value) => typeof value === "string" && value.trim().length > 0) ?? "";
}

function makeLandingURL(policy) {
  const url = new URL(`${catalogBaseURL}/catalog/storefront/landingscreen`);
  url.searchParams.set("ipr", "true");
  url.searchParams.set("ivg", "false");
  url.searchParams.set("sfInfo", "true");
  url.searchParams.set("reg", "in");
  url.searchParams.set("dt", dt);
  url.searchParams.set("cPageNumber", "1");
  url.searchParams.set("cPageSize", String(pageSize));
  url.searchParams.set("client", client);
  url.searchParams.set("pf", pf);
  url.searchParams.set("chrt", policy.chrt);
  return url;
}

function makeContainersURL({ storefrontID, tabID, policy, pageNumber }) {
  const url = new URL(`${catalogBaseURL}/catalog/storefront/${storefrontID}/${tabID}/containers`);
  url.searchParams.set("reg", "IN");
  url.searchParams.set("dt", dt);
  url.searchParams.set("client", client);
  url.searchParams.set("pf", pf);
  url.searchParams.set("chrt", policy.chrt);
  url.searchParams.set("policy_evaluate", "false");
  url.searchParams.set("pageSize", String(pageSize));
  url.searchParams.set("pageNumber", String(pageNumber));
  return url;
}

async function fetchJSON(url) {
  console.log(`[crawl] GET ${url}`);
  const response = await fetch(url, {
    headers: {
      Accept: "*/*",
      Origin: "https://www.sonyliv.com",
      Referer: "https://www.sonyliv.com/",
      "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.4 Safari/605.1.15",
    },
  });
  const text = await response.text();
  if (!response.ok) {
    throw new Error(`HTTP ${response.status} for ${url}\n${text.slice(0, 500)}`);
  }
  return JSON.parse(text);
}

async function crawlPolicy(policy) {
  const landingURL = makeLandingURL(policy);
  const landingJSON = await fetchJSON(landingURL);
  const landingData = Array.isArray(landingJSON.data) ? landingJSON.data[0] : landingJSON.data;
  if (!landingData?.id) {
    return { contentRows: [], sectionRows: [], tabRows: [] };
  }

  const storefrontID = landingData.id;
  const storefrontTitle = pickName(landingData.lon);
  const tabs = Array.isArray(landingData.t) ? landingData.t : [];

  const contentRows = [];
  const sectionRows = [];
  const tabRows = [];

  for (const [tabIndex, tab] of tabs.entries()) {
    const tabID = tab?.id ?? "";
    if (!tabID) continue;

    const tabName = pickName(tab.lon);
    let pageNumber = 1;
    let pagesFetched = 0;
    let tabSectionCount = 0;
    let tabContentCount = 0;

    while (true) {
      const containersURL = makeContainersURL({ storefrontID, tabID, policy, pageNumber });
      const containersJSON = await fetchJSON(containersURL);
      const containers = Array.isArray(containersJSON.data) ? containersJSON.data : [];
      if (containers.length === 0) break;

      pagesFetched += 1;

      for (const [sectionIndex, container] of containers.entries()) {
        const cards = Array.isArray(container.cd) ? container.cd : [];
        tabSectionCount += 1;
        tabContentCount += cards.length;

        const sectionBase = [
          policy.storefrontName,
          pf,
          policy.chrt,
          storefrontID,
          tabID,
          tabName,
          pageNumber,
          sectionIndex + 1,
          container.id ?? "",
          pickName(container.lon),
          container.lo ?? "",
          sectionType(container),
          container.iar ?? "",
          bgStyleValue(container.bg_style, "ia"),
          bgStyleValue(container.bg_style, "iar"),
          bgStyleValue(container.bg_style, "color") || bgStyleValue(container.bg_style, "bg_color"),
          cards.length,
          containersURL.toString(),
        ];
        sectionRows.push(sectionBase);

        for (const [cardIndex, card] of cards.entries()) {
          contentRows.push([
            policy.storefrontName,
            pf,
            policy.chrt,
            storefrontID,
            storefrontTitle,
            tabIndex + 1,
            tabID,
            tabName,
            pageNumber,
            sectionIndex + 1,
            container.id ?? "",
            pickName(container.lon),
            container.lo ?? "",
            sectionType(container),
            container.iar ?? "",
            bgStyleValue(container.bg_style, "ia"),
            bgStyleValue(container.bg_style, "iar"),
            bgStyleValue(container.bg_style, "color") || bgStyleValue(container.bg_style, "bg_color"),
            cardIndex + 1,
            card.id ?? "",
            pickName(card.lon),
            card.ty ?? "",
            card.cty ?? "",
            card.cust_sc ?? "",
            card.cust_id ?? "",
            card.stl_id ?? "",
            card.setl_id ?? "",
            resolvedSeriesID(card),
            card.nu ?? "",
            card.urn ?? "",
            Array.isArray(card.ia) ? card.ia.join(", ") : "",
            cardYear(card),
            pickList(card.log),
            Array.isArray(card.rat) ? card.rat.map((rating) => rating?.v).filter(Boolean).join(", ") : "",
            card.ap_url ?? "",
            containersURL.toString(),
          ]);
        }
      }

      pageNumber += 1;
    }

    tabRows.push([
      policy.storefrontName,
      pf,
      policy.chrt,
      storefrontID,
      storefrontTitle,
      tabIndex + 1,
      tabID,
      tabName,
      pagesFetched,
      tabSectionCount,
      tabContentCount,
    ]);
  }

  return { contentRows, sectionRows, tabRows };
}

function writeSheet(workbook, name, headers, rows) {
  const sheet = workbook.worksheets.add(name);
  sheet.showGridLines = false;
  sheet.getRangeByIndexes(0, 0, 1, headers.length).values = [headers];
  if (rows.length > 0) {
    sheet.getRangeByIndexes(1, 0, rows.length, headers.length).values = rows;
  }
  const usedRows = Math.max(rows.length + 1, 1);
  const usedRange = sheet.getRangeByIndexes(0, 0, usedRows, headers.length);
  usedRange.format.font.name = "Aptos";
  usedRange.format.font.size = 10;
  usedRange.format.wrapText = false;
  sheet.getRangeByIndexes(0, 0, 1, headers.length).format = {
    fill: "#111827",
    font: { bold: true, color: "#FFFFFF" },
  };
  sheet.freezePanes.freezeRows(1);
  usedRange.format.autofitColumns();
  usedRange.format.autofitRows();
  sheet.tables.add(sheet.getRangeByIndexes(0, 0, usedRows, headers.length), true, `${name.replace(/[^A-Za-z0-9]/g, "")}Table`);
  return sheet;
}

async function main() {
  await fs.mkdir(outputDir, { recursive: true });
  const contentRows = [];
  const sectionRows = [];
  const tabRows = [];

  for (const policy of storefrontPolicies) {
    const result = await crawlPolicy(policy);
    contentRows.push(...result.contentRows);
    sectionRows.push(...result.sectionRows);
    tabRows.push(...result.tabRows);
  }

  const workbook = Workbook.create();
  const summaryHeaders = ["metric", "value"];
  const uniqueStorefronts = new Set(contentRows.map((row) => row[0]));
  const uniqueTabs = new Set(contentRows.map((row) => `${row[0]}|${row[7]}`));
  const uniqueSections = new Set(contentRows.map((row) => `${row[0]}|${row[7]}|${row[10]}`));
  const uniqueCards = new Set(contentRows.map((row) => row[19]));
  const summaryRows = [
    ["generated_at", new Date().toISOString()],
    ["storefront_policy_count", storefrontPolicies.length],
    ["storefronts_with_content", uniqueStorefronts.size],
    ["tab_instances_with_content", uniqueTabs.size],
    ["section_instances_with_content", uniqueSections.size],
    ["content_rows", contentRows.length],
    ["unique_card_ids", uniqueCards.size],
    ["catalog_base_url", catalogBaseURL],
  ];

  writeSheet(workbook, "Summary", summaryHeaders, summaryRows);
  writeSheet(workbook, "Tabs", tabHeaders, tabRows);
  writeSheet(workbook, "Sections", sectionHeaders, sectionRows);
  writeSheet(workbook, "Content", contentHeaders, contentRows);

  const jsonPath = path.join(outputDir, "storefront_full_content_audit.json");
  await fs.writeFile(jsonPath, JSON.stringify({ summaryRows, tabRows, sectionRows, contentRows }, null, 2));

  const preview = await workbook.render({ sheetName: "Content", range: "A1:AJ20", scale: 1, format: "png" });
  await fs.writeFile(path.join(outputDir, "content_preview.png"), new Uint8Array(await preview.arrayBuffer()));

  const inspected = await workbook.inspect({
    kind: "table",
    range: "Summary!A1:B8",
    include: "values",
    tableMaxRows: 10,
    tableMaxCols: 3,
  });
  console.log(inspected.ndjson);

  const xlsx = await SpreadsheetFile.exportXlsx(workbook);
  await xlsx.save(path.join(outputDir, "storefront_full_content_audit.xlsx"));
  console.log(`[done] rows=${contentRows.length}`);
}

await main();
