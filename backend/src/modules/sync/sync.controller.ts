import { Request, Response, NextFunction } from 'express';
import { syncService } from './sync.service';
import { sendSuccess } from '../../common/utils/response';

export class SyncController {
  async processBatch(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await syncService.processBatch(req.user!.userId, req.body);
      sendSuccess(res, result, 'Sync events processed');
    } catch (error) {
      next(error);
    }
  }
}

export const syncController = new SyncController();
