import { Router } from 'express';
import { reflectionsController } from './reflections.controller';
import { authenticate } from '../../middleware/authenticate';
import { validateBody } from '../../middleware/validate';
import { submitWeeklyReflectionSchema } from './reflections.schema';

export const reflectionsRouter = Router();

reflectionsRouter.use(authenticate);

reflectionsRouter.post(
  '/',
  validateBody(submitWeeklyReflectionSchema),
  reflectionsController.submit
);

reflectionsRouter.get(
  '/journey/:journeyId',
  reflectionsController.listForJourney
);
