import { z } from "zod";

const rawSchemeSchema = z.object({
  id: z.string().min(1),
  title: z.union([z.string(), z.record(z.string(), z.string())]).optional(),
  shortDescription: z.record(z.string(), z.string()).optional(),
  category: z.string().min(1).optional(),
  subcategory: z.string().optional(),
  ministry: z.string().optional(),
  targetBeneficiaries: z.array(z.string()).optional(),
  tags: z.array(z.string()).optional(),
  requiredDocuments: z.array(z.string()).optional(),
  benefits: z.union([z.record(z.string(), z.string()), z.array(z.string()), z.string()]).optional(),
  eligibility: z
    .object({
      ageRange: z.array(z.number().nullable()).length(2).optional(),
      gender: z.string().optional(),
      incomeMax: z.number().nullable().optional(),
      occupations: z.array(z.string()).optional(),
      states: z.array(z.string()).optional(),
      casteCategory: z.string().optional()
    })
    .optional(),
  state: z.string().optional(),
  applicationUrl: z.string().url().optional(),
  officialSource: z.string().url().optional(),
  source: z.string().optional(),
  agency: z.string().optional(),
  highlight: z.string().optional(),
  lastDate: z.string().optional(),
  imageUrl: z.string().optional(),
  badge: z.string().nullable().optional()
});

const normalizedText = (map, fallback = "") => {
  if (typeof map === "string") {
    return {
      en: map,
      ta: ""
    };
  }
  if (map && typeof map === "object") {
    return {
      en: map.en || Object.values(map)[0] || fallback,
      ta: map.ta || ""
    };
  }
  return { en: fallback, ta: "" };
};

export const normalizeRawScheme = (raw, source = "sample_schemes.json") => {
  const parsed = rawSchemeSchema.parse(raw);
  const title = normalizedText(parsed.title, parsed.id).en;
  const description = normalizedText(parsed.shortDescription, "");
  const benefits = Array.isArray(parsed.benefits)
    ? parsed.benefits.map((entry) => entry.toString())
    : [normalizedText(parsed.benefits, "").en].filter(Boolean);

  const eligibility = {
    ageRange: parsed.eligibility?.ageRange || [null, null],
    gender: parsed.eligibility?.gender || "any",
    incomeMax: parsed.eligibility?.incomeMax ?? null,
    occupations: parsed.eligibility?.occupations || [],
    states: parsed.eligibility?.states || [parsed.state || "All India"],
    casteCategory: parsed.eligibility?.casteCategory || null
  };

  const defaultTags = [
    parsed.category,
    ...(parsed.targetBeneficiaries || []),
    ...(eligibility.occupations || [])
  ]
    .filter(Boolean)
    .map((value) => value.trim())
    .filter((value, index, array) => array.indexOf(value) === index);

  const tags = [...(parsed.tags || []), ...defaultTags]
    .map((value) => value.trim())
    .filter((value, index, array) => value.length > 0 && array.indexOf(value) === index);

  const targetBeneficiaries = parsed.targetBeneficiaries || eligibility.occupations || [];

  const normalizedScheme = {
    id: parsed.id,
    name: title,
    description: description.en,
    ministry: parsed.ministry || parsed.agency || null,
    category: parsed.category || "Uncategorized",
    subcategory: parsed.subcategory || null,
    application_link: parsed.applicationUrl || null,
    official_source: parsed.officialSource || parsed.applicationUrl || null,
    target_beneficiaries: targetBeneficiaries,
    states: eligibility.states,
    tags_text: tags,
    last_updated: parsed.lastDate || new Date().toISOString(),
    metadata: {
      source,
      badge: parsed.badge || null,
      imageUrl: parsed.imageUrl || null,
      highlight: parsed.highlight || null,
      localized: {
        title: normalizedText(parsed.title, parsed.id),
        shortDescription: description
      }
    }
  };

  return {
    scheme: normalizedScheme,
    benefits: benefits.map((benefitDescription) => ({
      scheme_id: parsed.id,
      benefit_type: "general",
      benefit_description: benefitDescription,
      amount: null
    })),
    eligibilityRules: (eligibility.states.length > 0 ? eligibility.states : [null]).flatMap(
      (state) =>
        (eligibility.occupations.length > 0 ? eligibility.occupations : [null]).map((occupation) => ({
          scheme_id: parsed.id,
          gender: eligibility.gender,
          age_min: eligibility.ageRange[0],
          age_max: eligibility.ageRange[1],
          income_limit: eligibility.incomeMax,
          state,
          occupation,
          caste_category: eligibility.casteCategory
        }))
    ),
    documents: (parsed.requiredDocuments || []).map((documentName) => ({
      scheme_id: parsed.id,
      document_name: documentName
    })),
    tags
  };
};

export const isEligibilityInvalid = (normalized) => {
  for (const rule of normalized.eligibilityRules || []) {
    if (rule.age_min != null && rule.age_max != null && rule.age_min > rule.age_max) {
      return true;
    }
  }

  return false;
};
