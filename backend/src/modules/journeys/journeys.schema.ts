import { z } from 'zod';

export const journeyCategoryEnum = z.enum([
  'LEARNING_SKILL',
  'CAREER_EXAM',
  'HEALTH_FITNESS',
  'CREATIVE_WRITING',
  'BUSINESS_STARTUP',
  'OTHER',
]);

export const resourceTypeEnum = z.enum([
  'ONLINE_COURSE',
  'BOOK',
  'CERTIFICATION_MATERIAL',
  'BOOTCAMP',
  'PROJECT_SPEC',
  'COACH_MENTOR',
  'OTHER',
]);

export const commitmentDaySchema = z.object({
  dayOfWeek: z.number().int().min(1).max(7), // 1 = Monday, 7 = Sunday
  startTime: z.string().regex(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/, 'Format HH:MM required'),
  durationMinutes: z.number().int().positive().default(60),
});

export const commitmentScheduleInputSchema = z.object({
  sessionDurationMinutes: z.number().int().positive().default(60),
  preferredTime: z.string().optional(),
  days: z.array(commitmentDaySchema).min(1, 'At least one commitment day is required'),
});

export const createJourneySchema = z.object({
  title: z.string().min(3, 'Title must be at least 3 characters').max(150),
  description: z.string().max(1000).optional(),
  category: journeyCategoryEnum.default('LEARNING_SKILL'),
  resourceTitle: z.string().max(200).optional(),
  resourceType: resourceTypeEnum.default('ONLINE_COURSE'),
  resourceUrl: z.string().url().or(z.literal('')).optional(),
  startDate: z.string().datetime().or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/)),
  targetDate: z.string().datetime().or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/)),
  forceQueue: z.boolean().default(false),
  schedule: commitmentScheduleInputSchema.optional(),
});

export const updateJourneySchema = z.object({
  title: z.string().min(3).max(150).optional(),
  description: z.string().max(1000).optional(),
  resourceTitle: z.string().max(200).optional(),
  resourceType: resourceTypeEnum.optional(),
  resourceUrl: z.string().url().or(z.literal('')).optional(),
  targetDate: z.string().datetime().or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/)).optional(),
});

export const signCommitmentSchema = z.object({
  commitmentStatement: z.string().min(5, 'Commitment statement is required'),
});

export const pauseJourneySchema = z.object({
  reason: z.enum([
    'ILLNESS_OR_INJURY',
    'WORK_TRAVEL',
    'EXAMS_OR_DEADLINES',
    'FAMILY_EMERGENCY',
    'PLANNED_VACATION',
    'OTHER',
  ]),
  notes: z.string().max(500).optional(),
});

export const extendJourneySchema = z.object({
  newTargetDate: z.string().datetime().or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/)),
  reason: z.string().max(500).optional(),
});

export const completeJourneySchema = z.object({
  reflectionNotes: z.string().max(2000).optional(),
});

export type CreateJourneyInput = z.infer<typeof createJourneySchema>;
export type UpdateJourneyInput = z.infer<typeof updateJourneySchema>;
export type SignCommitmentInput = z.infer<typeof signCommitmentSchema>;
export type PauseJourneyInput = z.infer<typeof pauseJourneySchema>;
export type ExtendJourneyInput = z.infer<typeof extendJourneySchema>;
export type CompleteJourneyInput = z.infer<typeof completeJourneySchema>;
