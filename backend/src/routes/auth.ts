import type { FastifyPluginAsync } from 'fastify';
import bcrypt from 'bcryptjs';
import { z } from 'zod';
import { prisma } from '../prisma.js';
import { Errors } from '../errors.js';
import { parseOrThrow } from '../lib/validate.js';
import { serializeUser } from '../lib/serializers.js';

const registerSchema = z.object({
  email: z.string().email().transform((s) => s.toLowerCase().trim()),
  password: z.string().min(8, 'password must be at least 8 chars'),
  name: z.string().min(1),
});

const loginSchema = z.object({
  email: z.string().email().transform((s) => s.toLowerCase().trim()),
  password: z.string().min(1),
});

const authRoutes: FastifyPluginAsync = async (fastify) => {
  fastify.post('/register', async (req, reply) => {
    const body = parseOrThrow(registerSchema, req.body);

    const existing = await prisma.user.findUnique({ where: { email: body.email } });
    if (existing) throw Errors.emailTaken();

    const passwordHash = await bcrypt.hash(body.password, 10);
    const user = await prisma.user.create({
      data: { email: body.email, passwordHash, name: body.name },
    });

    const token = fastify.jwt.sign({ id: user.id, email: user.email, tier: user.tier });
    return reply.code(201).send({ token, user: serializeUser(user) });
  });

  fastify.post('/login', async (req, reply) => {
    const body = parseOrThrow(loginSchema, req.body);

    const user = await prisma.user.findUnique({ where: { email: body.email } });
    if (!user) throw Errors.invalidCredentials();

    const ok = await bcrypt.compare(body.password, user.passwordHash);
    if (!ok) throw Errors.invalidCredentials();

    const token = fastify.jwt.sign({ id: user.id, email: user.email, tier: user.tier });
    return reply.code(200).send({ token, user: serializeUser(user) });
  });
};

export default authRoutes;
