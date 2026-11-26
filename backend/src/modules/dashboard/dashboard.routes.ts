import { Router } from 'express';
import { dashboardController } from './dashboard.controller';
import { authenticate } from '../../middleware/authenticate';

export const dashboardRouter = Router();

dashboardRouter.use(authenticate);

dashboardRouter.get('/', dashboardController.getDashboard);
