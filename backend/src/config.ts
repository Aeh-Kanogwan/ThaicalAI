import 'dotenv/config';

export type VisionProviderName = 'mock' | 'openai' | 'gemini';

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
} as const;
