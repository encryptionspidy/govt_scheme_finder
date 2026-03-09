import { cacheWrap } from "../../infrastructure/cache/cache.js";
import { schemeRepository } from "./schemeRepository.js";
import { AppError } from "../../core/errors/AppError.js";

const toFeatureVector = (scheme, profile) => {
  const eligibility = scheme.eligibility || {};
  const stateList = eligibility.states || [];

  const age = profile.age ?? null;
  const income = profile.income ?? null;
  const state = profile.state?.toLowerCase() || "";

  return {
    ageFit:
      age == null || !eligibility.ageRange
        ? 0.5
        : age >= (eligibility.ageRange[0] ?? 0) &&
          (eligibility.ageRange[1] == null || age <= eligibility.ageRange[1])
        ? 1
        : 0,
    incomeFit:
      income == null || eligibility.incomeMax == null
        ? 0.5
        : income <= eligibility.incomeMax
        ? 1
        : 0,
    genderFit:
      !profile.gender || !eligibility.gender || eligibility.gender === "any"
        ? 1
        : profile.gender.toLowerCase() === String(eligibility.gender).toLowerCase()
        ? 1
        : 0,
    stateFit:
      !state
        ? 0.5
        : stateList.some((s) => s.toLowerCase() === state || s.toLowerCase() === "all india")
        ? 1
        : 0,
    occupationFit:
      !profile.occupation || !eligibility.occupations?.length
        ? 0.5
        : eligibility.occupations.some(
            (o) => o.toLowerCase() === profile.occupation.toLowerCase() || o.toLowerCase() === "any"
          )
        ? 1
        : 0,
    casteFit:
      !profile.casteCategory || !eligibility.casteCategories?.length
        ? 0.5
        : eligibility.casteCategories.some(
            (c) => c.toLowerCase() === profile.casteCategory.toLowerCase() || c.toLowerCase() === "any"
          )
        ? 1
        : 0,
    beneficiaryFit:
      !profile.beneficiaryType || !scheme.targetBeneficiaries?.length
        ? 0.5
        : scheme.targetBeneficiaries.some(
            (b) =>
              b.toLowerCase() === profile.beneficiaryType.toLowerCase() || b.toLowerCase() === "any"
          )
        ? 1
        : 0
  };
};

const scoreScheme = (scheme, profile) => {
  const fv = toFeatureVector(scheme, profile);
  const score =
    fv.ageFit * 0.15 +
    fv.incomeFit * 0.2 +
    fv.genderFit * 0.1 +
    fv.stateFit * 0.15 +
    fv.occupationFit * 0.15 +
    fv.casteFit * 0.15 +
    fv.beneficiaryFit * 0.1;

  return {
    ...scheme,
    recommendation: {
      score: Number(score.toFixed(4)),
      featureVector: fv,
      reason: `age:${fv.ageFit}, income:${fv.incomeFit}, gender:${fv.genderFit}, state:${fv.stateFit}, occupation:${fv.occupationFit}, caste:${fv.casteFit}, beneficiary:${fv.beneficiaryFit}`
    }
  };
};

export const schemeService = {
  async listSchemes(filters) {
    return cacheWrap(
      `schemes:list:${JSON.stringify(filters)}`,
      async () => schemeRepository.findAll(filters),
      120
    );
  },

  async getSchemeById(id) {
    const scheme = await schemeRepository.findById(id);
    if (!scheme) {
      throw new AppError(`Scheme ${id} not found`, 404);
    }
    return scheme;
  },

  async searchSchemes(filters) {
    return cacheWrap(
      `schemes:search:${JSON.stringify(filters)}`,
      async () => schemeRepository.search(filters),
      120
    );
  },

  async getCategories() {
    return cacheWrap("schemes:categories", async () => schemeRepository.getCategories(), 300);
  },

  async getMinistries() {
    return cacheWrap("schemes:ministries", async () => schemeRepository.getMinistries(), 300);
  },

  async getBeneficiaryTypes() {
    return cacheWrap(
      "schemes:beneficiaryTypes",
      async () => schemeRepository.getBeneficiaryTypes(),
      300
    );
  },

  async recommend(profile, paging) {
    const cacheKey = `schemes:recommend:${JSON.stringify(profile)}:${JSON.stringify(paging)}`;
    return cacheWrap(cacheKey, async () => {
      const list = await schemeRepository.findAll({
        ...paging,
        category: undefined,
        beneficiaryType: profile.beneficiaryType,
        state: profile.state,
        gender: profile.gender,
        income: profile.income,
        age: profile.age
      });

      const ranked = list.items
        .map((scheme) => scoreScheme(scheme, profile))
        .filter((scheme) => scheme.recommendation.score >= 0.4)
        .sort((a, b) => b.recommendation.score - a.recommendation.score);

      return {
        items: ranked,
        total: ranked.length,
        page: paging.page,
        limit: paging.limit,
        hasMore: false
      };
    }, 300);
  }
};

export { scoreScheme, toFeatureVector };
