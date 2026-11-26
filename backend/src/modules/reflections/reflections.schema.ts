import { z } from 'zod';

export const weeklyAnswerEnum = z.enum(['YES', 'PARTIALLY', 'NO']);

export const submitWeeklyReflectionSchema = z.object({
  journeyId: z.string().uuid(),
  completedCommitments: weeklyAnswerEnum,
  biggestWin: z.string().min(2, 'Please enter your biggest win').max(1000),
  biggestChallenge: z.string().min(2, 'Please share your biggest challenge').max(1000),
  nextWeekFocus: z.string().min(2, 'Please outline your next week focus').max(1000),
  weekNumber: z.number().int().positive().optional(),
});

export type SubmitWeeklyReflectionInput = z.infer<typeof submitWeeklyReflectionSchema>;
