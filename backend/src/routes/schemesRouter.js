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
    res.json({ schemes });
  } catch (error) {
    next(error);
  }
});

router.get("/category/:category", async (req, res, next) => {
  try {
    const { category } = req.params;
    const schemes = await getSchemesByCategory(category);
    res.json({ schemes, category });
  } catch (error) {
    next(error);
  }
});

router.get("/state/:state", async (req, res, next) => {
  try {
    const { state } = req.params;
    const schemes = await getSchemesByState(state);
    res.json({ schemes, state });
  } catch (error) {
    next(error);
  }
});

router.post("/recommendations", async (req, res, next) => {
  try {
    const profile = req.body;
    const recommendations = await getRecommendations(profile);
    res.json({ recommendations });
  } catch (error) {
    next(error);
  }
});

export default router;
