const express = require('express');
const router = express.Router();
const os = require('os');

/**
 * GET /status
 * Health check + system info endpoint
 * Used by:
 *  - Kubernetes liveness & readiness probes
 *  - Prometheus health monitoring
 *  - Load balancer health checks (Nginx)
 */
router.get('/', (req, res) => {
  const statusData = {
    status: 'ok',
    message: 'Service is running',
    timestamp: new Date().toISOString(),
    requestId: req.id,
    environment: process.env.NODE_ENV || 'development',
    version: process.env.APP_VERSION || '1.0.0',
    appName: process.env.APP_NAME || 'qtec-task',
    system: {
      platform: os.platform(),
      arch: os.arch(),
      // Memory in MB
      totalMemoryMB: Math.round(os.totalmem() / 1024 / 1024),
      freeMemoryMB: Math.round(os.freemem() / 1024 / 1024),
      uptimeSeconds: Math.round(os.uptime()),
      cpuCount: os.cpus().length,
      hostname: os.hostname(),
    },
    process: {
      pid: process.pid,
      uptimeSeconds: Math.round(process.uptime()),
      memoryUsageMB: Math.round(process.memoryUsage().heapUsed / 1024 / 1024),
      nodeVersion: process.version,
    },
  };

  res.status(200).json(statusData);
});

/**
 * GET /status/health
 * Simple liveness probe for Kubernetes
 * Returns minimal response — fast and lightweight
 */
router.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString(),
  });
});

/**
 * GET /status/ready
 * Readiness probe for Kubernetes
 * Can add DB checks, Vault checks here in later steps
 */
router.get('/ready', (req, res) => {
  // In later steps: check Vault connection, DB connection etc.
  const isReady = true;

  if (isReady) {
    res.status(200).json({
      status: 'ready',
      timestamp: new Date().toISOString(),
    });
  } else {
    res.status(503).json({
      status: 'not ready',
      timestamp: new Date().toISOString(),
    });
  }
});

module.exports = router;