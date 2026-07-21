import { config } from '../../config.js';
import type { VisionProvider } from './types.js';
import { MockVisionProvider } from './mock.js';
import { OpenAiVisionProvider } from './openai.js';
import { GeminiVisionProvider } from './gemini.js';
import { ClaudeVisionProvider } from './claude.js';
import { TyphoonVisionProvider } from './typhoon.js';

export * from './types.js';

let cached: VisionProvider | null = null;

// Factory: picks the provider by VISION_PROVIDER env (default mock in dev).
export function getVisionProvider(): VisionProvider {
  if (cached) return cached;
  switch (config.visionProvider) {
    case 'openai':
      cached = new OpenAiVisionProvider();
      break;
    case 'gemini':
      cached = new GeminiVisionProvider();
      break;
    case 'claude':
      cached = new ClaudeVisionProvider();
      break;
    case 'typhoon':
      cached = new TyphoonVisionProvider();
      break;
    case 'mock':
    default:
      cached = new MockVisionProvider();
      break;
  }
  return cached;
}
