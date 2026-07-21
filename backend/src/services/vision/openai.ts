import { config } from '../../config.js';
import type { VisionProvider, VisionInput, VisionResult } from './types.js';
import { SYSTEM_PROMPT, USER_PROMPT, imageToBase64, parseVisionJson, fetchJson } from './_shared.js';

// Real OpenAI Chat Completions vision call (gpt-4o-mini by default), asking for
// structured JSON per Rqm §2. Cost target ~3.60 THB/user/month (Rqm §5) is kept
// low by using the mini model + small max_tokens.
export class OpenAiVisionProvider implements VisionProvider {
  readonly name = 'openai';

  async detect(input: VisionInput): Promise<VisionResult> {
    if (!config.openai.apiKey) {
      throw new Error('OPENAI_API_KEY is not set (VISION_PROVIDER=openai requires it).');
    }

    const base64 = imageToBase64(input);
    const dataUrl = `data:${input.mimeType ?? 'image/jpeg'};base64,${base64}`;

    const json = (await fetchJson('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${config.openai.apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: config.openai.model,
        max_tokens: 500,
        temperature: 0.2,
        response_format: { type: 'json_object' },
        messages: [
          { role: 'system', content: SYSTEM_PROMPT },
          {
            role: 'user',
            content: [
              { type: 'text', text: USER_PROMPT },
              // "low" detail keeps token cost down; food ID rarely needs high-res.
              { type: 'image_url', image_url: { url: dataUrl, detail: 'low' } },
            ],
          },
        ],
      }),
    })) as { choices?: Array<{ message?: { content?: string } }> };

    const content = json.choices?.[0]?.message?.content;
    if (!content) throw new Error('OpenAI vision returned no content');
    return parseVisionJson(content);
  }
}
