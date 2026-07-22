import { describe, it, expect } from 'vitest';
import {
  hasQuotaRemaining,
  FREE_LIFETIME_LIMIT,
  VIP_DAILY_LIMIT,
  type QuotaStatus,
} from '../quota.js';

function status(used: number, limit: number): QuotaStatus {
  return { used, limit, resetAt: new Date().toISOString(), tier: 'free' };
}

describe('hasQuotaRemaining boundaries', () => {
  it('used < limit → true', () => {
    expect(hasQuotaRemaining(status(2, 3))).toBe(true);
  });

  it('used == limit → false (boundary)', () => {
    expect(hasQuotaRemaining(status(3, 3))).toBe(false);
  });

  it('used > limit → false', () => {
    expect(hasQuotaRemaining(status(4, 3))).toBe(false);
  });

  it('zero usage → true', () => {
    expect(hasQuotaRemaining(status(0, 3))).toBe(true);
  });

  it('exercises the documented free/vip limits at their boundary', () => {
    expect(hasQuotaRemaining(status(FREE_LIFETIME_LIMIT - 1, FREE_LIFETIME_LIMIT))).toBe(true);
    expect(hasQuotaRemaining(status(FREE_LIFETIME_LIMIT, FREE_LIFETIME_LIMIT))).toBe(false);
    expect(hasQuotaRemaining(status(VIP_DAILY_LIMIT - 1, VIP_DAILY_LIMIT))).toBe(true);
    expect(hasQuotaRemaining(status(VIP_DAILY_LIMIT, VIP_DAILY_LIMIT))).toBe(false);
  });

  it('documented limits are 3 (free lifetime) and 10 (vip daily)', () => {
    expect(FREE_LIFETIME_LIMIT).toBe(3);
    expect(VIP_DAILY_LIMIT).toBe(10);
  });
});
