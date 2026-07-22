import { describe, it, expect } from 'vitest';
import { dayRange, todayIso } from '../dates.js';

describe('dayRange (Asia/Bangkok UTC+7 day boundaries)', () => {
  it('2026-07-22 maps to 2026-07-21T17:00Z .. 2026-07-22T17:00Z', () => {
    const { start, end } = dayRange('2026-07-22');
    // Bangkok midnight = 17:00 UTC the previous day.
    expect(start.toISOString()).toBe('2026-07-21T17:00:00.000Z');
    expect(end.toISOString()).toBe('2026-07-22T17:00:00.000Z');
  });

  it('a Bangkok day is exactly 24h', () => {
    const { start, end } = dayRange('2026-07-22');
    expect(end.getTime() - start.getTime()).toBe(24 * 60 * 60 * 1000);
  });

  it('timezone bug lock: 2026-07-21T17:15Z is INSIDE 2026-07-22 range', () => {
    // 17:15 UTC on the 21st is 00:15 on the 22nd in Bangkok — must count as the 22nd.
    const ts = new Date('2026-07-21T17:15:00.000Z');
    const d22 = dayRange('2026-07-22');
    expect(ts.getTime()).toBeGreaterThanOrEqual(d22.start.getTime());
    expect(ts.getTime()).toBeLessThan(d22.end.getTime());
  });

  it('timezone bug lock: 2026-07-21T17:15Z is NOT inside 2026-07-21 range', () => {
    const ts = new Date('2026-07-21T17:15:00.000Z');
    const d21 = dayRange('2026-07-21');
    const insideD21 = ts.getTime() >= d21.start.getTime() && ts.getTime() < d21.end.getTime();
    expect(insideD21).toBe(false);
  });

  it('end of a day equals start of the next day (half-open ranges tile)', () => {
    expect(dayRange('2026-07-22').end.toISOString()).toBe(
      dayRange('2026-07-23').start.toISOString(),
    );
  });

  it('throws on an invalid date string', () => {
    expect(() => dayRange('not-a-date')).toThrow('Invalid date');
  });
});

describe('todayIso', () => {
  it('returns a YYYY-MM-DD string', () => {
    expect(todayIso()).toMatch(/^\d{4}-\d{2}-\d{2}$/);
  });
});
