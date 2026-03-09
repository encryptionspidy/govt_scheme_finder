import fs from "fs";
import path from "path";
import initSqlJs from "sql.js";
import { env } from "../../config/env.js";
import { logger } from "../../core/logging/logger.js";

const migrationsDir = path.resolve(process.cwd(), "src/infrastructure/db/migrations");
const dbPath = path.resolve(process.cwd(), env.dbPath);

let db;
let initialized = false;

export const initDb = async () => {
  if (initialized) return;

  fs.mkdirSync(path.dirname(dbPath), { recursive: true });
  const SQL = await initSqlJs();

  if (fs.existsSync(dbPath)) {
    const fileBuffer = fs.readFileSync(dbPath);
    db = new SQL.Database(fileBuffer);
  } else {
    db = new SQL.Database();
  }

  initialized = true;
};

export const persistDb = () => {
  if (!db) return;
  const binary = db.export();
  fs.writeFileSync(dbPath, Buffer.from(binary));
};

export const applyMigrations = async () => {
  await initDb();
  db.run(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      version TEXT PRIMARY KEY,
      applied_at TEXT NOT NULL DEFAULT (datetime('now'))
    )
  `);

  const appliedRows = queryAll("SELECT version FROM schema_migrations");
  const applied = new Set(appliedRows.map((row) => row.version));

  const migrationFiles = fs
    .readdirSync(migrationsDir)
    .filter((name) => name.endsWith(".sql"))
    .sort();

  for (const fileName of migrationFiles) {
    if (applied.has(fileName)) continue;
    const sql = fs.readFileSync(path.join(migrationsDir, fileName), "utf8");
    db.run(sql);
    run(
      "INSERT INTO schema_migrations (version) VALUES (:version)",
      { ":version": fileName }
    );
    logger.info({ fileName }, "migration applied");
  }

  persistDb();
  logger.info({ dbPath }, "sqlite migrations applied");
};

export const queryAll = (sql, params = {}) => {
  const stmt = db.prepare(sql);
  stmt.bind(params);
  const rows = [];
  while (stmt.step()) {
    rows.push(stmt.getAsObject());
  }
  stmt.free();
  return rows;
};

export const queryOne = (sql, params = {}) => {
  const rows = queryAll(sql, params);
  return rows[0] || null;
};

export const run = (sql, params = {}) => {
  const stmt = db.prepare(sql);
  stmt.bind(params);
  stmt.step();
  stmt.free();
};

export const withTransaction = async (fn) => {
  run("BEGIN");
  try {
    await fn();
    run("COMMIT");
    persistDb();
  } catch (error) {
    run("ROLLBACK");
    throw error;
  }
};
