import pino from "pino";
import { env } from "../../config/env.js";

export const logger = pino({
  level: env.logLevel,
  base: {
    service: "schemeplus-backend",
    env: env.nodeEnv
  },
  timestamp: pino.stdTimeFunctions.isoTime
});
