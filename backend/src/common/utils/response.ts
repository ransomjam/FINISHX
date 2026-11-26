import { Response } from 'express';

export interface ApiResponse<T = any> {
  success: boolean;
  message?: string;
  data?: T;
  error?: {
    code?: string;
    message: string;
    details?: any;
  };
  meta?: Record<string, any>;
}

export function sendSuccess<T>(
  res: Response,
  data?: T,
  message?: string,
  statusCode = 200,
  meta?: Record<string, any>
): Response {
  const response: ApiResponse<T> = {
    success: true,
    ...(message ? { message } : {}),
    ...(data !== undefined ? { data } : {}),
    ...(meta ? { meta } : {}),
  };
  return res.status(statusCode).json(response);
}

export function sendCreated<T>(
  res: Response,
  data?: T,
  message = 'Resource created successfully',
  meta?: Record<string, any>
): Response {
  return sendSuccess(res, data, message, 201, meta);
}

export function sendNoContent(res: Response): Response {
  return res.status(204).send();
}
