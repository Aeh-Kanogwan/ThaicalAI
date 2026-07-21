import { config } from '../../config.js';
import type { VisionProvider, VisionInput, VisionResult } from './types.js';
import { SYSTEM_PROMPT, USER_PROMPT, imageToBase64, parseVisionJson, fetchJson } from './_shared.js';

// Real Google Gemini generateContent vision call (gemini-1.5-flash by default),
// asking for structured JSON per Rqm §2.
export class GeminiVisionProvider implements VisionProvider {
  readonly name = 'gemini';

  async detect(input: VisionInput): Promise<VisionResult> {
    if (!config.gemini.apiKey) {
      throw new Error('GEMINI_API_KEY is not set (VISION_PROVIDER=gemini requires it).');
    }

    const base64 = imageToBase64(input);
    const url =
      `https://generativelanguage.googleapis.com/v1beta/models/${config.gemini.model}:generateContent` +
      `?key=${config.gemini.apiKey}`;

    const json = (await fetchJson(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: SYSTEM_PROMPT }] },
        contents: [
          {
            role: 'user',
            parts: [
              { text: USER_PROMPT },
              { inlineData: { mimeType: input.mimeType ?? 'image/jpeg', data: base64 } },
            ],
          },
        ],
        generationConfig: { responseMimeType: 'application/json', temperature: 0.2 },
      }),
    })) as {
      candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }>;
      promptFeedback?: { blockReason?: string };
    };

    if (json.promptFeedback?.blockReason) {
      throw new Error(`Gemini blocked the request: ${json.promptFeedback.blockReason}`);
    }
    const text = json.candidates?.[0]?.content?.parts?.map((p) => p.text ?? '').join('');
    if (!text) throw new Error('Gemini vision returned no content');
    return parseVisionJson(text);
  }
}
