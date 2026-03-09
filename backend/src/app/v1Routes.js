import { Router } from "express";
import schemeRoutes from "../modules/schemes/schemeRoutes.js";
import notificationRoutes from "../modules/notifications/notificationRoutes.js";
import healthRoutes from "../modules/health/healthRoutes.js";

const router = Router();

router.use(healthRoutes);
router.use("/schemes", schemeRoutes);
router.use("/notifications", notificationRoutes);

export default router;
