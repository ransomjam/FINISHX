import { Router } from 'express';
import { journeysController } from './journeys.controller';
import { authenticate } from '../../middleware/authenticate';
import { validateBody } from '../../middleware/validate';
import {
  createJourneySchema,
  signCommitmentSchema,
  pauseJourneySchema,
  extendJourneySchema,
  completeJourneySchema,
} from './journeys.schema';

export const journeysRouter = Router();

journeysRouter.use(authenticate);

journeysRouter.post('/', validateBody(createJourneySchema), journeysController.createJourney);
journeysRouter.get('/active', journeysController.getActiveJourney);
journeysRouter.get('/queue', journeysController.getQueuedJourneys);
journeysRouter.get('/:id', journeysController.getJourneyById);

journeysRouter.post(
  '/:id/sign',
  validateBody(signCommitmentSchema),
  journeysController.signCommitment
);

journeysRouter.post(
  '/:id/pause',
  validateBody(pauseJourneySchema),
  journeysController.pauseJourney
);

journeysRouter.post('/:id/resume', journeysController.resumeJourney);

journeysRouter.post(
  '/:id/extend',
  validateBody(extendJourneySchema),
  journeysController.extendJourney
);

journeysRouter.post(
  '/:id/complete',
  validateBody(completeJourneySchema),
  journeysController.completeJourney
);

journeysRouter.post('/:id/cancel', journeysController.cancelJourney);
