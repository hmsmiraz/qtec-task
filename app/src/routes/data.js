const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');

// In-memory store (will be replaced with real DB in production)
// This simulates data persistence for now
const dataStore = [];

/**
 * POST /data
 * Accepts JSON payload and stores it
 * Demonstrates POST endpoint with validation
 */
router.post('/', (req, res) => {
  try {
    const { name, value, tags } = req.body;

    // ─── Input Validation ──────────────────────────────────────
    if (!name || typeof name !== 'string') {
      return res.status(400).json({
        status: 'error',
        message: 'Field "name" is required and must be a string',
        requestId: req.id,
        timestamp: new Date().toISOString(),
      });
    }

    if (value === undefined || value === null) {
      return res.status(400).json({
        status: 'error',
        message: 'Field "value" is required',
        requestId: req.id,
        timestamp: new Date().toISOString(),
      });
    }

    // ─── Create Record ─────────────────────────────────────────
    const record = {
      id: uuidv4(),
      name: name.trim(),
      value,
      tags: tags || [],
      createdAt: new Date().toISOString(),
      requestId: req.id,
      processedBy: process.env.HOSTNAME || 'local', // shows which pod handled it in K8s
    };

    // Store in memory
    dataStore.push(record);

    // ─── Response ──────────────────────────────────────────────
    return res.status(201).json({
      status: 'success',
      message: 'Data stored successfully',
      data: record,
      timestamp: new Date().toISOString(),
    });

  } catch (error) {
    return res.status(500).json({
      status: 'error',
      message: 'Internal server error',
      requestId: req.id,
      timestamp: new Date().toISOString(),
    });
  }
});

/**
 * GET /data
 * Returns all stored data (for testing purposes)
 */
router.get('/', (req, res) => {
  res.status(200).json({
    status: 'success',
    count: dataStore.length,
    data: dataStore,
    timestamp: new Date().toISOString(),
  });
});

module.exports = router;