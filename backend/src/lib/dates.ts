// Day boundaries are resolved in Asia/Bangkok (UTC+7). Thailand observes no DST,
// so a fixed +07:00 offset is correct year-round — no tz database needed.
const BKK_OFFSET = '+07:00';
const BKK_SHIFT_MS = 7 * 60 * 60 * 1000;

// Returns [start, end) UTC instants bounding a YYYY-MM-DD Bangkok calendar day.
export function dayRange(date: string): { start: Date; end: Date } {
  const start = new Date(`${date}T00:00:00.000${BKK_OFFSET}`);
  if (Number.isNaN(start.getTime())) {
    throw new Error('Invalid date');
  }
  // Thailand has no DST, so a Bangkok day is exactly 24h.
  const end = new Date(start.getTime() + 24 * 60 * 60 * 1000);
  return { start, end };
}

// Today's date (YYYY-MM-DD) as it reads on a clock in Bangkok.
export function todayIso(): string {
  return new Date(Date.now() + BKK_SHIFT_MS).toISOString().slice(0, 10);
}

// Start of *today* in Bangkok (as a UTC instant) — used for VIP daily quota window.
export function startOfTodayBkk(): Date {
  return dayRange(todayIso()).start;
}

// End of today in Bangkok (as a UTC instant) — the resetAt for a daily quota.
export function endOfTodayBkk(): Date {
  return dayRange(todayIso()).end;
}
