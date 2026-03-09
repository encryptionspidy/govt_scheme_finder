import fs from "fs";
import path from "path";
import crypto from "crypto";
import { spawn } from "child_process";

const DATA_DIR = process.env.ETL_DATA_DIR || "./data/external";
const AGGREGATED_DATA_PATH =
  process.env.ETL_AGGREGATED_PATH || "./data/external/latest_raw_schemes.json";

const ensureDir = (filePath) => {
  const dir = path.dirname(filePath);
  fs.mkdirSync(dir, { recursive: true });
};

const runCommand = (command, args, env = {}) =>
  new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      cwd: process.cwd(),
      env: { ...process.env, ...env },
      stdio: "inherit",
      shell: process.platform === "win32"
    });

    child.on("close", (code) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`Command failed: ${command} ${args.join(" ")} (exit ${code})`));
      }
    });
  });

const readJsonIfExists = (filePath) => {
  if (!fs.existsSync(filePath)) return [];
  const raw = JSON.parse(fs.readFileSync(filePath, "utf8"));
  return Array.isArray(raw) ? raw : [];
};

const dedupeAndMerge = (groups) => {
  const out = [];
  const seen = new Set();

  for (const group of groups) {
    for (const item of group) {
      const id = String(item.id || "").trim();
      if (!id) continue;
      if (seen.has(id)) continue;
      seen.add(id);
      out.push(item);
    }
  }

  return out;
};

const ensureSyntheticId = (items) => {
  return items.map((item, index) => {
    if (item.id) return item;
    const title = item?.title?.en || item?.title || `scheme-${index}`;
    return {
      ...item,
      id: `import-${crypto.createHash("md5").update(`${title}|${index}`).digest("hex")}`
    };
  });
};

const run = async () => {
  const dataDir = path.resolve(process.cwd(), DATA_DIR);
  fs.mkdirSync(dataDir, { recursive: true });

  const crawlerOutputPath = path.resolve(dataDir, "myscheme_raw.json");
  const importOutputPath = path.resolve(dataDir, "public_dataset_raw.json");
  const aggregatePath = path.resolve(process.cwd(), AGGREGATED_DATA_PATH);

  console.log("[etl:update] Step 1/5: crawl MyScheme");
  await runCommand("node", ["--env-file=.env", "scripts/myscheme_crawler.js"], {
    MYSCHEME_OUTPUT_PATH: crawlerOutputPath
  });

  if (process.env.PUBLIC_DATASET_URL) {
    console.log("[etl:update] Step 2/5: import public dataset");
    await runCommand("node", ["--env-file=.env", "scripts/import_public_dataset.js"], {
      PUBLIC_DATASET_URL: process.env.PUBLIC_DATASET_URL,
      PUBLIC_IMPORT_OUTPUT_PATH: importOutputPath
    });
  } else {
    console.log("[etl:update] Step 2/5: skip public import (PUBLIC_DATASET_URL not set)");
  }

  console.log("[etl:update] Step 3/5: merge data sources");
  const samplePath = path.resolve(process.cwd(), process.env.SAMPLE_DATA_PATH || "./data/sample_schemes.json");
  const sample = readJsonIfExists(samplePath);
  const crawled = readJsonIfExists(crawlerOutputPath);
  const imported = readJsonIfExists(importOutputPath);

  const merged = ensureSyntheticId(dedupeAndMerge([sample, crawled, imported]));
  ensureDir(aggregatePath);
  fs.writeFileSync(aggregatePath, JSON.stringify(merged, null, 2));

  console.log(`[etl:update] merged dataset: ${aggregatePath}`);
  console.log(`[etl:update] merged records: ${merged.length}`);

  console.log("[etl:update] Step 4/5: ingest merged data");
  await runCommand("node", ["--env-file=.env", "scripts/ingest_schemes.js", aggregatePath]);

  console.log("[etl:update] Step 5/5: run data quality audit");
  await runCommand("node", ["--env-file=.env", "scripts/data_quality_audit.js", aggregatePath]);

  console.log("[etl:update] completed");
};

run();
