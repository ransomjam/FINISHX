import { Pool, neonConfig } from '@neondatabase/serverless';
import { PrismaNeon } from '@prisma/adapter-neon';
import { PrismaClient } from '@prisma/client';
import ws from 'ws';
import { config } from '../config';
import { logger } from '../common/logger';

// Configure WebSocket constructor for Node.js server environment
neonConfig.webSocketConstructor = ws;

let prismaInstance: PrismaClient | null = null;

export function getPrismaClient(): PrismaClient {
  if (!prismaInstance) {
    const isNeon =
      config.DATABASE_URL.includes('neon.tech') ||
      config.DATABASE_URL.includes('pooler') ||
      config.DATABASE_URL.includes('sslmode=require');

    if (isNeon) {
      try {
        const pool = new Pool({ connectionString: config.DATABASE_URL });
        const adapter = new PrismaNeon(pool);
        prismaInstance = new PrismaClient({
          adapter,
          log: config.NODE_ENV === 'development' ? ['error', 'warn'] : ['error'],
        });
        logger.info('Initialized Prisma Client with Neon Serverless adapter');
      } catch (err) {
        logger.warn('Failed to initialize Neon adapter, falling back to standard PrismaClient', err);
        prismaInstance = new PrismaClient({
          datasources: { db: { url: config.DATABASE_URL } },
          log: config.NODE_ENV === 'development' ? ['error', 'warn'] : ['error'],
        });
      }
    } else {
      prismaInstance = new PrismaClient({
        datasources: { db: { url: config.DATABASE_URL } },
        log: config.NODE_ENV === 'development' ? ['error', 'warn'] : ['error'],
      });
      logger.info('Initialized standard Prisma Client');
    }
  }

  return prismaInstance;
}

export const prisma = getPrismaClient();

export async function checkDatabaseConnection(): Promise<boolean> {
  try {
    await prisma.$queryRaw`SELECT 1`;
    return true;
  } catch (error) {
    logger.error('Database connection check failed:', error);
    return false;
  }
}

export async function disconnectPrisma(): Promise<void> {
  if (prismaInstance) {
    await prismaInstance.$disconnect();
    prismaInstance = null;
    logger.info('Prisma Client disconnected');
  }
}
