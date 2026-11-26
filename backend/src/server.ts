import { app } from './app';
import { config } from './config';
import { logger } from './common/logger';
import { disconnectPrisma } from './database/prisma';

const server = app.listen(config.PORT, config.HOST, () => {
  logger.info(`=======================================================`);
  logger.info(`FinishX API Server running on http://${config.HOST}:${config.PORT}`);
  logger.info(`Environment: ${config.NODE_ENV}`);
  logger.info(`API v1 Base: http://${config.HOST}:${config.PORT}/api/v1`);
  logger.info(`Swagger Docs: http://${config.HOST}:${config.PORT}/api/v1/docs`);
  logger.info(`Health Check: http://${config.HOST}:${config.PORT}/health/ready`);
  logger.info(`=======================================================`);
});

// Graceful Shutdown handling for Render and container lifecycles
let isShuttingDown = false;

async function handleShutdown(signal: string) {
  if (isShuttingDown) return;
  isShuttingDown = true;

  logger.info(`Received ${signal}. Starting graceful shutdown...`);

  // Stop accepting new connections
  server.close(async () => {
    logger.info('HTTP server closed. Disconnecting database...');
    try {
      await disconnectPrisma();
      logger.info('Graceful shutdown completed successfully.');
      process.exit(0);
    } catch (err) {
      logger.error('Error during database disconnection:', err);
      process.exit(1);
    }
  });

  // Force shutdown after 30 seconds if still hanging
  setTimeout(() => {
    logger.error('Forced shutdown after 30s timeout.');
    process.exit(1);
  }, 30000);
}

process.on('SIGTERM', () => handleShutdown('SIGTERM'));
process.on('SIGINT', () => handleShutdown('SIGINT'));
