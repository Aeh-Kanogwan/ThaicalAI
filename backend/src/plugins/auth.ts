import fp from 'fastify-plugin';
import fastifyJwt from '@fastify/jwt';
import type { FastifyPluginAsync, FastifyRequest, FastifyReply } from 'fastify';
import { config } from '../config.js';
import { Errors } from '../errors.js';

// JWT payload shape.
export interface AuthUser {
  id: string;
  email: string;
  tier: 'free' | 'vip';
}

declare module 'fastify' {
  interface FastifyInstance {
    authenticate: (req: FastifyRequest, reply: FastifyReply) => Promise<void>;
  }
  interface FastifyRequest {
    authUser: AuthUser;
  }
}

declare module '@fastify/jwt' {
  interface FastifyJWT {
    payload: AuthUser;
    user: AuthUser;
  }
}

const authPlugin: FastifyPluginAsync = async (fastify) => {
  await fastify.register(fastifyJwt, { secret: config.jwtSecret });

  // Preferred as a route preHandler: `preHandler: [fastify.authenticate]`.
  fastify.decorate(
    'authenticate',
    async (req: FastifyRequest, _reply: FastifyReply) => {
      try {
        await req.jwtVerify();
        req.authUser = req.user;
      } catch {
        throw Errors.unauthorized();
      }
    },
  );
};

export default fp(authPlugin);
