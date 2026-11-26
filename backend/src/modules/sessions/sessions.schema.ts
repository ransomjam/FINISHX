import { z } from 'zod';

export const sessionFeelingEnum = z.enum([
  'ENERGIZED',
  'FOCUSED',
  'NEUTRAL',
  'TIRED',
  'DISTRACTED',
]);

export const startSessionSchema = z.object({
  startedAt: z.string().datetime().optional(),
});

export const endSessionSchema = z.object({
  actualDurationMinutes: z.number().int().min(1, 'Duration must be at least 1 minute'),
  completedAt: z.string().datetime().optional(),
  feeling: sessionFeelingEnum.optional(),
  rating: z.number().int().min(1).max(5).optional(),
  notes: z.string().max(1000).optional(),
  distractionsLevel: z.number().int().min(1).max(5).optional(),
});

export const reflectSessionSchema = z.object({
  feeling: sessionFeelingEnum.default('FOCUSED'),
  rating: z.number().int().min(1).max(5).default(4),
  notes: z.string().max(1000).optional(),
  distractionsLevel: z.number().int().min(1).max(5).default(1),
});

export const skipSessionSchema = z.object({
  reason: z.string().max(500).optional(),
});

export const listSessionsQuerySchema = z.object({
  journeyId: z.string().uuid().optional(),
  status: z.enum(['SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'MISSED', 'SKIPPED']).optional(),
  from: z.string().datetime().or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/)).optional(),
  to: z.string().datetime().or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/)).optional(),
  limit: z.string().optional().transform((v) => (v ? parseInt(v, 10) : 20)),
  page: z.string().optional().transform((v) => (v ? parseInt(v, 10) : 1)),
});

export type StartSessionInput = z.infer<typeof startSessionSchema>;
export type EndSessionInput = z.infer<typeof endSessionSchema>;
export type ReflectSessionInput = z.infer<typeof reflectSessionSchema>;
export type SkipSessionInput = z.infer<typeof skipSessionSchema>;
export type ListSessionsQuery = z.infer<typeof listSessionsQuerySchema>;
