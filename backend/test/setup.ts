// Global test setup — runs before each test file is evaluated.
// 1) Force the mock vision provider so no test ever needs a real API key.
// 2) Load DATABASE_URL (and friends) from .env for the integration tests.
//    We deliberately do NOT read or log the file contents here.
import { config as loadEnv } from 'dotenv';

process.env.VISION_PROVIDER = 'mock';
loadEnv(); // populates process.env from backend/.env if present
