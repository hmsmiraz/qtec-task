const promClient = require('prom-client');

// Collect default Node.js metrics (CPU, memory, event loop, etc.)
const collectDefaultMetrics = promClient.collectDefaultMetrics;
collectDefaultMetrics({ timeout: 5000 });

// ─── Custom Metrics ────────────────────────────────────────────

// Counter: total HTTP requests
const httpRequestCounter = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
});

// Histogram: request duration in seconds
const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.001, 0.005, 0.01, 0.05, 0.1, 0.3, 0.5, 1, 2, 5],
});

// Gauge: currently active requests
const activeRequestsGauge = new promClient.Gauge({
  name: 'http_active_requests',
  help: 'Number of currently active HTTP requests',
});

// Counter: total errors
const errorCounter = new promClient.Counter({
  name: 'http_errors_total',
  help: 'Total number of HTTP errors',
  labelNames: ['method', 'route', 'status_code'],
});

// ─── Middleware: track every request ───────────────────────────
const metricsMiddleware = (req, res, next) => {
  // Skip metrics endpoint itself
  if (req.url === '/metrics') return next();

  const start = Date.now();
  activeRequestsGauge.inc();

  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    const route = req.route ? req.route.path : req.url;
    const labels = {
      method: req.method,
      route,
      status_code: res.statusCode,
    };

    httpRequestCounter.inc(labels);
    httpRequestDuration.observe(labels, duration);
    activeRequestsGauge.dec();

    // Track errors (4xx and 5xx)
    if (res.statusCode >= 400) {
      errorCounter.inc(labels);
    }
  });

  next();
};

// ─── /metrics endpoint handler ─────────────────────────────────
const metricsEndpoint = async (req, res) => {
  try {
    res.set('Content-Type', promClient.register.contentType);
    const metrics = await promClient.register.metrics();
    res.end(metrics);
  } catch (error) {
    res.status(500).end(error.message);
  }
};

module.exports = {
  metricsMiddleware,
  metricsEndpoint,
  httpRequestCounter,
  httpRequestDuration,
  activeRequestsGauge,
  errorCounter,
};