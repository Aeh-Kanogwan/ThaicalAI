import { config } from '../../config.js';
import type { VisionProvider, VisionInput, VisionResult } from './types.js';

// Structured-output prompt asking the model to return Thai dishes with
// estimated portion + confidence, per Rqm §2 "Prompt Strategy".
const SYSTEM_PROMPT = `You are a Thai food recognition assistant. Given a food photo,
identify each distinct dish (support multiple items on one plate). Respond ONLY with JSON:
{"items":[{"label":"<ชื่ออาหารไทย>","confidence":0-1,"estimatedPortion":"เช่น 1 จาน","grams":<number>}]}`;

export class OpenAiVisionProvider implements VisionProvider {
  readonly name = 'openai';

  async detect(input: VisionInput): Promise<VisionResult> {
    // TODO(vision/openai): wire the real OpenAI Chat Completions vision call.
    // Requires config.openai.apiKey and config.openai.model (default gpt-4o-mini).
    // The intended request structure:
    //
    //   const dataUrl = `data:${input.mimeType ?? 'image/jpeg'};base64,${
    //     input.imageBase64 ?? input.imageBuffer!.toString('base64')
    //   }`;
    //   const res = await fetch('https://api.openai.com/v1/chat/completions', {
    //     method: 'POST',
    //     headers: {
    //       Authorization: `Bearer ${config.openai.apiKey}`,
    //       'Content-Type': 'application/json',
    //     },
    //     body: JSON.stringify({
    //       model: config.openai.model,
    //       response_format: { type: 'json_object' },
    //       messages: [
    //         { role: 'system', content: SYSTEM_PROMPT },
    //         { role: 'user', content: [
    //           { type: 'text', text: 'ระบุอาหารในภาพนี้' },
    //           { type: 'image_url', image_url: { url: dataUrl } },
    //         ] },
    //       ],
    //     }),
    //   });
    //   const json = await res.json();
    //   const parsed = JSON.parse(json.choices[0].message.content);
    //   return { confidence: Math.max(...parsed.items.map(i => i.confidence)), items: parsed.items };

    void SYSTEM_PROMPT;
    void input;
    void config;
    throw new Error(
      'OpenAiVisionProvider not configured. Set VISION_PROVIDER=mock in dev, ' +
        'or implement the OpenAI call and provide OPENAI_API_KEY.',
    );
  }
}
