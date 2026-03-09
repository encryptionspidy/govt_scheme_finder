import client from "prom-client";

export const register = new client.Registry();
client.collectDefaultMetrics({ register });

export const httpRequestDuration = new client.Histogram({
  name: "http_request_duration_ms",
  help: "HTTP request duration in milliseconds",
  labelNames: ["method", "route", "status_code"],
  buckets: [10, 25, 50, 100, 250, 500, 1000, 2000]
});

export const httpRequestsTotal = new client.Counter({
  name: "http_requests_total",
  help: "Total number of HTTP requests",
  labelNames: ["method", "route", "status_code"]
});

register.registerMetric(httpRequestDuration);
register.registerMetric(httpRequestsTotal);

export const metricsMiddleware = (req, res, next) => {
  const end = httpRequestDuration.startTimer();
  res.on("finish", () => {
    const route = req.route?.path || req.path || "unknown";
    const labels = {
      method: req.method,
      route,
      status_code: String(res.statusCode)
    };
    httpRequestsTotal.inc(labels);
    end(labels);
  });
  next();
};
