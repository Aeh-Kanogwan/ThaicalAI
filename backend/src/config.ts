import 'dotenv/config';

export type VisionProviderName = 'mock' | 'openai' | 'gemini' | 'claude' | 'typhoon';

export const config = {
  port: Number(process.env.PORT ?? 4000),
  jwtSecret: process.env.JWT_SECRET ?? 'dev-insecure-secret',
  visionProvider: (process.env.VISION_PROVIDER ?? 'mock') as VisionProviderName,
  openai: {
    apiKey: process.env.OPENAI_API_KEY ?? '',
    model: process.env.OPENAI_VISION_MODEL ?? 'gpt-4o-mini',
  },
  gemini: {
    apiKey: process.env.GEMINI_API_KEY ?? '',
    model: process.env.GEMINI_VISION_MODEL ?? 'gemini-1.5-flash',
  },
  claude: {
    apiKey: process.env.ANTHROPIC_API_KEY ?? '',
    // Defaults to the most capable model. Food recognition is a simple task, so
    // set CLAUDE_VISION_MODEL=claude-haiku-4-5 to cut cost (~5x cheaper) toward
    // the Rqm §5 target of ~3.60 THB/user/month.
    model: process.env.CLAUDE_VISION_MODEL ?? 'claude-opus-4-8',
  },
  // Typhoon (SCB 10X, Thai LLM). OpenAI-compatible — point baseUrl at the hosted
  // API (https://api.opentyphoon.ai/v1) or a local server (Ollama:
  // http://localhost:11434/v1, vLLM: http://localhost:8000/v1).
  typhoon: {
    baseUrl: process.env.TYPHOON_BASE_URL ?? 'https://api.opentyphoon.ai/v1',
    apiKey: process.env.TYPHOON_API_KEY ?? '',
    model: process.env.TYPHOON_VISION_MODEL ?? 'typhoon2-vision',
  },
} as const;
