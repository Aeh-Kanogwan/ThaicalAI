import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { prisma } from '../prisma.js';
import { Errors } from '../errors.js';
import { parseOrThrow } from '../lib/validate.js';
import { serializeFood } from '../lib/serializers.js';
import { getVisionProvider, type VisionInput } from '../services/vision/index.js';
import { matchFoodByLabel } from '../services/foodMatch.js';
import { getQuota, hasQuotaRemaining } from '../services/quota.js';

const base64Schema = z.object({
  imageBase64: z.string().min(1),
  mimeType: z.string().optional(),
});

const scanRoutes: FastifyPluginAsync = async (fastify) => {
  fastify.addHook('preHandler', fastify.authenticate);

  // GET /scan/quota → { used, limit, resetAt, tier }
  fastify.get('/quota', async (req) => {
    const q = await getQuota(req.authUser.id, req.authUser.tier);
    return { used: q.used, limit: q.limit, resetAt: q.resetAt, tier: q.tier };
  });

  // POST /scan — multipart `image` OR JSON { imageBase64 }
  fastify.post('/', async (req, reply) => {
    const userId = req.authUser.id;

    // 1) Enforce quota BEFORE calling the (paid) vision provider.
    const quotaBefore = await getQuota(userId, req.authUser.tier);
    if (!hasQuotaRemaining(quotaBefore)) {
      throw Errors.quotaExceeded(
        req.authUser.tier === 'free'
          ? 'Free trial scans exhausted. Upgrade to VIP.'
          : 'Daily scan limit reached. Try again tomorrow.',
      );
    }

    // 2) Extract image from multipart or JSON body.
    const input: VisionInput = {};
    if (req.isMultipart()) {
      const file = await req.file();
      if (!file || file.fieldname !== 'image') {
        throw Errors.badRequest('multipart field `image` is required');
      }
      input.imageBuffer = await file.toBuffer();
      input.mimeType = file.mimetype;
    } else {
      const body = parseOrThrow(base64Schema, req.body);
      input.imageBase64 = body.imageBase64.replace(/^data:[^;]+;base64,/, '');
      input.mimeType = body.mimeType;
    }

    // 3) Call vision provider.
    const provider = getVisionProvider();
    const result = await provider.detect(input);

    // 4) Match each detected label against the foods DB.
    const items = await Promise.all(
      result.items.map(async (it) => {
        const food = await matchFoodByLabel(it.label);
        return {
          label: it.label,
          confidence: it.confidence,
          estimatedPortion: it.estimatedPortion,
          matchedFood: food ? serializeFood(food) : null,
          grams: it.grams,
        };
      }),
    );

    // 5) Record the scan (counts against quota) and return updated quota.
    const record = await prisma.scanRecord.create({ data: { userId } });
    const quotaAfter = await getQuota(userId, req.authUser.tier);

    return reply.code(200).send({
      scanId: record.id,
      confidence: result.confidence,
      items,
      quota: {
        used: quotaAfter.used,
        limit: quotaAfter.limit,
        resetAt: quotaAfter.resetAt,
      },
    });
  });
};

export default scanRoutes;
