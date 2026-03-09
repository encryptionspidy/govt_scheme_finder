import fs from "fs";
import path from "path";

import { env } from "../src/config/env.js";
import { normalizeRawScheme } from "../src/modules/schemes/normalizer.js";

const sourcePath = process.argv[2]
  ? path.resolve(process.cwd(), process.argv[2])
  : path.resolve(process.cwd(), env.sampleDataPath);

const raw = JSON.parse(fs.readFileSync(sourcePath, "utf8"));
const ids = new Map();
const issues = [];

for (const [index, item] of raw.entries()) {
  try {
    const normalized = normalizeRawScheme(item);
    const scheme = normalized.scheme;

    if (ids.has(scheme.id)) {
      issues.push({ type: "duplicate_id", index, id: scheme.id });
    } else {
      ids.set(scheme.id, true);
    }

    if (!scheme.name || !scheme.description) {
      issues.push({ type: "missing_text", index, id: scheme.id });
    }

    if (!Array.isArray(scheme.states) || scheme.states.length === 0) {
      issues.push({ type: "missing_states", index, id: scheme.id });
    }

    if (!scheme.ministry) {
      issues.push({ type: "missing_ministry", index, id: scheme.id });
    }

    if (!scheme.category) {
      issues.push({ type: "missing_category", index, id: scheme.id });
    }

    if (!normalized.benefits.length) {
      issues.push({ type: "missing_benefits", index, id: scheme.id });
    }

    for (const rule of normalized.eligibilityRules) {
      if (rule.age_min != null && rule.age_max != null && rule.age_min > rule.age_max) {
        issues.push({ type: "invalid_age_range", index, id: scheme.id });
      }
    }
  } catch (error) {
    issues.push({ type: "parse_error", index, error: error.message });
  }
}

const report = {
  sourcePath,
  total: raw.length,
  issuesCount: issues.length,
  issues
};

const outPath = path.resolve(process.cwd(), "docs/data-quality-report.json");
fs.writeFileSync(outPath, JSON.stringify(report, null, 2));
console.log(`Data quality report written: ${outPath}`);
console.log(`Total issues: ${issues.length}`);
