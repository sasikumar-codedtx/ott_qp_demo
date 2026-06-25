import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const storefronts = [
  { storefront: "Entertainment", pf: "regular" },
  { storefront: "Sports", pf: "kids" },
  { storefront: "Reality", pf: "Preschool" },
];

const pageSize = 10;
const baseURL = "https://catalog-service.cms-qp.opt.quickplay.com/catalog/storefront/landingscreen";
const outputCSV = path.join(__dirname, "storefront_content_audit.csv");
const outputSummary = path.join(__dirname, "storefront_content_audit_summary.json");
const outputXLSX = path.join(__dirname, "storefront_content_audit.xlsx");

const headers = [
  "storefront",
  "pf",
  "storefront_id",
  "tab",
  "tab_id",
  "page",
  "section_index",
  "section",
  "section_id",
  "section_ty",
  "section_lo",
  "iar",
  "bg_style",
  "card_source",
  "card_index",
  "card",
  "card_id",
  "card_ty",
  "cty",
  "cust_sc",
  "source_url",
  "request_url",
];

function landingURL({ pf, storefrontID, tabID, pageNumber }) {
  const url = new URL(baseURL);
  url.searchParams.set("ipr", "true");
  url.searchParams.set("ivg", "false");
  url.searchParams.set("sfInfo", "true");
  url.searchParams.set("reg", "in");
  url.searchParams.set("dt", "androidmobile");
  url.searchParams.set("client", "sony-sony-androidmobile");
  url.searchParams.set("chrt", "Sony1");
  url.searchParams.set("cPageSize", String(pageSize));
  url.searchParams.set("pf", pf);
  url.searchParams.set("cPageNumber", String(pageNumber));
  if (storefrontID) url.searchParams.set("sfid", storefrontID);
  if (tabID) url.searchParams.set("tid", tabID);
  return url;
}

async function fetchJSON(url) {
  const response = await fetch(url, {
    headers: {
      Accept: "*/*",
      Origin: "https://www.sonyliv.com",
      Referer: "https://www.sonyliv.com/",
      "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.4 Safari/605.1.15",
    },
  });
  if (!response.ok) {
    throw new Error(`HTTP ${response.status} for ${url}`);
  }
  return response.json();
}

function array(value) {
  return Array.isArray(value) ? value : value ? [value] : [];
}

function preferredText(lon) {
  const items = array(lon);
  return (
    items.find((item) => item?.lang === "en")?.n ??
    items.find((item) => typeof item?.n === "string")?.n ??
    ""
  );
}

function firstData(json) {
  return array(json?.data)[0] ?? {};
}

function tabList(json) {
  return array(firstData(json)?.t);
}

function sectionsFor(json, tabID) {
  const tabs = tabList(json);
  const target = tabs.find((tab) => tab?.id === tabID) ?? tabs[0] ?? {};
  return array(target?.c);
}

function sectionTitle(section) {
  return preferredText(section?.lon) || section?.n || section?.title || "";
}

function cardTitle(card) {
  return preferredText(card?.lon) || card?.n || card?.title || "";
}

function stringifyField(value) {
  if (value == null) return "";
  if (typeof value === "string") return value;
  if (typeof value === "number" || typeof value === "boolean") return String(value);
  return JSON.stringify(value);
}

function csvEscape(value) {
  const text = stringifyField(value);
  if (/[",\n\r]/.test(text)) {
    return `"${text.replaceAll('"', '""')}"`;
  }
  return text;
}

function sectionBackgroundStyle(section) {
  return section?.bg_style ?? section?.backgroundStyle ?? "";
}

function sectionIAR(section) {
  const diar = array(section?.diar);
  return diar.find((item) => item?.dt === "mobile")?.iar ?? diar[0]?.iar ?? section?.iar ?? "";
}

function directCards(section) {
  return array(section?.cd);
}

function contentSources(section) {
  return array(section?.i);
}

function rowsFromPage({ meta, json, tab, pageNumber, requestURL }) {
  const rows = [];
  const sections = sectionsFor(json, tab.id);

  sections.forEach((section, sectionOffset) => {
    const sectionIndex = sectionOffset + 1;
    const cards = directCards(section);
    const sources = contentSources(section);
    const bgStyle = sectionBackgroundStyle(section);
    const base = {
      storefront: meta.storefront,
      pf: meta.pf,
      storefront_id: meta.storefrontID,
      tab: meta.tabName,
      tab_id: tab.id ?? "",
      page: pageNumber,
      section_index: sectionIndex,
      section: sectionTitle(section),
      section_id: section?.id ?? "",
      section_ty: section?.ty ?? "",
      section_lo: section?.lo ?? "",
      iar: sectionIAR(section),
      bg_style: bgStyle,
      request_url: requestURL,
    };

    if (cards.length > 0) {
      cards.forEach((card, cardOffset) => {
        rows.push({
          ...base,
          card_source: "direct_cd",
          card_index: cardOffset + 1,
          card: cardTitle(card),
          card_id: card?.id ?? "",
          card_ty: card?.ty ?? "",
          cty: card?.cty ?? "",
          cust_sc: card?.cust_sc ?? "",
          source_url: "",
        });
      });
      return;
    }

    sources.forEach((source, sourceOffset) => {
      rows.push({
        ...base,
        card_source: source?.ty ?? source?.type ?? "source",
        card_index: sourceOffset + 1,
        card: "",
        card_id: "",
        card_ty: "",
        cty: "",
        cust_sc: "",
        source_url: source?.cu ?? "",
      });
    });
  });

  return { rows, sections };
}

async function auditStorefront(config) {
  const initialURL = landingURL({ pf: config.pf, pageNumber: 1 });
  const initialJSON = await fetchJSON(initialURL);
  const storefrontID = firstData(initialJSON)?.id ?? "";
  const tabs = tabList(initialJSON);
  const tabsSummary = [];
  const rows = [];

  for (let tabIndex = 0; tabIndex < tabs.length; tabIndex += 1) {
    const tab = tabs[tabIndex];
    const tabName = preferredText(tab?.lon) || tab?.n || `Tab ${tabIndex + 1}`;
    const tabSummary = {
      tab: tabName,
      tab_id: tab?.id ?? "",
      pages: [],
      sections: 0,
      rows: 0,
    };

    for (let pageNumber = 1; pageNumber < 100; pageNumber += 1) {
      const requestURL =
        pageNumber === 1 && tabIndex === 0
          ? initialURL
          : landingURL({
              pf: config.pf,
              storefrontID,
              tabID: tab?.id,
              pageNumber,
            });

      let pageJSON = initialJSON;
      let error = null;
      if (!(pageNumber === 1 && tabIndex === 0)) {
        try {
          pageJSON = await fetchJSON(requestURL);
        } catch (fetchError) {
          error = fetchError.message;
          pageJSON = {};
        }
      }

      const result = rowsFromPage({
        meta: {
          storefront: config.storefront,
          pf: config.pf,
          storefrontID,
          tabName,
        },
        json: pageJSON,
        tab,
        pageNumber,
        requestURL: requestURL.toString(),
      });

      rows.push(...result.rows);
      tabSummary.pages.push({
        page: pageNumber,
        sections: result.sections.length,
        rows: result.rows.length,
        error,
      });
      tabSummary.sections += result.sections.length;
      tabSummary.rows += result.rows.length;

      if (error || result.sections.length === 0 || result.rows.length === 0) {
        break;
      }
    }

    tabsSummary.push(tabSummary);
  }

  return {
    rows,
    summary: {
      storefront: config.storefront,
      pf: config.pf,
      storefront_id: storefrontID,
      initial_url: initialURL.toString(),
      tabs: tabsSummary,
    },
  };
}

async function writeCSV(rows) {
  const lines = [
    headers.join(","),
    ...rows.map((row) => headers.map((header) => csvEscape(row[header])).join(",")),
  ];
  await fs.writeFile(outputCSV, `${lines.join("\n")}\n`, "utf8");
}

async function writeWorkbook(csvRows, summary) {
  const workbook = Workbook.create();
  const dataSheet = workbook.worksheets.add("Storefront Data");
  const summarySheet = workbook.worksheets.add("Summary");
  dataSheet.showGridLines = false;
  summarySheet.showGridLines = false;

  const data = [headers, ...csvRows.map((row) => headers.map((header) => row[header] ?? ""))];
  dataSheet.getRangeByIndexes(0, 0, data.length, headers.length).values = data;
  dataSheet.freezePanes.freezeRows(1);

  const used = dataSheet.getRangeByIndexes(0, 0, data.length, headers.length);
  used.format.font.name = "Aptos";
  used.format.font.size = 11;
  used.format.wrapText = false;
  dataSheet.getRangeByIndexes(0, 0, 1, headers.length).format.fill.color = "#12233F";
  dataSheet.getRangeByIndexes(0, 0, 1, headers.length).format.font.color = "#FFFFFF";
  dataSheet.getRangeByIndexes(0, 0, 1, headers.length).format.font.bold = true;
  used.format.borders = { preset: "insideHorizontal", style: "thin", color: "#E6EAF0" };
  dataSheet.getRangeByIndexes(0, 0, data.length, headers.length).format.autofitColumns();
  dataSheet.getRange("A:A").format.columnWidth = 18;
  dataSheet.getRange("H:H").format.columnWidth = 28;
  dataSheet.getRange("P:P").format.columnWidth = 32;
  dataSheet.getRange("U:V").format.columnWidth = 55;

  const summaryHeaders = [
    "storefront",
    "pf",
    "storefront_id",
    "tab",
    "tab_id",
    "pages",
    "sections",
    "rows",
  ];
  const summaryRows = summary.flatMap((storefront) =>
    storefront.tabs.map((tab) => [
      storefront.storefront,
      storefront.pf,
      storefront.storefront_id,
      tab.tab,
      tab.tab_id,
      tab.pages.length,
      tab.sections,
      tab.rows,
    ])
  );
  const summaryData = [summaryHeaders, ...summaryRows];
  summarySheet.getRangeByIndexes(0, 0, summaryData.length, summaryHeaders.length).values = summaryData;
  summarySheet.freezePanes.freezeRows(1);
  const summaryRange = summarySheet.getRangeByIndexes(0, 0, summaryData.length, summaryHeaders.length);
  summaryRange.format.font.name = "Aptos";
  summaryRange.format.font.size = 11;
  summarySheet.getRangeByIndexes(0, 0, 1, summaryHeaders.length).format.fill.color = "#12233F";
  summarySheet.getRangeByIndexes(0, 0, 1, summaryHeaders.length).format.font.color = "#FFFFFF";
  summarySheet.getRangeByIndexes(0, 0, 1, summaryHeaders.length).format.font.bold = true;
  summaryRange.format.borders = { preset: "insideHorizontal", style: "thin", color: "#E6EAF0" };
  summaryRange.format.autofitColumns();

  const errors = await workbook.inspect({
    kind: "match",
    searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A",
    options: { useRegex: true, maxResults: 50 },
    maxChars: 2000,
  });
  console.log(errors.ndjson);

  const preview = await workbook.render({
    sheetName: "Summary",
    range: "A1:H25",
    scale: 1,
    format: "png",
  });
  await fs.writeFile(
    path.join(__dirname, "storefront_content_audit_preview.png"),
    new Uint8Array(await preview.arrayBuffer())
  );

  const output = await SpreadsheetFile.exportXlsx(workbook);
  await output.save(outputXLSX);
}

const allRows = [];
const summary = [];

for (const config of storefronts) {
  console.log(`Fetching ${config.storefront} (${config.pf})`);
  const result = await auditStorefront(config);
  allRows.push(...result.rows);
  summary.push(result.summary);
}

await writeCSV(allRows);
await fs.writeFile(outputSummary, JSON.stringify({ generated_at: new Date().toISOString(), summary }, null, 2));
await writeWorkbook(allRows, summary);

console.log(`Rows: ${allRows.length}`);
console.log(outputCSV);
console.log(outputXLSX);
