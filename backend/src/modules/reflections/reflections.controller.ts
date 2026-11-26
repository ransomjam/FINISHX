import { Request, Response, NextFunction } from 'express';
import { reflectionsService } from './reflections.service';
import { sendCreated, sendSuccess } from '../../common/utils/response';

export class ReflectionsController {
  async submit(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await reflectionsService.submitWeeklyReflection(
        req.user!.userId,
        req.body
      );
      sendCreated(res, result, 'Weekly reflection recorded successfully');
    } catch (error) {
      next(error);
    }
  }

  async listForJourney(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const results = await reflectionsService.getReflectionsForJourney(
        req.params.journeyId,
        req.user!.userId
      );
      sendSuccess(res, results);
    } catch (error) {
      next(error);
    }
  }
}

export const reflectionsController = new ReflectionsController();
