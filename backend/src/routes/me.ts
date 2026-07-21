import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { prisma } from '../prisma.js';
import { Errors } from '../errors.js';
import { parseOrThrow } from '../lib/validate.js';
import { serializeUser } from '../lib/serializers.js';
import { computeDailyGoal } from '../lib/nutrition.js';

const profileSchema = z.object({
  sex: z.enum(['male', 'female']),
  age: z.number().int().min(1).max(120),
  heightCm: z.number().min(50).max(300),
  weightKg: z.number().min(20).max(500),
  activityLevel: z.enum(['sedentary', 'light', 'moderate', 'active', 'very_active']),
  goal: z.enum(['lose', 'maintain', 'gain']),
});

function serializeProfile(p: NonNullable<Awaited<ReturnType<typeof prisma.profile.findUnique>>>) {
  return {
    sex: p.sex,
    age: p.age,
    heightCm: p.heightCm,
    weightKg: p.weightKg,
    activityLevel: p.activityLevel,
    goal: p.goal,
  };
}

const meRoutes: FastifyPluginAsync = async (fastify) => {
  fastify.addHook('preHandler', fastify.authenticate);

  // GET /me → { user, profile, dailyGoal }
  fastify.get('/', async (req) => {
    const user = await prisma.user.findUnique({
      where: { id: req.authUser.id },
      include: { profile: true },
    });
    if (!user) throw Errors.notFound('User not found');

    const dailyGoal = user.profile ? computeDailyGoal(user.profile) : null;
    return {
      user: serializeUser(user),
      profile: user.profile ? serializeProfile(user.profile) : null,
      dailyGoal,
    };
  });

  // PUT /me/profile → { profile, dailyGoal }
  fastify.put('/profile', async (req) => {
    const body = parseOrThrow(profileSchema, req.body);
    const userId = req.authUser.id;

    const profile = await prisma.profile.upsert({
      where: { userId },
      create: { userId, ...body },
      update: { ...body },
    });

    const dailyGoal = computeDailyGoal(profile);
    return { profile: serializeProfile(profile), dailyGoal };
  });
};

export default meRoutes;
