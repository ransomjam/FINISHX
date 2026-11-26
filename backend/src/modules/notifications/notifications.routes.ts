import { Router } from 'express';
import { notificationsController } from './notifications.controller';
import { authenticate } from '../../middleware/authenticate';
import { validateBody } from '../../middleware/validate';
import { registerDeviceSchema } from './notifications.schema';

export const notificationsRouter = Router();

notificationsRouter.use(authenticate);

notificationsRouter.get('/', notificationsController.list);
notificationsRouter.patch('/:id/read', notificationsController.markAsRead);
notificationsRouter.post(
  '/devices',
  validateBody(registerDeviceSchema),
  notificationsController.registerDevice
);
