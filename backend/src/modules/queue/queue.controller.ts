import { Request, Response, NextFunction } from 'express';
import { queueService } from './queue.service';
import { sendSuccess, sendNoContent } from '../../common/utils/response';

export class QueueController {
  async getQueue(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const queue = await queueService.getQueue(req.user!.userId);
      sendSuccess(res, queue);
    } catch (error) {
      next(error);
    }
  }

  async promote(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const journey = await queueService.promoteJourney(req.params.id, req.user!.userId);
      sendSuccess(res, journey, 'Journey promoted to active!');
    } catch (error) {
      next(error);
    }
  }

  async remove(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await queueService.removeJourney(req.params.id, req.user!.userId);
      sendNoContent(res);
    } catch (error) {
      next(error);
    }
  }
}

export const queueController = new QueueController();
