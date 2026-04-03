require('dotenv').config();
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');

const { httpLogger, assignRequestId } = require('./middleware/logger');
const { metricsMiddleware, metricsEndpoint } = require('./middleware/metrics');
const statusRouter = require('./routes/status');
const dataRouter = require('./routes/data');
const { loadSecrets, checkVaultHealth } = require('./config/vault');

const app = express();
const PORT = process.env.PORT || 3000;
const APP_NAME = process.env.APP_NAME || 'qtec-task';

// ─── Global Middleware ─────────────────────────────────────────
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(assignRequestId);
app.use(httpLogger);
app.use(metricsMiddleware);

// ─── Routes ───────────────────────────────────────────────────
app.use('/status', statusRouter);
app.use('/data', dataRouter);
app.get('/metrics', metricsEndpoint);

// Root endpoint
app.get('/', (req, res) => {
  res.status(200).json({
    app: APP_NAME,
    version: process.env.APP_VERSION || '1.0.0',
    endpoints: {
      status:  'GET /status',
      health:  'GET /status/health',
      ready:   'GET /status/ready',
      data:    'POST /data',
      metrics: 'GET /metrics',
      vault:   'GET /vault-status',
    },
    timestamp: new Date().toISOString(),
  });
});

// ─── Vault Status Endpoint ────────────────────────────────────
app.get('/vault-status', async (req, res) => {
  const health = await checkVaultHealth();
  res.status(health.connected ? 200 : 503).json({
    vault: health,
    timestamp: new Date().toISOString(),
  });
});

// ─── 404 Handler ──────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({
    status: 'error',
    message: `Route ${req.method} ${req.url} not found`,
    requestId: req.id,
    timestamp: new Date().toISOString(),
  });
});

// ─── Global Error Handler ─────────────────────────────────────
app.use((err, req, res, next) => {
  console.error(`[ERROR] ${err.stack}`);
  res.status(500).json({
    status: 'error',
    message: 'Something went wrong',
    requestId: req.id,
    timestamp: new Date().toISOString(),
  });
});

// ─── Export app for testing ────────────────────────────────────
module.exports = app;

// ─── Start server only when run directly ──────────────────────
if (require.main === module) {
  const startServer = async () => {
    // Load secrets from Vault before starting server
    // If Vault is unavailable, continue with env vars
    const vaultEnabled = process.env.VAULT_ENABLED === 'true';
    if (vaultEnabled) {
      await loadSecrets();
    } else {
      console.log('[Vault] Vault integration disabled, using env vars');
    }

    const server = app.listen(PORT, () => {
      console.log(`[${APP_NAME}] Server running on port ${PORT}`);
      console.log(`[${APP_NAME}] Environment: ${process.env.NODE_ENV}`);
      console.log(`[${APP_NAME}] Version: ${process.env.APP_VERSION || '1.0.0'}`);
      console.log(`[${APP_NAME}] Vault: ${vaultEnabled ? 'enabled' : 'disabled'}`);
    });

    // Handle SIGTERM (Kubernetes pod shutdown)
    process.on('SIGTERM', () => {
      console.log('[SIGTERM] Graceful shutdown initiated...');
      server.close(() => {
        console.log('[SIGTERM] Server closed. Process exiting.');
        process.exit(0);
      });
    });

    // Handle SIGINT (Ctrl+C)
    process.on('SIGINT', () => {
      console.log('[SIGINT] Graceful shutdown initiated...');
      server.close(() => {
        console.log('[SIGINT] Server closed. Process exiting.');
        process.exit(0);
      });
    });
  };

  startServer();
}