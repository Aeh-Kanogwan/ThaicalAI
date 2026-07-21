import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { prisma } from '../prisma.js';
import { Errors } from '../errors.js';
import { parseOrThrow } from '../lib/validate.js';
import { serializeMealLog } from '../lib/serializers.js';
import { computeDailyGoal } from '../lib/nutrition.js';
import { dayRange } from '../lib/dates.js';

const createSchema = z
  .object({
    foodId: z.string().nullable().optional(),
    customName: z.string().nullable().optional(),
    mealType: z.enum(['breakfast', 'lunch', 'dinner', 'snack']),
    grams: z.number().positive(),
    calories: z.number().int().min(0),
    protein: z.number().min(0),
    carbs: z.number().min(0),
    fat: z.number().min(0),
    sodium: z.number().min(0).nullable().optional(),
    scanId: z.string().nullable().optional(),
    loggedAt: z.string().datetime().optional(),
  })
  .refine((b) => b.foodId || b.customName, {
    message: 'either foodId or customName is required',
  });

const listSchema = z.object({
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'date must be YYYY-MM-DD'),
});

// Resolve a MealLog display name: customName, else linked food nameTh, else fallback.
async function resolveName(foodId: string | null, customName: string | null): Promise<string> {
  if (customName) return customName;
  if (foodId) {
    const food = await prisma.food.findUnique({ where: { id: foodId } });
    if (food) return food.nameTh;
  }
  return 'อาหาร';
}

const logsRoutes: FastifyPluginAsync = async (fastify) => {
  fastify.addHook('preHandler', fastify.authenticate);

  // POST /logs → 201 { log }
  fastify.post('/', async (req, reply) => {
    const body = parseOrThrow(createSchema, req.body);
    const userId = req.authUser.id;

    if (body.foodId) {
      const food = await prisma.food.findUnique({ where: { id: body.foodId } });
      if (!food) throw Errors.notFound('foodId does not exist');
    }

    const log = await prisma.mealLog.create({
      data: {
        userId,
        foodId: body.foodId ?? null,
        customName: body.customName ?? null,
        mealType: body.mealType,
        grams: body.grams,
        calories: body.calories,
        protein: body.protein,
        carbs: body.carbs,
        fat: body.fat,
        sodium: body.sodium ?? null,
        scanId: body.scanId ?? null,
        loggedAt: body.loggedAt ? new Date(body.loggedAt) : undefined,
      },
    });

    const name = await resolveName(log.foodId, log.customName);
    return reply.code(201).send({ log: serializeMealLog(log, name) });
  });

  // GET /logs?date=YYYY-MM-DD → { date, summary, logs }
  fastify.get('/', async (req) => {
    const { date } = parseOrThrow(listSchema, req.query);
    const userId = req.authUser.id;
    const { start, end } = dayRange(date);

    const logs = await prisma.mealLog.findMany({
      where: { userId, loggedAt: { gte: start, lt: end } },
      orderBy: { loggedAt: 'asc' },
      include: { food: true },
    });

    const summary = logs.reduce(
      (acc, l) => {
        acc.calories += l.calories;
        acc.protein += l.protein;
        acc.carbs += l.carbs;
        acc.fat += l.fat;
        acc.sodium += l.sodium ?? 0;
        return acc;
      },
      { calories: 0, protein: 0, carbs: 0, fat: 0, sodium: 0 },
    );

    const profile = await prisma.profile.findUnique({ where: { userId } });
    const target = profile ? computeDailyGoal(profile) : null;

    return {
      date,
      summary: {
        calories: summary.calories,
        protein: Math.round(summary.protein * 10) / 10,
        carbs: Math.round(summary.carbs * 10) / 10,
        fat: Math.round(summary.fat * 10) / 10,
        sodium: Math.round(summary.sodium * 10) / 10,
        target,
      },
      logs: logs.map((l) =>
        serializeMealLog(l, l.customName ?? l.food?.nameTh ?? 'อาหาร'),
      ),
    };
  });

  // DELETE /logs/:id → 204
  fastify.delete<{ Params: { id: string } }>('/:id', async (req, reply) => {
    const userId = req.authUser.id;
    const existing = await prisma.mealLog.findUnique({ where: { id: req.params.id } });
    if (!existing || existing.userId !== userId) throw Errors.notFound('Log not found');

    await prisma.mealLog.delete({ where: { id: req.params.id } });
    return reply.code(204).send();
  });
};

export default logsRoutes;
