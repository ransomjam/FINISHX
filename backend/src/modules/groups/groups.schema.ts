import { z } from 'zod';

export const reactionTypeEnum = z.enum([
  'THUMBS_UP',
  'FIRE',
  'APPLAUD',
  'CELEBRATE',
  'HEART',
]);

export const addReactionSchema = z.object({
  reactionType: reactionTypeEnum.default('FIRE'),
});

export type AddReactionInput = z.infer<typeof addReactionSchema>;
