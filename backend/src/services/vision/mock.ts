import type { VisionProvider, VisionInput, VisionResult, VisionDetectedItem } from './types.js';

// A pool of plausible Thai dishes. Labels are chosen to line up with the
// keywords seeded into the foods DB so matching succeeds in dev.
const POOL: VisionDetectedItem[] = [
  { label: 'ข้าวผัดกะเพราไก่', confidence: 0.97, estimatedPortion: '1 จาน', grams: 350 },
  { label: 'ไข่ดาว', confidence: 0.94, estimatedPortion: '1 ฟอง', grams: 46 },
  { label: 'ต้มยำกุ้ง', confidence: 0.92, estimatedPortion: '1 ถ้วย', grams: 300 },
  { label: 'ผัดไทยกุ้งสด', confidence: 0.9, estimatedPortion: '1 จาน', grams: 300 },
  { label: 'ส้มตำไทย', confidence: 0.88, estimatedPortion: '1 จาน', grams: 200 },
  { label: 'ข้าวมันไก่', confidence: 0.91, estimatedPortion: '1 จาน', grams: 350 },
  { label: 'ข้าวเหนียว', confidence: 0.85, estimatedPortion: '1 ห่อ', grams: 120 },
  { label: 'ชาไทยเย็น', confidence: 0.8, estimatedPortion: '1 แก้ว', grams: 300 },
];

// Deterministic-ish pseudo-random based on payload size so tests are stable
// but different inputs can yield different item counts.
function pickCount(seed: number): number {
  return 1 + (seed % 3); // 1..3 items
}

export class MockVisionProvider implements VisionProvider {
  readonly name = 'mock';

  async detect(input: VisionInput): Promise<VisionResult> {
    const size =
      input.imageBuffer?.length ??
      (input.imageBase64 ? input.imageBase64.length : 7);
    const count = pickCount(size);
    const startIdx = size % POOL.length;

    const items: VisionDetectedItem[] = [];
    for (let i = 0; i < count; i++) {
      items.push(POOL[(startIdx + i) % POOL.length]);
    }

    const confidence = Math.max(...items.map((it) => it.confidence));
    return { confidence, items };
  }
}
