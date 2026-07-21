import type { VisionInput, VisionResult, VisionDetectedItem } from './types.js';

// Shared prompt for both real providers — asks for structured JSON of Thai
// dishes with estimated portion + confidence, per Rqm §2 "Prompt Strategy".
export const SYSTEM_PROMPT = `You are a Thai food recognition assistant. Given a food photo,
identify each distinct dish (support multiple items on one plate, e.g. rice + fried egg + soup).
Use Thai dish names. Respond ONLY with strict JSON, no markdown, in this exact shape:
{"items":[{"label":"<ชื่ออาหารไทย>","confidence":<0-1>,"estimatedPortion":"<เช่น 1 จาน / 0.5 ถ้วย>","grams":<number>}]}
If no food is visible, return {"items":[]}.`;

export const USER_PROMPT = 'ระบุรายการอาหารไทยในภาพนี้ พร้อมประเมินปริมาณและความมั่นใจ';

export function imageToBase64(input: VisionInput): string {
  if (input.imageBase64) {
    // Strip a data URL prefix if the caller passed one.
    return input.imageBase64.replace(/^data:[^;]+;base64,/, '');
  }
  if (input.imageBuffer) return input.imageBuffer.toString('base64');
  throw new Error('VisionInput has neither imageBase64 nor imageBuffer');
}

// Extract a JSON object from a model response that may be wrapped in prose or
// ```json fences, then normalize it into a validated VisionResult.
export function parseVisionJson(raw: string): VisionResult {
  const text = raw.trim().replace(/^```(?:json)?/i, '').replace(/```$/i, '').trim();

  let obj: unknown;
  try {
    obj = JSON.parse(text);
  } catch {
    // Fallback: grab the first {...} block.
    const match = text.match(/\{[\s\S]*\}/);
    if (!match) throw new Error(`Vision response was not JSON: ${text.slice(0, 200)}`);
    obj = JSON.parse(match[0]);
  }

  const rawItems = (obj as { items?: unknown }).items;
  if (!Array.isArray(rawItems)) return { confidence: 0, items: [] };

  const items: VisionDetectedItem[] = rawItems
    .map((it): VisionDetectedItem | null => {
      const r = it as Record<string, unknown>;
      const label = typeof r.label === 'string' ? r.label.trim() : '';
      if (!label) return null;
      const confidence = clamp01(Number(r.confidence));
      const grams = Number(r.grams);
      return {
        label,
        confidence,
        estimatedPortion:
          typeof r.estimatedPortion === 'string' && r.estimatedPortion.trim()
            ? r.estimatedPortion.trim()
            : '1 จาน',
        grams: Number.isFinite(grams) && grams > 0 ? Math.round(grams) : 300,
      };
    })
    .filter((x): x is VisionDetectedItem => x !== null);

  const confidence = items.length ? Math.max(...items.map((i) => i.confidence)) : 0;
  return { confidence, items };
}

function clamp01(n: number): number {
  if (!Number.isFinite(n)) return 0.5;
  if (n < 0) return 0;
  if (n > 1) return n > 1 && n <= 100 ? n / 100 : 1; // tolerate 0-100 scale
  return n;
}

// fetch with timeout + one retry on transient failures (429 / 5xx / network).
export async function fetchJson(
  url: string,
  init: RequestInit,
  { timeoutMs = 20_000, retries = 1 }: { timeoutMs?: number; retries?: number } = {},
): Promise<unknown> {
  let lastErr: unknown;
  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      const res = await fetch(url, { ...init, signal: AbortSignal.timeout(timeoutMs) });
      if (res.ok) return await res.json();
      const body = await res.text().catch(() => '');
      // Retry transient server/rate-limit errors; fail fast on 4xx (bad key/request).
      if (res.status === 429 || res.status >= 500) {
        lastErr = new Error(`Vision API ${res.status}: ${body.slice(0, 300)}`);
        continue;
      }
      throw new Error(`Vision API ${res.status}: ${body.slice(0, 300)}`);
    } catch (err) {
      lastErr = err;
      if (attempt === retries) break;
    }
  }
  throw lastErr instanceof Error ? lastErr : new Error('Vision API request failed');
}
