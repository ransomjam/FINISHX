import { z } from 'zod';

export const syncEventInputSchema = z.object({
  id: z.string().uuid(),
  eventType: z.string().min(1),
  payload: z.record(z.any()),
  clientTimestamp: z.string().datetime(),
  deviceId: z.string().optional(),
});

export const syncBatchSchema = z.object({
  events: z.array(syncEventInputSchema).max(100, 'Maximum 100 events per batch'),
});

export type SyncEventInput = z.infer<typeof syncEventInputSchema>;
export type SyncBatchInput = z.infer<typeof syncBatchSchema>;
