import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { prisma } from '../prisma.js';
import { Errors } from '../errors.js';
import { parseOrThrow } from '../lib/validate.js';
import { serializeFood } from '../lib/serializers.js';

const searchSchema = z.object({
  q: z.string().min(1, 'q is required'),
  limit: z.coerce.number().int().min(1).max(50).default(20),
});

const foodsRoutes: FastifyPluginAsync = async (fastify) => {
  fastify.addHook('preHandler', fastify.authenticate);

  // GET /foods/search?q=&limit= → matches nameTh, nameEn, keywords (case-insensitive)
  fastify.get('/search', async (req) => {
    const { q, limit } = parseOrThrow(searchSchema, req.query);

    const items = await prisma.food.findMany({
      where: {
        OR: [
          { nameTh: { contains: q, mode: 'insensitive' } },
          { nameEn: { contains: q, mode: 'insensitive' } },
          { keywords: { has: q } },
          { keywords: { hasSome: q.split(/\s+/).filter(Boolean) } },
        ],
      },
      take: limit,
      orderBy: { nameTh: 'asc' },
    });

    return { items: items.map(serializeFood) };
  });

  // GET /foods/:id → { food }
  fastify.get<{ Params: { id: string } }>('/:id', async (req) => {
    const food = await prisma.food.findUnique({ where: { id: req.params.id } });
    if (!food) throw Errors.notFound('Food not found');
    return { food: serializeFood(food) };
  });
};

export default foodsRoutes;
