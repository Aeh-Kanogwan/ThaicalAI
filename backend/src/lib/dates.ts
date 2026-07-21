// Returns [start, end) UTC boundaries for a YYYY-MM-DD calendar day.
// NOTE: dev-simple — treats the date as a UTC day. A production build should
// resolve the day in the user's timezone (Asia/Bangkok).
export function dayRange(date: string): { start: Date; end: Date } {
  const start = new Date(`${date}T00:00:00.000Z`);
  if (Number.isNaN(start.getTime())) {
    throw new Error('Invalid date');
  }
  const end = new Date(start);
  end.setUTCDate(end.getUTCDate() + 1);
  return { start, end };
}

export function todayIso(): string {
  return new Date().toISOString().slice(0, 10);
}

// Start of *today* (UTC) — used for VIP daily quota window.
export function startOfTodayUtc(): Date {
  return new Date(`${todayIso()}T00:00:00.000Z`);
}

// End of today (UTC) — the resetAt for a daily quota.
export function endOfTodayUtc(): Date {
  const s = startOfTodayUtc();
  s.setUTCDate(s.getUTCDate() + 1);
  return s;
}
