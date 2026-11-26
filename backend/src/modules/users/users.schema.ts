import { z } from 'zod';

export const updateProfileSchema = z.object({
  fullName: z.string().min(2).max(100).trim().optional(),
  timezone: z.string().min(1).optional(),
  avatarUrl: z.string().url().nullable().optional(),
});

export const updateTimezoneSchema = z.object({
  timezone: z.string().min(1, 'Timezone is required'),
});

export type UpdateProfileInput = z.infer<typeof updateProfileSchema>;
export type UpdateTimezoneInput = z.infer<typeof updateTimezoneSchema>;
