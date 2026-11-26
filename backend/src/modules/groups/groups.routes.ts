import { Router } from 'express';
import { groupsController } from './groups.controller';
import { authenticate } from '../../middleware/authenticate';
import { validateBody } from '../../middleware/validate';
import { addReactionSchema } from './groups.schema';

export const groupsRouter = Router();

groupsRouter.use(authenticate);

groupsRouter.get('/:id', groupsController.getDetails);
groupsRouter.post(
  '/activities/:activityId/react',
  validateBody(addReactionSchema),
  groupsController.addReaction
);
