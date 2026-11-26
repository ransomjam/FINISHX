import { Router } from 'express';
import { usersController } from './users.controller';
import { authenticate } from '../../middleware/authenticate';
import { validateBody } from '../../middleware/validate';
import { updateProfileSchema, updateTimezoneSchema } from './users.schema';

export const usersRouter = Router();

usersRouter.use(authenticate);

usersRouter.get('/profile', usersController.getProfile);
usersRouter.patch('/profile', validateBody(updateProfileSchema), usersController.updateProfile);
usersRouter.patch('/timezone', validateBody(updateTimezoneSchema), usersController.updateTimezone);
usersRouter.delete('/account', usersController.deleteAccount);
