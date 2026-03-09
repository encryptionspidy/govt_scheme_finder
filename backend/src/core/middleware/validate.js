import { AppError } from "../errors/AppError.js";

export const validate = ({ params, query, body }) => (req, _res, next) => {
  const sections = [
    ["params", params],
    ["query", query],
    ["body", body]
  ];

  for (const [section, schema] of sections) {
    if (!schema) continue;
    const result = schema.safeParse(req[section]);
    if (!result.success) {
      return next(new AppError("Validation failed", 400, {
        section,
        issues: result.error.issues
      }));
    }
    req[section] = result.data;
  }

  return next();
};
