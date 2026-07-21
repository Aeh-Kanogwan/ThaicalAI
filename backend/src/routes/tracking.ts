import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { prisma } from '../prisma.js';
import { parseOrThrow } from '../lib/validate.js';
import { dayRange } from '../lib/dates.js';

const waterCreate = z.object({
  ml: z.number().int().positive(),
  loggedAt: z.string().datetime().optional(),
});
const exerciseCreate = z.object({
  name: z.string().min(1),
  minutes: z.number().int().positive(),
  caloriesBurned: z.number().int().min(0),
  loggedAt: z.string().datetime().optional(),
});
const weightCreate = z.object({
  weightKg: z.number().positive(),
  photoUrl: z.string().url().nullable().optional(),
  loggedAt: z.string().datetime().optional(),
});

const dateQuery = z.object({
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'date must be YYYY-MM-DD'),
});
const rangeQuery = z.object({
  from: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  to: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
});

const trackingRoutes: FastifyPluginAsync = async (fastify) => {
  fastify.addHook('preHandler', fastify.authenticate);

  // ---- Water ----
  fastify.post('/water', async (req, reply) => {
    const body = parseOrThrow(waterCreate, req.body);
    const entry = await prisma.waterEntry.create({
      data: {
        userId: req.authUser.id,
        ml: body.ml,
        loggedAt: body.loggedAt ? new Date(body.loggedAt) : undefined,
      },
    });
    return reply.code(201).send({
      entry: { id: entry.id, ml: entry.ml, loggedAt: entry.loggedAt.toISOString() },
    });
  });

  fastify.get('/water', async (req) => {
    const { date } = parseOrThrow(dateQuery, req.query);
    const { start, end } = dayRange(date);
    const entries = await prisma.waterEntry.findMany({
      where: { userId: req.authUser.id, loggedAt: { gte: start, lt: end } },
      orderBy: { loggedAt: 'asc' },
    });
    const totalMl = entries.reduce((s, e) => s + e.ml, 0);
    return {
      totalMl,
      entries: entries.map((e) => ({
        id: e.id,
        ml: e.ml,
        loggedAt: e.loggedAt.toISOString(),
      })),
    };
  });

  // ---- Exercise ----
  fastify.post('/exercise', async (req, reply) => {
    const body = parseOrThrow(exerciseCreate, req.body);
    const entry = await prisma.exerciseEntry.create({
      data: {
        userId: req.authUser.id,
        name: body.name,
        minutes: body.minutes,
        caloriesBurned: body.caloriesBurned,
        loggedAt: body.loggedAt ? new Date(body.loggedAt) : undefined,
      },
    });
    return reply.code(201).send({
      entry: {
        id: entry.id,
        name: entry.name,
        minutes: entry.minutes,
        caloriesBurned: entry.caloriesBurned,
        loggedAt: entry.loggedAt.toISOString(),
      },
    });
  });

  // ---- Weight ----
  fastify.post('/weight', async (req, reply) => {
    const body = parseOrThrow(weightCreate, req.body);
    const entry = await prisma.weightEntry.create({
      data: {
        userId: req.authUser.id,
        weightKg: body.weightKg,
        photoUrl: body.photoUrl ?? null,
        loggedAt: body.loggedAt ? new Date(body.loggedAt) : undefined,
      },
    });
    return reply.code(201).send({
      entry: {
        id: entry.id,
        weightKg: entry.weightKg,
        photoUrl: entry.photoUrl,
        loggedAt: entry.loggedAt.toISOString(),
      },
    });
  });

  fastify.get('/weight', async (req) => {
    const { from, to } = parseOrThrow(rangeQuery, req.query);
    const where: Record<string, unknown> = { userId: req.authUser.id };
    if (from || to) {
      const range: { gte?: Date; lt?: Date } = {};
      if (from) range.gte = dayRange(from).start;
      if (to) range.lt = dayRange(to).end;
      where.loggedAt = range;
    }
    const entries = await prisma.weightEntry.findMany({
      where,
      orderBy: { loggedAt: 'asc' },
    });
    return {
      entries: entries.map((e) => ({
        id: e.id,
        weightKg: e.weightKg,
        photoUrl: e.photoUrl,
        loggedAt: e.loggedAt.toISOString(),
      })),
    };
  });
};

export default trackingRoutes;
