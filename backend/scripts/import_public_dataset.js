import fs from "fs";
import path from "path";
import crypto from "crypto";

import axios from "axios";

const DATASET_URL = process.argv[2] || process.env.PUBLIC_DATASET_URL;
const OUTPUT_PATH = process.env.PUBLIC_IMPORT_OUTPUT_PATH || "./data/external/public_dataset_raw.json";
const TIMEOUT_MS = Number(process.env.PUBLIC_IMPORT_TIMEOUT_MS || 20000);

if (!DATASET_URL) {
  console.error("Usage: npm run etl:import:url -- <dataset-url>");
  process.exit(1);
}

const ensureDir = (filePath) => {
  const dir = path.dirname(filePath);
  fs.mkdirSync(dir, { recursive: true });
};

const asArray = (payload) => {
  if (Array.isArray(payload)) return payload;
  if (Array.isArray(payload?.data)) return payload.data;
  if (Array.isArray(payload?.items)) return payload.items;
  if (Array.isArray(payload?.records)) return payload.records;
  if (Array.isArray(payload?.result?.records)) return payload.result.records;
  return [];
};

const pick = (obj, keys) => {
  for (const key of keys) {
    if (obj[key] != null && String(obj[key]).trim() !== "") return obj[key];
  }
  return null;
};

const toStringArray = (value) => {
  if (Array.isArray(value)) return value.map((v) => String(v).trim()).filter(Boolean);
  if (typeof value === "string") {
    return value
      .split(/[,;|]/)
      .map((v) => v.trim())
      .filter(Boolean);
  }
  return [];
};

const normalizeRawRecord = (record, index) => {
  const title = String(
    pick(record, ["title", "name", "scheme_name", "scheme", "schemeTitle", "program_name"]) ||
      ""
  ).trim();
  const description = String(
    pick(record, [
      "description",
      "summary",
      "details",
      "objective",
      "shortDescription",
      "scheme_description"
    ]) || ""
  ).trim();

  if (!title || !description) return null;

  const category = String(
    pick(record, ["category", "sector", "theme", "department_category"]) || "Uncategorized"
  ).trim();

  const ministry = String(
    pick(record, ["ministry", "department", "agency", "implementing_agency"]) || ""
  ).trim();

  const state = String(pick(record, ["state", "states", "location", "coverage"]) || "All India").trim();

  const applicationUrl = String(
    pick(record, ["application_url", "apply_url", "link", "url", "website"]) || ""
  ).trim();

  const officialSource = String(
    pick(record, ["official_source", "source", "source_url", "portal_url"]) || DATASET_URL
  ).trim();

  const occupations = toStringArray(
    pick(record, ["target_beneficiaries", "beneficiaries", "occupation", "occupations"])
  );

  const tags = toStringArray(pick(record, ["tags", "keywords", "topics"]));
  const docs = toStringArray(pick(record, ["documents", "required_documents"]));

  const rawId = String(
    pick(record, ["id", "scheme_id", "code", "slug"]) ||
      `public-${crypto.createHash("md5").update(`${title}|${index}`).digest("hex")}`
  ).trim();

  return {
    id: rawId,
    title: { en: title, ta: "" },
    shortDescription: { en: description, ta: "" },
    category,
    ministry: ministry || undefined,
    targetBeneficiaries: occupations,
    tags,
    requiredDocuments: docs,
    eligibility: {
      states: [state]
    },
    applicationUrl: applicationUrl || undefined,
    officialSource: officialSource || undefined,
    source: "public_dataset"
  };
};

const run = async () => {
  const response = await axios.get(DATASET_URL, {
    timeout: TIMEOUT_MS,
    headers: {
      Accept: "application/json,text/plain,*/*",
      "User-Agent": "SchemeFinderBot/1.0"
    }
  });

  const raw = response.data;
  const rows = asArray(raw);

  if (!rows.length) {
    throw new Error("Unsupported dataset format: expected records array in payload");
  }

  const normalized = rows
    .map((item, index) => normalizeRawRecord(item, index))
    .filter((item) => item !== null);

  const outputPath = path.resolve(process.cwd(), OUTPUT_PATH);
  ensureDir(outputPath);
  fs.writeFileSync(outputPath, JSON.stringify(normalized, null, 2));

  console.log(`[import_public_dataset] source: ${DATASET_URL}`);
  console.log(`[import_public_dataset] output: ${outputPath}`);
  console.log(`[import_public_dataset] records: ${normalized.length}`);
};

run();
