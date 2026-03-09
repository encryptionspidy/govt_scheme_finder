import { Router } from "express";
import {
  getSchemes,
  getSchemesByCategory,
  getSchemesByState,
  getRecommendations
} from "../repositories/schemeRepository.js";

const router = Router();

router.get("/", async (req, res, next) => {
  try {
    const schemes = await getSchemes();
    console.log(`[schemesRouter] GET /schemes -> ${schemes.length} schemes`);
    res.json({ schemes });
  } catch (error) {
    console.error("[schemesRouter] GET /schemes failed", error);
    next(error);
  }
});

router.get("/category/:category", async (req, res, next) => {
  try {
    const { category } = req.params;
    const schemes = await getSchemesByCategory(category);
    console.log(
      `[schemesRouter] GET /schemes/category/${category} -> ${schemes.length} schemes`
    );
    res.json({ schemes, category });
  } catch (error) {
    console.error("[schemesRouter] GET /schemes/category failed", error);
    next(error);
  }
});

router.get("/state/:state", async (req, res, next) => {
  try {
    const { state } = req.params;
    const schemes = await getSchemesByState(state);
    console.log(`[schemesRouter] GET /schemes/state/${state} -> ${schemes.length} schemes`);
    res.json({ schemes, state });
  } catch (error) {
    console.error("[schemesRouter] GET /schemes/state failed", error);
    next(error);
  }
});

router.post("/recommendations", async (req, res, next) => {
  try {
    const profile = req.body;
    const recommendations = await getRecommendations(profile);
    console.log(
      `[schemesRouter] POST /schemes/recommendations -> ${recommendations.length} recommendations`
    );
    res.json({ recommendations });
  } catch (error) {
    console.error("[schemesRouter] POST /schemes/recommendations failed", error);
    next(error);
  }
});

export default router;
