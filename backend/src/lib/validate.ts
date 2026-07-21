import type { ZodTypeAny, z } from 'zod';
import { Errors } from '../errors.js';

// Parse an unknown body/query with a Zod schema; throw a 400 ApiError on failure.
export function parseOrThrow<T extends ZodTypeAny>(
  schema: T,
  data: unknown,
): z.infer<T> {
  const result = schema.safeParse(data);
  if (!result.success) {
    const first = result.error.issues[0];
    const path = first?.path.join('.') || 'body';
    throw Errors.validation(`${path}: ${first?.message ?? 'invalid'}`);
  }
  return result.data;
}
