import { isAppError } from "../errors/AppError.js";

export const notFoundMiddleware = (req, res) => {
  res.status(404).json({
    error: "NotFound",
    message: `Route not found: ${req.method} ${req.originalUrl}`,
    requestId: req.id
  });
};

export const errorHandlerMiddleware = (err, req, res, next) => {
  void next;
  const known = isAppError(err);
  const statusCode = known ? err.statusCode : 500;
  const payload = {
    error: known ? "ApplicationError" : "InternalServerError",
    message: err.message || "Unexpected server error",
    requestId: req.id,
    details: known ? err.details : undefined
  };

  req.log.error({ err, payload }, "request failed");
  res.status(statusCode).json(payload);
};
