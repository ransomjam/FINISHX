import dotenv from 'dotenv';
import { z } from 'zod';

// Load .env in non-production environments
if (process.env.NODE_ENV !== 'production') {
  dotenv.config();
}

const envSchema = z.object({
  NODE_ENV: z
    .enum(['development', 'test', 'production'])
    .default('development'),
  PORT: z
    .string()
    .default('10000')
    .transform((val) => parseInt(val, 10)),
  HOST: z.string().default('0.0.0.0'),

  // Neon PostgreSQL connection strings
  DATABASE_URL: z.string().min(1, 'DATABASE_URL is required'),
  DIRECT_URL: z.string().optional(),

  // JWT configuration
  JWT_ACCESS_SECRET: z.string().min(16, 'JWT_ACCESS_SECRET must be at least 16 chars'),
  JWT_REFRESH_SECRET: z.string().min(16, 'JWT_REFRESH_SECRET must be at least 16 chars'),
  JWT_ACCESS_EXPIRES_IN: z.string().default('15m'),
  JWT_REFRESH_EXPIRES_IN: z.string().default('30d'),

  // CORS and URL
  CORS_ALLOWED_ORIGINS: z.string().default('*'),
  APP_BASE_URL: z.string().default('http://localhost:10000'),

  // Firebase Cloud Messaging (optional in dev, required in prod for push notifications)
  FIREBASE_PROJECT_ID: z.string().optional(),
  FIREBASE_CLIENT_EMAIL: z.string().optional(),
  FIREBASE_PRIVATE_KEY: z.string().optional(),

  // SMTP Settings
  SMTP_HOST: z.string().optional(),
  SMTP_PORT: z
    .string()
    .optional()
    .transform((val) => (val ? parseInt(val, 10) : 587)),
  SMTP_USER: z.string().optional(),
  SMTP_PASSWORD: z.string().optional(),
  SMTP_FROM: z.string().default('FinishX <no-reply@finishx.app>'),

  LOG_LEVEL: z.enum(['debug', 'info', 'warn', 'error']).default('info'),
});

const parseResult = envSchema.safeParse(process.env);

if (!parseResult.success) {
  const issues = parseResult.error.issues.map((i) => ` - ${i.path.join('.')}: ${i.message}`).join('\n');
  console.error(`\x1b[31m[Config Error] Invalid environment configuration:\n${issues}\x1b[0m`);
  if (process.env.NODE_ENV === 'production') {
    process.exit(1);
  }
}

export const config = parseResult.success
  ? parseResult.data
  : (envSchema.parse({
      ...process.env,
      DATABASE_URL: process.env.DATABASE_URL || 'postgresql://postgres:postgres@localhost:5432/finishx?schema=public',
      JWT_ACCESS_SECRET: process.env.JWT_ACCESS_SECRET || 'dev_access_secret_super_secure_32_chars_long',
      JWT_REFRESH_SECRET: process.env.JWT_REFRESH_SECRET || 'dev_refresh_secret_super_secure_32_chars_long',
    }));
