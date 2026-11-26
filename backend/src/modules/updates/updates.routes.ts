import { Router } from 'express';
import { updatesController } from './updates.controller';
import { authenticate } from '../../middleware/authenticate';
import { validateBody } from '../../middleware/validate';
import { createUpdateSchema } from './updates.schema';

export const updatesRouter = Router();

updatesRouter.use(authenticate);

updatesRouter.post('/', validateBody(createUpdateSchema), updatesController.create);
updatesRouter.get('/journey/:journeyId', updatesController.list);
