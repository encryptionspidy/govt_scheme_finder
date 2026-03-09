import { z } from "zod";

export const schemeFiltersSchema = z.object({
  q: z.string().trim().min(1).max(120).optional(),
  category: z.string().trim().min(1).max(80).optional(),
  ministry: z.string().trim().min(1).max(120).optional(),
  beneficiaryType: z.string().trim().min(1).max(120).optional(),
  tag: z.string().trim().min(1).max(80).optional(),
  state: z.string().trim().min(1).max(80).optional(),
  gender: z.string().trim().min(1).max(20).optional(),
  income: z.coerce.number().int().nonnegative().optional(),
  age: z.coerce.number().int().nonnegative().optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20)
});

export const recommendationSchema = z.object({
  name: z.string().trim().min(1).max(100).optional(),
  age: z.number().int().nonnegative().optional(),
  gender: z.string().trim().min(1).max(20).optional(),
  occupation: z.string().trim().min(1).max(80).optional(),
  beneficiaryType: z.string().trim().min(1).max(120).optional(),
  casteCategory: z.string().trim().min(1).max(60).optional(),
  income: z.number().int().nonnegative().optional(),
  state: z.string().trim().min(1).max(80).optional()
});
