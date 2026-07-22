import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { randomUUID } from 'node:crypto';
import type { FastifyInstance } from 'fastify';
import { buildApp } from '../../src/app.js';
import { prisma } from '../../src/prisma.js';
import { computeDailyGoal } from '../../src/lib/nutrition.js';
import { todayIso } from '../../src/lib/dates.js';

// A 1x1 transparent PNG (base64). Any non-empty base64 works with the mock provider.
const PNG_1x1 =
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

// Run-scoped unique suffix (controlled by us, printed for traceability). NOT Date.now().
const RUN = randomUUID().slice(0, 8);
const email = `vitest+${RUN}@calthai.app`;
const password = 'Sup3rSecret!';

let app: FastifyInstance;
let token: string;
let userId: string;

beforeAll(async () => {
  // Ensure the mock provider regardless of any ambient env.
  process.env.VISION_PROVIDER = 'mock';
  app = await buildApp();
  await app.ready();
});

afterAll(async () => {
  // Clean up everything created for this user so re-runs stay green.
  if (userId) {
    await prisma.scanRecord.deleteMany({ where: { userId } }).catch(() => {});
    await prisma.mealLog.deleteMany({ where: { userId } }).catch(() => {});
    await prisma.profile.deleteMany({ where: { userId } }).catch(() => {});
    await prisma.user.deleteMany({ where: { id: userId } }).catch(() => {});
  }
  // Belt-and-suspenders: nuke by email pattern in case a prior run half-failed.
  await prisma.user.deleteMany({ where: { email } }).catch(() => {});
  await app.close();
  await prisma.$disconnect();
});

describe('GET /health', () => {
  it('returns 200 { ok: true }', async () => {
    const res = await app.inject({ method: 'GET', url: '/health' });
    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual({ ok: true });
  });
});

describe('auth', () => {
  it('registers a new user → 201 with token', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/register',
      payload: { email, password, name: 'Vitest User' },
    });
    expect(res.statusCode).toBe(201);
    const body = res.json();
    expect(typeof body.token).toBe('string');
    expect(body.user.email).toBe(email);
    userId = body.user.id;
    token = body.token;
  });

  it('rejects duplicate email → 409 EMAIL_TAKEN', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/register',
      payload: { email, password, name: 'Dup' },
    });
    expect(res.statusCode).toBe(409);
    expect(res.json().error.code).toBe('EMAIL_TAKEN');
  });

  it('logs in with correct credentials → 200', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/login',
      payload: { email, password },
    });
    expect(res.statusCode).toBe(200);
    token = res.json().token; // refresh token from login
    expect(typeof token).toBe('string');
  });

  it('rejects bad password → 401 INVALID_CREDENTIALS', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/login',
      payload: { email, password: 'wrong-password' },
    });
    expect(res.statusCode).toBe(401);
    expect(res.json().error.code).toBe('INVALID_CREDENTIALS');
  });

  it('rejects protected route with no token → 401 UNAUTHORIZED', async () => {
    const res = await app.inject({ method: 'GET', url: '/api/v1/me' });
    expect(res.statusCode).toBe(401);
    expect(res.json().error.code).toBe('UNAUTHORIZED');
  });
});

describe('profile & daily goal', () => {
  const profile = {
    sex: 'male' as const,
    age: 30,
    heightCm: 175,
    weightKg: 70,
    activityLevel: 'moderate' as const,
    goal: 'maintain' as const,
  };

  it('PUT /me/profile → dailyGoal matches nutrition.ts', async () => {
    const res = await app.inject({
      method: 'PUT',
      url: '/api/v1/me/profile',
      headers: { authorization: `Bearer ${token}` },
      payload: profile,
    });
    expect(res.statusCode).toBe(200);
    const expected = computeDailyGoal(profile);
    expect(res.json().dailyGoal).toEqual(expected);
  });

  it('GET /me → returns the same dailyGoal (bmr 1649 / tdee 2556)', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/v1/me',
      headers: { authorization: `Bearer ${token}` },
    });
    expect(res.statusCode).toBe(200);
    const g = res.json().dailyGoal;
    expect(g.bmr).toBe(1649);
    expect(g.tdee).toBe(2556);
    expect(g.calories).toBe(2556);
  });
});

describe('POST /scan with mock provider + quota enforcement', () => {
  it('returns items and quota, and enforces the free 3-scan lifetime limit', async () => {
    // Free tier lifetime limit = 3. This user is brand new → 3 succeed, 4th fails.
    for (let i = 1; i <= 3; i++) {
      const res = await app.inject({
        method: 'POST',
        url: '/api/v1/scan',
        headers: { authorization: `Bearer ${token}` },
        payload: { imageBase64: PNG_1x1, mimeType: 'image/png' },
      });
      expect(res.statusCode).toBe(200);
      const body = res.json();
      expect(Array.isArray(body.items)).toBe(true);
      expect(body.items.length).toBeGreaterThanOrEqual(1);
      for (const it of body.items) {
        expect(it.label.length).toBeGreaterThan(0);
        expect(it.confidence).toBeGreaterThanOrEqual(0);
        expect(it.confidence).toBeLessThanOrEqual(1);
        expect(it.grams).toBeGreaterThan(0);
      }
      expect(body.quota.used).toBe(i);
      expect(body.quota.limit).toBe(3);
    }

    // 4th scan → quota exceeded.
    const res4 = await app.inject({
      method: 'POST',
      url: '/api/v1/scan',
      headers: { authorization: `Bearer ${token}` },
      payload: { imageBase64: PNG_1x1, mimeType: 'image/png' },
    });
    expect(res4.statusCode).toBe(402);
    expect(res4.json().error.code).toBe('QUOTA_EXCEEDED');
  });
});

describe('meal logs (Thai customName via inject payload)', () => {
  it('POST /logs → 201, then GET /logs?date=today shows it in the summary', async () => {
    const create = await app.inject({
      method: 'POST',
      url: '/api/v1/logs',
      headers: { authorization: `Bearer ${token}` },
      payload: {
        customName: 'ข้าวกะเพราไก่ไข่ดาว',
        mealType: 'lunch',
        grams: 350,
        calories: 650,
        protein: 30,
        carbs: 70,
        fat: 25,
      },
    });
    expect(create.statusCode).toBe(201);
    const log = create.json().log;
    expect(log.name).toBe('ข้าวกะเพราไก่ไข่ดาว'); // Thai round-trips intact
    expect(log.calories).toBe(650);

    const date = todayIso(); // Bangkok date of "now"
    const list = await app.inject({
      method: 'GET',
      url: `/api/v1/logs?date=${date}`,
      headers: { authorization: `Bearer ${token}` },
    });
    expect(list.statusCode).toBe(200);
    const body = list.json();
    expect(body.date).toBe(date);
    expect(body.summary.calories).toBeGreaterThanOrEqual(650);
    const names = body.logs.map((l: { name: string }) => l.name);
    expect(names).toContain('ข้าวกะเพราไก่ไข่ดาว');
  });
});
