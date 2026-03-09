import fs from "fs/promises";
import path from "path";
import { fileURLToPath } from "url";
import { fetchSchemesFromOGD } from "../services/ogdClient.js";
import { cacheWrap } from "../utils/cache.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const DATA_PATH = path.resolve(__dirname, "../../data/sample_schemes.json");

const toObject = (value, fallback = {}) =>
  value && typeof value === "object" && !Array.isArray(value) ? value : fallback;

const toStringMap = (value) => {
  const map = toObject(value);
  return Object.fromEntries(
    Object.entries(map).map(([key, val]) => [key, val?.toString?.() ?? ""])
  );
};

const normalizeScheme = (scheme) => {
  const input = toObject(scheme);
  const eligibility = toObject(input.eligibility);

  return {
    ...input,
    id: input.id?.toString?.() ?? "",
    title: toStringMap(input.title),
    shortDescription: toStringMap(input.shortDescription),
    category: input.category?.toString?.() ?? "",
    state: input.state?.toString?.() ?? "All India",
    benefits: toStringMap(input.benefits),
    eligibility: {
      ...eligibility,
      ageRange: Array.isArray(eligibility.ageRange) ? eligibility.ageRange : null,
      states:
        Array.isArray(eligibility.states) && eligibility.states.length > 0
          ? eligibility.states
          : [input.state?.toString?.() ?? "All India"]
    }
  };
};

const loadLocalSchemes = async () => {
  try {
    const file = await fs.readFile(DATA_PATH, "utf-8");
    const parsed = JSON.parse(file);
    if (!Array.isArray(parsed)) {
      console.error(
        `[schemeRepository] Invalid sample_schemes.json format at ${DATA_PATH}. Expected an array.`
      );
      return [];
    }

    const normalized = parsed.map(normalizeScheme).filter((scheme) => Boolean(scheme.id));
    console.log(
      `[schemeRepository] Loaded ${normalized.length} local schemes from sample_schemes.json`
    );
    return normalized;
  } catch (error) {
    console.error(
      `[schemeRepository] Failed to read sample schemes from ${DATA_PATH}: ${error.message}`
    );
    return [];
  }
};

const fetchCombinedSchemes = async (options = {}) => {
  const [seeded, ogdSchemes] = await Promise.all([
    loadLocalSchemes(),
    fetchSchemesFromOGD(options)
  ]);

  const merged = [...seeded];

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
