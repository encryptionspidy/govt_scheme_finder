import { Router } from "express";
import { register } from "../../core/metrics/metrics.js";

const router = Router();

router.get("/health", (_req, res) => {
  res.json({ status: "ok", uptimeSec: process.uptime() });
});

router.get("/metrics", async (_req, res) => {
  res.set("Content-Type", register.contentType);
  res.send(await register.metrics());
});

router.get("/test/ping", (_req, res) => {
  res.json({ message: "pong" });
});

export default router;
