const morgan = require('morgan');
const { v4: uuidv4 } = require('uuid');

// Assign unique request ID to every incoming request
const assignRequestId = (req, res, next) => {
  req.id = uuidv4();
  res.setHeader('X-Request-Id', req.id);
  next();
};

// Custom morgan token for request ID
morgan.token('request-id', (req) => req.id);

// Custom morgan token for response body size
morgan.token('body', (req) => JSON.stringify(req.body));

// Log format: [timestamp] METHOD URL status response-time requestId
const logFormat =
  '[:date[iso]] :method :url :status :response-time ms - RequestId::request-id';

// Morgan middleware with custom format
const httpLogger = morgan(logFormat, {
  // Skip health check logs to reduce noise
  skip: (req) => req.url === '/health',
});

module.exports = { httpLogger, assignRequestId };