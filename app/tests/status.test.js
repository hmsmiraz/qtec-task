const request = require('supertest');
const app = require('../src/index');

describe('GET /status', () => {
  it('should return 200 with status ok', async () => {
    const res = await request(app).get('/status');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('ok');
    expect(res.body).toHaveProperty('timestamp');
    expect(res.body).toHaveProperty('version');
    expect(res.body).toHaveProperty('system');
    expect(res.body).toHaveProperty('process');
  });

  it('should return 200 for /status/health', async () => {
    const res = await request(app).get('/status/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('ok');
  });

  it('should return 200 for /status/ready', async () => {
    const res = await request(app).get('/status/ready');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('ready');
  });

  it('should return 404 for unknown route', async () => {
    const res = await request(app).get('/unknown-route');
    expect(res.statusCode).toBe(404);
    expect(res.body.status).toBe('error');
  });
});

describe('GET /', () => {
  it('should return API info with endpoints', async () => {
    const res = await request(app).get('/');
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('endpoints');
    expect(res.body.app).toBe('qtec-task');
  });
});