import { describe, it, expect } from 'vitest';
import { parseVisionJson, imageToBase64 } from '../_shared.js';

describe('parseVisionJson', () => {
  it('parses plain valid JSON', () => {
    const r = parseVisionJson(
      '{"items":[{"label":"ข้าวผัด","confidence":0.9,"estimatedPortion":"1 จาน","grams":300}]}',
    );
    expect(r.items).toHaveLength(1);
    expect(r.items[0].label).toBe('ข้าวผัด');
    expect(r.items[0].confidence).toBe(0.9);
    expect(r.confidence).toBe(0.9); // overall = max item confidence
  });

  it('parses JSON wrapped in ```json fences', () => {
    const raw = '```json\n{"items":[{"label":"ต้มยำ","confidence":0.8,"grams":250}]}\n```';
    const r = parseVisionJson(raw);
    expect(r.items).toHaveLength(1);
    expect(r.items[0].label).toBe('ต้มยำ');
    expect(r.items[0].grams).toBe(250);
  });

  it('extracts JSON embedded in prose', () => {
    const raw =
      'Sure! Here is what I see: {"items":[{"label":"ส้มตำ","confidence":0.7,"grams":180}]} Enjoy.';
    const r = parseVisionJson(raw);
    expect(r.items).toHaveLength(1);
    expect(r.items[0].label).toBe('ส้มตำ');
  });

  it('clamps negative confidence to 0', () => {
    const r = parseVisionJson('{"items":[{"label":"x","confidence":-0.5,"grams":100}]}');
    expect(r.items[0].confidence).toBe(0);
  });

  it('rescales confidence on a 0-100 scale (>1, ≤100) by /100', () => {
    const r = parseVisionJson('{"items":[{"label":"x","confidence":85,"grams":100}]}');
    expect(r.items[0].confidence).toBeCloseTo(0.85, 6);
  });

  it('clamps confidence >100 to 1', () => {
    const r = parseVisionJson('{"items":[{"label":"x","confidence":250,"grams":100}]}');
    expect(r.items[0].confidence).toBe(1);
  });

  it('missing items key → {confidence:0, items:[]}', () => {
    const r = parseVisionJson('{"foo":"bar"}');
    expect(r).toEqual({ confidence: 0, items: [] });
  });

  it('empty items array → {confidence:0, items:[]}', () => {
    const r = parseVisionJson('{"items":[]}');
    expect(r).toEqual({ confidence: 0, items: [] });
  });

  it('defaults grams to 300 when absent or non-positive', () => {
    const missing = parseVisionJson('{"items":[{"label":"a","confidence":0.5}]}');
    expect(missing.items[0].grams).toBe(300);
    const zero = parseVisionJson('{"items":[{"label":"b","confidence":0.5,"grams":0}]}');
    expect(zero.items[0].grams).toBe(300);
  });

  it('defaults estimatedPortion to "1 จาน" when absent or blank', () => {
    const r = parseVisionJson('{"items":[{"label":"a","confidence":0.5,"grams":100}]}');
    expect(r.items[0].estimatedPortion).toBe('1 จาน');
    const blank = parseVisionJson(
      '{"items":[{"label":"a","confidence":0.5,"grams":100,"estimatedPortion":"   "}]}',
    );
    expect(blank.items[0].estimatedPortion).toBe('1 จาน');
  });

  it('filters out items with empty/whitespace labels', () => {
    const r = parseVisionJson(
      '{"items":[{"label":"","confidence":0.9,"grams":100},{"label":"  ","confidence":0.9},{"label":"ผัดไทย","confidence":0.6,"grams":200}]}',
    );
    expect(r.items).toHaveLength(1);
    expect(r.items[0].label).toBe('ผัดไทย');
  });

  it('rounds fractional grams to an integer', () => {
    const r = parseVisionJson('{"items":[{"label":"a","confidence":0.5,"grams":123.7}]}');
    expect(r.items[0].grams).toBe(124);
  });

  it('throws when the response contains no JSON object at all', () => {
    expect(() => parseVisionJson('no json here')).toThrow(/not JSON/);
  });
});

describe('imageToBase64', () => {
  it('returns imageBase64 unchanged when it has no data-URL prefix', () => {
    expect(imageToBase64({ imageBase64: 'AAAA' })).toBe('AAAA');
  });

  it('strips a data-URL prefix from imageBase64', () => {
    expect(imageToBase64({ imageBase64: 'data:image/png;base64,AAAA' })).toBe('AAAA');
  });

  it('encodes an imageBuffer to base64', () => {
    const buf = Buffer.from('hello');
    expect(imageToBase64({ imageBuffer: buf })).toBe(buf.toString('base64'));
  });

  it('prefers imageBase64 over imageBuffer when both provided', () => {
    expect(
      imageToBase64({ imageBase64: 'BBBB', imageBuffer: Buffer.from('x') }),
    ).toBe('BBBB');
  });

  it('throws when neither imageBase64 nor imageBuffer is present', () => {
    expect(() => imageToBase64({})).toThrow(/neither/);
  });
});
