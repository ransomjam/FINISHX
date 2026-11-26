import { config } from '../config';

type LogLevel = 'debug' | 'info' | 'warn' | 'error';

const LEVEL_PRIORITIES: Record<LogLevel, number> = {
  debug: 0,
  info: 1,
  warn: 2,
  error: 3,
};

class Logger {
  private currentPriority: number;

  constructor() {
    this.currentPriority = LEVEL_PRIORITIES[config.LOG_LEVEL] ?? 1;
  }

  private formatMessage(level: LogLevel, message: string, meta?: any): string {
    const timestamp = new Date().toISOString();
    const metaStr = meta ? ` ${typeof meta === 'object' ? JSON.stringify(meta) : meta}` : '';
    return `[${timestamp}] [${level.toUpperCase()}] ${message}${metaStr}`;
  }

  debug(message: string, meta?: any): void {
    if (this.currentPriority <= LEVEL_PRIORITIES.debug) {
      console.debug(this.formatMessage('debug', message, meta));
    }
  }

  info(message: string, meta?: any): void {
    if (this.currentPriority <= LEVEL_PRIORITIES.info) {
      console.log(this.formatMessage('info', message, meta));
    }
  }

  warn(message: string, meta?: any): void {
    if (this.currentPriority <= LEVEL_PRIORITIES.warn) {
      console.warn(this.formatMessage('warn', message, meta));
    }
  }

  error(message: string, error?: any): void {
    if (this.currentPriority <= LEVEL_PRIORITIES.error) {
      const errorDetails = error instanceof Error
        ? { message: error.message, stack: config.NODE_ENV !== 'production' ? error.stack : undefined }
        : error;
      console.error(this.formatMessage('error', message, errorDetails));
    }
  }
}

export const logger = new Logger();
