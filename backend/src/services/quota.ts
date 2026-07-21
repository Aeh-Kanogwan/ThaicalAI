import type { Tier } from '@prisma/client';
import { prisma } from '../prisma.js';
import { startOfTodayBkk, endOfTodayBkk } from '../lib/dates.js';

export const FREE_LIFETIME_LIMIT = 3; // Rqm §5: free = 3 lifetime trial scans
export const VIP_DAILY_LIMIT = 10; // Rqm §5: VIP = up to 10/day

export interface QuotaStatus {
  used: number;
  limit: number;
  resetAt: string; // ISO; for free (lifetime) this is null-ish → we use end of today as a stable value
  tier: Tier;
}

// Compute current quota usage. Daily windows use the Bangkok calendar day.
//  - free: lifetime count of ScanRecord; no real reset — we expose end-of-today
//    (Bangkok) as a placeholder ISO so the contract's resetAt stays a string.
//  - vip:  count within today (Bangkok); resetAt = end of today (Bangkok).
export async function getQuota(userId: string, tier: Tier): Promise<QuotaStatus> {
  if (tier === 'vip') {
    const used = await prisma.scanRecord.count({
      where: { userId, createdAt: { gte: startOfTodayBkk(), lt: endOfTodayBkk() } },
    });
    return {
      used,
      limit: VIP_DAILY_LIMIT,
      resetAt: endOfTodayBkk().toISOString(),
      tier,
    };
  }

  // free — lifetime
  const used = await prisma.scanRecord.count({ where: { userId } });
  return {
    used,
    limit: FREE_LIFETIME_LIMIT,
    resetAt: endOfTodayBkk().toISOString(),
    tier,
  };
}

export function hasQuotaRemaining(q: QuotaStatus): boolean {
  return q.used < q.limit;
}
