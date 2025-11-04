import { Router } from "express";
import schemesRouter from "./schemesRouter.js";
import notificationsRouter from "./notificationsRouter.js";

const router = Router();

router.use("/schemes", schemesRouter);
router.use("/notifications", notificationsRouter);

router.get("/health", (req, res) => {
  res.json({ status: "ok" });
});

export default router;
