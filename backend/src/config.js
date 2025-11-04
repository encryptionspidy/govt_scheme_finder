import dotenv from "dotenv";

dotenv.config();

export const config = {
  port: Number(process.env.PORT || 4000),
  ogd: {
    apiKey: process.env.OGD_API_KEY,
    baseUrl: "https://api.data.gov.in/resource",
    datasetId: process.env.OGD_DATASET_ID || "ef6ca11b-0c83-4c22-b88d-37dd7610ce0d",
    limit: Number(process.env.OGD_PAGE_LIMIT || 50)
  },
  cache: {
    ttlSeconds: Number(process.env.CACHE_TTL_SECONDS || 900)
  }
};

console.log(
  "[config] Using local sample_schemes.json only. OGD API calls are disabled."
);
