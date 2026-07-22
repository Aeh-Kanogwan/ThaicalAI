import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'node',
    globals: false,
    // Load env + force mock vision BEFORE any src module (config.ts, prisma.ts) is imported.
    setupFiles: ['./test/setup.ts'],
    include: ['src/**/*.test.ts', 'test/**/*.test.ts'],
    // Integration tests share one dev Postgres; run files sequentially to avoid
    // cross-file quota/log contention on the same user rows.
    fileParallelism: false,
    hookTimeout: 30_000,
    testTimeout: 30_000,
  },
});
