import { createApp } from "./app/createApp.js";
import { env } from "./config/env.js";
import { logger } from "./core/logging/logger.js";
import { applyMigrations } from "./infrastructure/db/sqlite.js";

const start = async () => {
  await applyMigrations();

  const app = createApp();
  const server = app.listen(env.port, () => {
    logger.info({ port: env.port }, "SchemePlus backend listening");
  });

  server.on("error", (err) => {
    logger.error({ err }, "server failed to start");
    process.exit(1);
  });
};

start();
