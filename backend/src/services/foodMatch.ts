import type { Food } from '@prisma/client';
import { prisma } from '../prisma.js';

// Normalize a label for loose comparison (strip spaces, lowercase).
function norm(s: string): string {
  return s.replace(/\s+/g, '').toLowerCase();
}

// Match a single Vision label against the foods DB.
// Strategy: try keyword containment first (most reliable for AI labels),
// then substring match on nameTh / nameEn. Returns best candidate or null.
export async function matchFoodByLabel(label: string): Promise<Food | null> {
  const q = label.trim();
  if (!q) return null;

  // Pull a candidate set with a broad case-insensitive query, then rank in JS.
  const candidates = await prisma.food.findMany({
    where: {
      OR: [
        { nameTh: { contains: q, mode: 'insensitive' } },
        { nameEn: { contains: q, mode: 'insensitive' } },
        { keywords: { has: q } },
        // Also try token-level keyword overlap for multi-word labels.
        { keywords: { hasSome: q.split(/\s+/) } },
      ],
    },
    take: 25,
  });

  if (candidates.length === 0) return null;

  const nq = norm(q);
  let best: Food | null = null;
  let bestScore = -1;

  for (const f of candidates) {
    let score = 0;
    const nth = norm(f.nameTh);
    const nen = f.nameEn ? norm(f.nameEn) : '';

    if (nth === nq || nen === nq) score = 100;
    else if (nth.includes(nq) || nq.includes(nth)) score = 80;
    else if (nen && (nen.includes(nq) || nq.includes(nen))) score = 70;

    for (const kw of f.keywords) {
      const nkw = norm(kw);
      if (nkw === nq) score = Math.max(score, 90);
      else if (nq.includes(nkw) || nkw.includes(nq)) score = Math.max(score, 60);
    }

    if (score > bestScore) {
      bestScore = score;
      best = f;
    }
  }

  return bestScore > 0 ? best : candidates[0];
}
