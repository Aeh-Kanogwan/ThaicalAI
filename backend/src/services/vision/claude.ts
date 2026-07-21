import Anthropic from '@anthropic-ai/sdk';
import { config } from '../../config.js';
import type { VisionProvider, VisionInput, VisionResult } from './types.js';
import { SYSTEM_PROMPT, USER_PROMPT, imageToBase64, parseVisionJson } from './_shared.js';

// JSON Schema for structured output — guarantees the model returns valid,
// parseable JSON matching our VisionResult item shape (per Rqm §2).
const OUTPUT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  properties: {
    items: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        properties: {
          label: { type: 'string' },
          confidence: { type: 'number' },
          estimatedPortion: { type: 'string' },
          grams: { type: 'number' },
        },
        required: ['label', 'confidence', 'estimatedPortion', 'grams'],
      },
    },
  },
  required: ['items'],
} as const;

// Vision provider backed by Claude (default claude-opus-4-8) via the official
// Anthropic SDK, asking for structured JSON of Thai dishes.
export class ClaudeVisionProvider implements VisionProvider {
  readonly name = 'claude';
  private client: Anthropic | null = null;

  private getClient(): Anthropic {
    if (!config.claude.apiKey) {
      throw new Error('ANTHROPIC_API_KEY is not set (VISION_PROVIDER=claude requires it).');
    }
    if (!this.client) this.client = new Anthropic({ apiKey: config.claude.apiKey });
    return this.client;
  }

  async detect(input: VisionInput): Promise<VisionResult> {
    const base64 = imageToBase64(input);
    const mediaType = (input.mimeType ?? 'image/jpeg') as
      | 'image/jpeg'
      | 'image/png'
      | 'image/gif'
      | 'image/webp';

    const response = await this.getClient().messages.create({
      model: config.claude.model,
      max_tokens: 1024,
      system: SYSTEM_PROMPT,
      // Constrain the response to strict JSON matching OUTPUT_SCHEMA.
      output_config: { format: { type: 'json_schema', schema: OUTPUT_SCHEMA } },
      messages: [
        {
          role: 'user',
          content: [
            { type: 'image', source: { type: 'base64', media_type: mediaType, data: base64 } },
            { type: 'text', text: USER_PROMPT },
          ],
        },
      ],
    });

    if (response.stop_reason === 'refusal') {
      throw new Error('Claude declined to analyze the image (safety refusal).');
    }
    const text = response.content
      .filter((b): b is Anthropic.TextBlock => b.type === 'text')
      .map((b) => b.text)
      .join('');
    if (!text) throw new Error('Claude vision returned no content');
    return parseVisionJson(text);
  }
}
