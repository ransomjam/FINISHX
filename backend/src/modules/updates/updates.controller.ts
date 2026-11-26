import { Request, Response, NextFunction } from 'express';
import { updatesService } from './updates.service';
import { sendCreated, sendSuccess } from '../../common/utils/response';

export class UpdatesController {
  async create(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const update = await updatesService.createUpdate(req.user!.userId, req.body);
      sendCreated(res, update, 'Update posted successfully');
    } catch (error) {
      next(error);
    }
  }

  async list(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const updates = await updatesService.listUpdatesForJourney(
        req.params.journeyId,
        req.user!.userId
      );
      sendSuccess(res, updates);
    } catch (error) {
      next(error);
    }
  }
}

export const updatesController = new UpdatesController();
