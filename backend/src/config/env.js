import dotenv from "dotenv";

dotenv.config();

const toNumber = (value, fallback) => {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
};

export const env = {
  nodeEnv: process.env.NODE_ENV || "development",
  port: toNumber(process.env.PORT, 4000),
  logLevel: process.env.LOG_LEVEL || "info",
  requestTimeoutMs: toNumber(process.env.REQUEST_TIMEOUT_MS, 10000),
  cacheTtlSeconds: toNumber(process.env.CACHE_TTL_SECONDS, 600),
  rateLimitWindowMs: toNumber(process.env.RATE_LIMIT_WINDOW_MS, 60000),
  rateLimitMax: toNumber(process.env.RATE_LIMIT_MAX, 120),
  dbPath: process.env.DB_PATH || "./data/schemes.sqlite",
  sampleDataPath: process.env.SAMPLE_DATA_PATH || "./data/sample_schemes.json"
};
