import { Request, Response, NextFunction } from 'express';
import { AppError, ValidationError } from '../common/errors/app-error';
import { logger } from '../common/logger';
import { config } from '../config';

export function errorHandler(
  err: any,
  req: Request,
  res: Response,
  _next: NextFunction
): void {
  // Operational errors
  if (err instanceof ValidationError) {
    res.status(err.statusCode).json({
      success: false,
      error: {
        code: err.code || 'VALIDATION_ERROR',
        message: err.message,
        details: err.details,
      },
    });
    return;
  }

  if (err instanceof AppError) {
    res.status(err.statusCode).json({
      success: false,
      error: {
        code: err.code || 'APP_ERROR',
        message: err.message,
      },
    });
    return;
  }

  // Prisma Known Request Errors
  if (err.code === 'P2002') {
    const target = err.meta?.target || 'field';
    res.status(409).json({
      success: false,
      error: {
        code: 'CONFLICT',
        message: `A resource with that ${Array.isArray(target) ? target.join(', ') : target} already exists.`,
      },
    });
    return;
  }

  if (err.code === 'P2025') {
    res.status(404).json({
      success: false,
      error: {
        code: 'NOT_FOUND',
        message: 'The requested resource was not found.',
      },
    });
    return;
  }

  // SyntaxError from body-parser
  if (err instanceof SyntaxError && 'body' in err) {
    res.status(400).json({
      success: false,
      error: {
        code: 'INVALID_JSON',
        message: 'Malformed JSON payload in request body.',
      },
    });
    return;
  }

  // Unhandled / 500 errors
  logger.error(`Unhandled error on ${req.method} ${req.originalUrl}:`, err);

  res.status(500).json({
    success: false,
    error: {
      code: 'INTERNAL_SERVER_ERROR',
      message:
        config.NODE_ENV === 'production'
          ? 'An unexpected error occurred. Please try again later.'
          : err.message || 'Internal server error',
      ...(config.NODE_ENV !== 'production' && { stack: err.stack }),
    },
  });
}
