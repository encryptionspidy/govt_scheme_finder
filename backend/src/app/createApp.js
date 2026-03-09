import path from "path";
import express from "express";
import cors from "cors";
import helmet from "helmet";
import compression from "compression";
import expressRateLimit from "express-rate-limit";
import swaggerUi from "swagger-ui-express";
import YAML from "yamljs";

import { env } from "../config/env.js";
import { metricsMiddleware } from "../core/metrics/metrics.js";
import { requestContextMiddleware, requestTimingMiddleware } from "../core/middleware/requestContext.js";
import { errorHandlerMiddleware, notFoundMiddleware } from "../core/middleware/errorHandler.js";
import v1Routes from "./v1Routes.js";

const openApiPath = path.resolve(process.cwd(), "openapi.yaml");
const openApiSpec = YAML.load(openApiPath);

export const createApp = () => {
  const app = express();

  app.use(helmet());
  app.use(cors());
  app.use(compression());
  app.use(express.json({ limit: "1mb" }));

  app.use(requestContextMiddleware);
  app.use(requestTimingMiddleware);
  app.use(metricsMiddleware);

  app.use(expressRateLimit({
    windowMs: env.rateLimitWindowMs,
    limit: env.rateLimitMax,
    standardHeaders: true,
    legacyHeaders: false,
    message: {
      error: "RateLimitExceeded",
      message: "Too many requests, please retry later"
    }
  }));

  app.get("/", (_req, res) => {
    res.json({
      service: "SchemePlus API",
      version: "v1",
      docs: "/docs"
    });
  });

  app.use("/docs", swaggerUi.serve, swaggerUi.setup(openApiSpec));
  app.use("/api/v1", v1Routes);
  app.use("/api", v1Routes);

  app.use(notFoundMiddleware);
  app.use(errorHandlerMiddleware);

  return app;
};
