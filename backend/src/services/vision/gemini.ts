import { config } from '../../config.js';
import type { VisionProvider, VisionInput, VisionResult } from './types.js';

const SYSTEM_PROMPT = `You are a Thai food recognition assistant. Identify each distinct dish
in the photo (support multiple items). Respond ONLY with JSON:
{"items":[{"label":"<ชื่ออาหารไทย>","confidence":0-1,"estimatedPortion":"เช่น 1 จาน","grams":<number>}]}`;

export class GeminiVisionProvider implements VisionProvider {
  readonly name = 'gemini';

  async detect(input: VisionInput): Promise<VisionResult> {
    // TODO(vision/gemini): wire the real Gemini generateContent vision call.
    // Requires config.gemini.apiKey and config.gemini.model (default gemini-1.5-flash).
    // The intended request structure:
    //
    //   const base64 = input.imageBase64 ?? input.imageBuffer!.toString('base64');
    //   const url = `https://generativelanguage.googleapis.com/v1beta/models/${
    //     config.gemini.model}:generateContent?key=${config.gemini.apiKey}`;
    //   const res = await fetch(url, {
    //     method: 'POST',
    //     headers: { 'Content-Type': 'application/json' },
    //     body: JSON.stringify({
    //       systemInstruction: { parts: [{ text: SYSTEM_PROMPT }] },
    //       contents: [{ parts: [
    //         { text: 'ระบุอาหารในภาพนี้' },
    //         { inlineData: { mimeType: input.mimeType ?? 'image/jpeg', data: base64 } },
    //       ] }],
    //       generationConfig: { responseMimeType: 'application/json' },
    //     }),
    //   });
    //   const json = await res.json();
    //   const text = json.candidates[0].content.parts[0].text;
    //   const parsed = JSON.parse(text);
    //   return { confidence: Math.max(...parsed.items.map(i => i.confidence)), items: parsed.items };

    void SYSTEM_PROMPT;
    void input;
    void config;
    throw new Error(
      'GeminiVisionProvider not configured. Set VISION_PROVIDER=mock in dev, ' +
        'or implement the Gemini call and provide GEMINI_API_KEY.',
    );
  }
}
