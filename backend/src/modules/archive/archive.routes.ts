import { Router } from 'express';
import { archiveController } from './archive.controller';
import { authenticate } from '../../middleware/authenticate';

export const archiveRouter = Router();

archiveRouter.use(authenticate);

archiveRouter.get('/', archiveController.getArchive);
