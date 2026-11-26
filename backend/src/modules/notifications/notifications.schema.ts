import { z } from 'zod';

export const registerDeviceSchema = z.object({
  token: z.string().min(1, 'Device token is required'),
  platform: z.enum(['ANDROID', 'IOS', 'WEB']).default('ANDROID'),
  appVersion: z.string().optional(),
});

export type RegisterDeviceInput = z.infer<typeof registerDeviceSchema>;
