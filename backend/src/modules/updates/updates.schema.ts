import { z } from 'zod';

export const createUpdateSchema = z.object({
  journeyId: z.string().uuid(),
  content: z.string().min(1, 'Update content is required').max(2000),
  milestoneTitle: z.string().max(200).optional(),
});

export type CreateUpdateInput = z.infer<typeof createUpdateSchema>;
