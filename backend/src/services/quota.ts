import type { Tier } from '@prisma/client';
import { prisma } from '../prisma.js';
import { startOfTodayUtc, endOfTodayUtc } from '../lib/dates.js';

export const FREE_LIFETIME_LIMIT = 3; // Rqm §5: free = 3 lifetime trial scans
export const VIP_DAILY_LIMIT = 10; // Rqm §5: VIP = up to 10/day

export interface QuotaStatus {
  used: number;
  limit: number;
  resetAt: string; // ISO; for free (lifetime) this is null-ish → we use end of today as a stable value
  tier: Tier;
}

// Compute current quota usage.
//  - free: lifetime count of ScanRecord; resetAt = null (no reset). We expose
//    end-of-today as a placeholder ISO so the contract's resetAt stays a string.
//  - vip:  count within today (UTC); resetAt = end of today.
export async function getQuota(userId: string, tier: Tier): Promise<QuotaStatus> {
  if (tier === 'vip') {
    const used = await prisma.scanRecord.count({
      where: { userId, createdAt: { gte: startOfTodayUtc(), lt: endOfTodayUtc() } },
    });
    return {
      used,
      limit: VIP_DAILY_LIMIT,
      resetAt: endOfTodayUtc().toISOString(),
      tier,
    };
  }

  // free — lifetime
  const used = await prisma.scanRecord.count({ where: { userId } });
  return {
    used,
    limit: FREE_LIFETIME_LIMIT,
    resetAt: endOfTodayUtc().toISOString(),
    tier,
  };
}

export function hasQuotaRemaining(q: QuotaStatus): boolean {
  return q.used < q.limit;
}
