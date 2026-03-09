import { applyMigrations } from "../src/infrastructure/db/sqlite.js";
import { logger } from "../src/core/logging/logger.js";

const run = async () => {
	await applyMigrations();
	logger.info("Database initialized");
};

run();
