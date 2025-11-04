import fs from "fs/promises";
import path from "path";
import { fileURLToPath } from "url";
import { fetchSchemesFromOGD } from "../services/ogdClient.js";
import { cacheWrap } from "../utils/cache.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const DATA_PATH = path.resolve(__dirname, "../../data/sample_schemes.json");

const loadLocalSchemes = async () => {
  try {
    const file = await fs.readFile(DATA_PATH, "utf-8");
    return JSON.parse(file);
  } catch (error) {
    console.error("[schemeRepository] Failed to read sample schemes", error);
    return [];
  }
};

const fetchCombinedSchemes = async (options = {}) => {
  const [seeded, ogdSchemes] = await Promise.all([
    loadLocalSchemes(),
    fetchSchemesFromOGD(options)
  ]);

  const normalizedSeeded = seeded.map((scheme) => ({
    ...scheme,
    eligibility: {
      ...scheme.eligibility,
      ageRange: scheme.eligibility?.ageRange || null,
      states: scheme.eligibility?.states || [scheme.state]
    }
  }));

  const merged = [...normalizedSeeded];

  ogdSchemes.forEach((scheme) => {
    if (!merged.some((s) => s.id === scheme.id)) {
      merged.push(scheme);
    }
  });

  return merged;
};

export const getSchemes = (options = {}) =>
  cacheWrap("schemes:all", () => fetchCombinedSchemes(options));

export const getSchemesByCategory = async (category) => {
  const schemes = await getSchemes();
  return schemes.filter(
    (scheme) => scheme.category?.toLowerCase() === category.toLowerCase()
  );
};

export const getSchemesByState = async (state) => {
  const schemes = await getSchemes();
  return schemes.filter((scheme) => {
    const normalizedState = state.toLowerCase();
    return (
      scheme.state?.toLowerCase() === normalizedState ||
      scheme.eligibility?.states?.some((s) => s.toLowerCase() === normalizedState) ||
      scheme.eligibility?.states?.includes("All India")
    );
  });
};

export const getRecommendations = async (profile) => {
  const schemes = await getSchemes();
  return schemes
    .filter((scheme) => matchesProfile(scheme, profile))
    .slice(0, 20);
};

const matchesProfile = (scheme, profile) => {
  if (!profile) return true;
  const {
    age,
    gender,
    occupation,
    income,
    state
  } = profile;

  const { eligibility } = scheme;

  if (eligibility?.ageRange) {
    const [minAge, maxAge] = eligibility.ageRange;
    if (minAge && age < minAge) return false;
    if (maxAge && age > maxAge) return false;
  }

  if (eligibility?.gender && eligibility.gender !== "any") {
    if (gender?.toLowerCase() !== eligibility.gender.toLowerCase()) return false;
  }

  if (eligibility?.incomeMax && income && income > eligibility.incomeMax) {
    return false;
  }

  if (eligibility?.occupations?.length) {
    const profileOccupation = occupation?.toLowerCase();
    if (!eligibility.occupations.some((o) => o.toLowerCase() === profileOccupation)) {
      return false;
    }
  }

  if (state) {
    const normalizedState = state.toLowerCase();
    const eligibleStates = eligibility?.states?.map((s) => s.toLowerCase()) || [];
    if (
      !eligibleStates.includes(normalizedState) &&
      !eligibleStates.includes("all india") &&
      scheme.state?.toLowerCase() !== normalizedState
    ) {
      return false;
    }
  }

  return true;
};
