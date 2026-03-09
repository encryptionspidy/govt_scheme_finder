import { Router } from "express";
import { validate } from "../../core/middleware/validate.js";
import { asyncHandler } from "../../core/middleware/asyncHandler.js";
import { schemeController } from "./schemeController.js";
import { recommendationSchema, schemeFiltersSchema } from "./schemeValidation.js";
import { z } from "zod";

const router = Router();

router.get("/", validate({ query: schemeFiltersSchema }), asyncHandler(schemeController.list));

router.get("/search", validate({ query: schemeFiltersSchema }), asyncHandler(schemeController.search));

router.get("/categories", asyncHandler(schemeController.categories));

router.get("/ministries", asyncHandler(schemeController.ministries));

router.get(
  "/beneficiary-types",
  asyncHandler(schemeController.beneficiaryTypes)
);

router.get(
  "/category/:category",
  validate({
    params: z.object({ category: z.string().min(1).max(80) }),
    query: schemeFiltersSchema
  }),
  asyncHandler(schemeController.listByCategory)
);

router.get(
  "/state/:state",
  validate({
    params: z.object({ state: z.string().min(1).max(80) }),
    query: schemeFiltersSchema
  }),
  asyncHandler(schemeController.listByState)
);

router.get(
  "/:id",
  validate({ params: z.object({ id: z.string().min(1).max(120) }) }),
  asyncHandler(schemeController.getById)
);

router.post(
  "/recommendations",
  validate({
    body: recommendationSchema,
    query: z.object({
      page: z.coerce.number().int().min(1).default(1),
      limit: z.coerce.number().int().min(1).max(100).default(20)
    })
  }),
  asyncHandler(schemeController.recommend)
);

export default router;
