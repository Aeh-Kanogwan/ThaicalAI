import Fastify, { type FastifyInstance } from 'fastify';
import cors from '@fastify/cors';
import multipart from '@fastify/multipart';
import authPlugin from './plugins/auth.js';
import { ApiError } from './errors.js';
import authRoutes from './routes/auth.js';
import meRoutes from './routes/me.js';
import foodsRoutes from './routes/foods.js';
import scanRoutes from './routes/scan.js';
import logsRoutes from './routes/logs.js';
import trackingRoutes from './routes/tracking.js';

export async function buildApp(): Promise<FastifyInstance> {
  // Quiet logs under the test runner; keep full logging for the dev/prod server.
  const app = Fastify({ logger: process.env.VITEST ? false : true });

  await app.register(cors, { origin: true });
  await app.register(multipart, {
    limits: { fileSize: 10 * 1024 * 1024 }, // 10 MB
  });
  await app.register(authPlugin);

  // Global error handler → { error: { code, message } }
  app.setErrorHandler((err, _req, reply) => {
    if (err instanceof ApiError) {
      return reply
        .code(err.statusCode)
        .send({ error: { code: err.code, message: err.message } });
    }
    // Fastify validation / known HTTP errors
    const maybeHttp = err as { statusCode?: number; message?: string };
    if (typeof maybeHttp.statusCode === 'number') {
      return reply
        .code(maybeHttp.statusCode)
        .send({ error: { code: 'ERROR', message: maybeHttp.message ?? 'Error' } });
    }
    app.log.error(err);
    return reply
      .code(500)
      .send({ error: { code: 'INTERNAL', message: 'Internal server error' } });
  });

  app.setNotFoundHandler((_req, reply) => {
    reply.code(404).send({ error: { code: 'NOT_FOUND', message: 'Route not found' } });
  });

  // Health check
  app.get('/health', async () => ({ ok: true }));

  // v1 API
  await app.register(authRoutes, { prefix: '/api/v1/auth' });
  await app.register(meRoutes, { prefix: '/api/v1/me' });
  await app.register(foodsRoutes, { prefix: '/api/v1/foods' });
  await app.register(scanRoutes, { prefix: '/api/v1/scan' });
  await app.register(logsRoutes, { prefix: '/api/v1/logs' });
  await app.register(trackingRoutes, { prefix: '/api/v1' });

  return app;
}
