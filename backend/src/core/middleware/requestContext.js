import pinoHttp from "pino-http";
import crypto from "crypto";
import { logger } from "../logging/logger.js";

export const requestContextMiddleware = pinoHttp({
  logger,
  genReqId: (req, res) => {
    const incoming = req.headers["x-request-id"];
    const requestId = typeof incoming === "string" && incoming.trim()
      ? incoming
      : crypto.randomUUID();
    res.setHeader("x-request-id", requestId);
    return requestId;
  },
  customLogLevel: (req, res, err) => {
    if (err || res.statusCode >= 500) return "error";
    if (res.statusCode >= 400) return "warn";
    return "info";
  },
  customSuccessMessage: (req, res) => `${req.method} ${req.url} completed with ${res.statusCode}`
});

export const requestTimingMiddleware = (req, res, next) => {
  const start = process.hrtime.bigint();
  res.on("finish", () => {
    const durationMs = Number(process.hrtime.bigint() - start) / 1_000_000;
    req.log.info({ durationMs: Number(durationMs.toFixed(2)) }, "request completed");
  });
  next();
};
