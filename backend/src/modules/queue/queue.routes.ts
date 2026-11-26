import { Router } from 'express';
import { queueController } from './queue.controller';
import { authenticate } from '../../middleware/authenticate';

export const queueRouter = Router();

queueRouter.use(authenticate);

queueRouter.get('/', queueController.getQueue);
queueRouter.post('/:id/promote', queueController.promote);
queueRouter.delete('/:id', queueController.remove);
