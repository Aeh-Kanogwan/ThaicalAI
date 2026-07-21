import { config } from '../../config.js';
import type { VisionProvider, VisionInput, VisionResult } from './types.js';
import { SYSTEM_PROMPT, USER_PROMPT, imageToBase64, parseVisionJson, fetchJson } from './_shared.js';

// Typhoon (SCB 10X, Thai LLM) via any OpenAI-compatible endpoint. Works with the
// hosted API (api.opentyphoon.ai) or a local server such as Ollama / vLLM — set
// TYPHOON_BASE_URL, TYPHOON_API_KEY, and TYPHOON_VISION_MODEL accordingly.
// Requires a vision-capable Typhoon model to read images.
export class TyphoonVisionProvider implements VisionProvider {
  readonly name = 'typhoon';

  async detect(input: VisionInput): Promise<VisionResult> {
    // A local server (Ollama/vLLM) may need no key; the hosted API does.
    const isLocal = /localhost|127\.0\.0\.1|host\.docker\.internal/.test(config.typhoon.baseUrl);
    if (!config.typhoon.apiKey && !isLocal) {
      throw new Error('TYPHOON_API_KEY is not set (hosted Typhoon API requires it).');
    }

    const base64 = imageToBase64(input);
    const dataUrl = `data:${input.mimeType ?? 'image/jpeg'};base64,${base64}`;
    const url = `${config.typhoon.baseUrl.replace(/\/$/, '')}/chat/completions`;

    const json = (await fetchJson(
      url,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...(config.typhoon.apiKey ? { Authorization: `Bearer ${config.typhoon.apiKey}` } : {}),
        },
        body: JSON.stringify({
          model: config.typhoon.model,
          max_tokens: 512,
          temperature: 0.2,
          messages: [
            { role: 'system', content: SYSTEM_PROMPT },
            {
              role: 'user',
              content: [
                { type: 'text', text: USER_PROMPT },
                { type: 'image_url', image_url: { url: dataUrl } },
              ],
            },
          ],
        }),
      },
      // Local CPU inference is slow — allow a long timeout.
      { timeoutMs: isLocal ? 180_000 : 30_000, retries: isLocal ? 0 : 1 },
    )) as { choices?: Array<{ message?: { content?: string } }> };

    const content = json.choices?.[0]?.message?.content;
    if (!content) throw new Error('Typhoon vision returned no content');
    return parseVisionJson(content);
  }
}
