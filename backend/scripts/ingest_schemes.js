import fs from "fs";
import path from "path";
import crypto from "crypto";

import { applyMigrations } from "../src/infrastructure/db/sqlite.js";
import { schemeRepository } from "../src/modules/schemes/schemeRepository.js";
import { normalizeRawScheme, isEligibilityInvalid } from "../src/modules/schemes/normalizer.js";
import { logger } from "../src/core/logging/logger.js";
import { env } from "../src/config/env.js";

const sourcePath = process.argv[2]
  ? path.resolve(process.cwd(), process.argv[2])
  : path.resolve(process.cwd(), env.sampleDataPath);

const main = async () => {
  await applyMigrations();

  const raw = JSON.parse(fs.readFileSync(sourcePath, "utf8"));
  if (!Array.isArray(raw)) {
    throw new Error("Input dataset must be an array of schemes");
  }

  const seen = new Set();
  const records = [];
  const errors = [];
  let duplicateCount = 0;

  for (const [index, item] of raw.entries()) {
    try {
      const normalized = normalizeRawScheme(item, path.basename(sourcePath));
      const schemeId = normalized.scheme.id;
      if (seen.has(schemeId)) {
        duplicateCount += 1;
        continue;
      }
      seen.add(schemeId);

      if (isEligibilityInvalid(normalized)) {
        errors.push({ index, id: schemeId, error: "invalid_age_range" });
        continue;
      }

      records.push(normalized);
    } catch (error) {
      errors.push({ index, error: error.message });
    }
  }

  await schemeRepository.upsertMany({
    records,
    run: {
      run_id: crypto.randomUUID(),
      source_path: sourcePath,
      imported_count: records.length,
      duplicate_count: duplicateCount,
      validation_errors: JSON.stringify(errors)
    }
  });

  logger.info(
    {
      sourcePath,
      imported: records.length,
      duplicateCount,
      validationErrors: errors.length
    },
    "Ingestion completed"
  );
};

main();
