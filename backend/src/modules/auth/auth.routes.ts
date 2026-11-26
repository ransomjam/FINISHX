import { Router } from 'express';
import { authController } from './auth.controller';
import { validateBody } from '../../middleware/validate';
import { authenticate } from '../../middleware/authenticate';
import { authRateLimiter } from '../../middleware/rate-limiter';
import {
  registerSchema,
  loginSchema,
  refreshTokenSchema,
  googleAuthSchema,
} from './auth.schema';

export const authRouter = Router();

authRouter.post(
  '/register',
  authRateLimiter,
  validateBody(registerSchema),
  authController.register
);

authRouter.post(
  '/login',
  authRateLimiter,
  validateBody(loginSchema),
  authController.login
);

authRouter.post(
  '/refresh',
  validateBody(refreshTokenSchema),
  authController.refreshToken
);

authRouter.post(
  '/google',
  authRateLimiter,
  validateBody(googleAuthSchema),
  authController.googleAuth
);

authRouter.post(
  '/logout',
  authenticate,
  authController.logout
);

authRouter.get(
  '/me',
  authenticate,
  authController.me
);
