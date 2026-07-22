import { describe, it, expect } from 'vitest';
import { MockVisionProvider } from '../mock.js';

const provider = new MockVisionProvider();

describe('MockVisionProvider', () => {
  it('has name "mock"', () => {
    expect(provider.name).toBe('mock');
  });

  it('returns 1..3 items, each valid, for a range of base64 inputs', async () => {
    // Vary payload length to exercise the pickCount/startIdx branches.
    for (const len of [1, 5, 20, 47, 128, 999]) {
      const res = await provider.detect({ imageBase64: 'a'.repeat(len) });
      expect(res.items.length).toBeGreaterThanOrEqual(1);
      expect(res.items.length).toBeLessThanOrEqual(3);
      for (const it of res.items) {
        expect(it.label.trim().length).toBeGreaterThan(0);
        expect(it.confidence).toBeGreaterThanOrEqual(0);
        expect(it.confidence).toBeLessThanOrEqual(1);
        expect(it.grams).toBeGreaterThan(0);
        expect(Number.isFinite(it.grams)).toBe(true);
      }
    }
  });

  it('overall confidence equals the max item confidence and is in [0,1]', async () => {
    const res = await provider.detect({ imageBase64: 'abcdefg' });
    const maxItem = Math.max(...res.items.map((i) => i.confidence));
    expect(res.confidence).toBe(maxItem);
    expect(res.confidence).toBeGreaterThanOrEqual(0);
    expect(res.confidence).toBeLessThanOrEqual(1);
  });

  it('works from an imageBuffer input', async () => {
    const res = await provider.detect({ imageBuffer: Buffer.from('some-bytes-here') });
    expect(res.items.length).toBeGreaterThanOrEqual(1);
    expect(res.items[0].label.length).toBeGreaterThan(0);
  });

  it('is deterministic for the same input', async () => {
    const a = await provider.detect({ imageBase64: 'repeatable' });
    const b = await provider.detect({ imageBase64: 'repeatable' });
    expect(b).toEqual(a);
  });
});
