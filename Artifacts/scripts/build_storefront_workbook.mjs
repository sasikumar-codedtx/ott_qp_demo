import fs from "node:fs/promises";
import path from "node:path";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const [csvPathArg, outputPathArg] = process.argv.slice(2);
if (!csvPathArg || !outputPathArg) {
  throw new Error("Usage: node build_storefront_workbook.mjs <input.csv> <output.xlsx>");
}

const csvPath = path.resolve(csvPathArg);
const outputPath = path.resolve(outputPathArg);
const csvText = await fs.readFile(csvPath, "utf8");
const rowCount = csvText.trimEnd().split(/\r?\n/).length;
const colCount = csvText.slice(0, csvText.indexOf("\n")).split(",").length;

const workbook = await Workbook.fromCSV(csvText, { sheetName: "Storefront Data" });
const sheet = workbook.worksheets.getItem("Storefront Data");
sheet.showGridLines = false;
sheet.freezePanes.freezeRows(1);

const usedRange = sheet.getRangeByIndexes(0, 0, rowCount, colCount);
usedRange.format.font.name = "Aptos";
usedRange.format.font.size = 10;
usedRange.format.wrapText = false;

const header = sheet.getRangeByIndexes(0, 0, 1, colCount);
header.format.fill.color = "#111827";
header.format.font.color = "#FFFFFF";
header.format.font.bold = true;
header.format.borders = { preset: "outside", style: "thin", color: "#111827" };

const dataRange = sheet.getRangeByIndexes(1, 0, Math.max(rowCount - 1, 1), colCount);
dataRange.format.borders = { preset: "inside", style: "thin", color: "#E5E7EB" };

usedRange.format.autofitColumns();
usedRange.format.autofitRows();

const wideColumns = new Set([
  "section_source_q",
  "section_source_cu",
  "card_raw_keys",
  "card_title",
  "section_title",
]);
const headers = csvText.slice(0, csvText.indexOf("\n")).split(",");
headers.forEach((name, index) => {
  const column = sheet.getRangeByIndexes(0, index, rowCount, 1);
  if (wideColumns.has(name)) {
    column.format.columnWidthPx = name === "section_source_cu" ? 360 : 240;
  } else if (name.includes("id") || name.includes("urn")) {
    column.format.columnWidthPx = 190;
  } else {
    column.format.columnWidthPx = 120;
  }
});

const inspect = await workbook.inspect({
  kind: "table",
  sheetId: "Storefront Data",
  range: "A1:AH8",
  tableMaxRows: 8,
  tableMaxCols: 34,
  maxChars: 5000,
});
console.log(inspect.ndjson);

const errors = await workbook.inspect({
  kind: "match",
  searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A",
  options: { useRegex: true, maxResults: 100 },
  summary: "formula error scan",
});
console.log(errors.ndjson);

const preview = await workbook.render({
  sheetName: "Storefront Data",
  range: "A1:AH35",
  scale: 1,
  format: "png",
});
const previewPath = outputPath.replace(/\.xlsx$/i, "_preview.png");
await fs.writeFile(previewPath, new Uint8Array(await preview.arrayBuffer()));

await fs.mkdir(path.dirname(outputPath), { recursive: true });
const output = await SpreadsheetFile.exportXlsx(workbook);
await output.save(outputPath);
console.log(JSON.stringify({ outputPath, previewPath, rowCount, colCount }, null, 2));
