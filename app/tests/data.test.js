const request = require('supertest');
const app = require('../src/index');

describe('POST /data', () => {
  it('should store data and return 201', async () => {
    const payload = {
      name: 'test-item',
      value: 42,
      tags: ['test', 'devops'],
    };

    const res = await request(app).post('/data').send(payload);
    expect(res.statusCode).toBe(201);
    expect(res.body.status).toBe('success');
    expect(res.body.data).toHaveProperty('id');
    expect(res.body.data.name).toBe('test-item');
    expect(res.body.data.value).toBe(42);
  });

  it('should return 400 when name is missing', async () => {
    const res = await request(app).post('/data').send({ value: 10 });
    expect(res.statusCode).toBe(400);
    expect(res.body.status).toBe('error');
  });

  it('should return 400 when value is missing', async () => {
    const res = await request(app).post('/data').send({ name: 'test' });
    expect(res.statusCode).toBe(400);
    expect(res.body.status).toBe('error');
  });

  it('should return 400 when name is not a string', async () => {
    const res = await request(app)
      .post('/data')
      .send({ name: 123, value: 10 });
    expect(res.statusCode).toBe(400);
    expect(res.body.status).toBe('error');
  });
});

describe('GET /data', () => {
  it('should return list of stored data', async () => {
    const res = await request(app).get('/data');
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('count');
    expect(Array.isArray(res.body.data)).toBe(true);
  });
});