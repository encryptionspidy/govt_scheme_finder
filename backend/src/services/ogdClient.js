import { config } from "../config.js";

export const fetchSchemesFromOGD = async ({ limit = config.ogd.limit, offset = 0, filters = {} } = {}) => {
  // OGD API disabled - only local data is used.
  void limit;
  void offset;
  void filters;

  return [];
};
