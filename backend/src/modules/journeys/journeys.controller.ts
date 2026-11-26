import { Request, Response, NextFunction } from 'express';
import { journeysService } from './journeys.service';
import { sendSuccess, sendCreated } from '../../common/utils/response';

export class JourneysController {
  async createJourney(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const journey = await journeysService.createJourney(req.user!.userId, req.body);
      sendCreated(res, journey, 'Journey created successfully');
    } catch (error) {
      next(error);
    }
  }

  async getActiveJourney(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const journey = await journeysService.getActiveJourney(req.user!.userId);
      sendSuccess(res, journey);
    } catch (error) {
      next(error);
    }
  }

  async getQueuedJourneys(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const queued = await journeysService.getQueuedJourneys(req.user!.userId);
      sendSuccess(res, queued);
    } catch (error) {
      next(error);
    }
  }

  async getJourneyById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const journey = await journeysService.getJourneyById(req.params.id, req.user!.userId);
      sendSuccess(res, journey);
    } catch (error) {
      next(error);
    }
  }

  async signCommitment(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const journey = await journeysService.signCommitment(
        req.params.id,
        req.user!.userId,
        req.body
      );
      sendSuccess(res, journey, 'Commitment signed and active!');
    } catch (error) {
      next(error);
    }
  }

  async pauseJourney(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const journey = await journeysService.pauseJourney(
        req.params.id,
        req.user!.userId,
        req.body
      );
      sendSuccess(res, journey, 'Journey paused');
    } catch (error) {
      next(error);
    }
  }

  async resumeJourney(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const journey = await journeysService.resumeJourney(req.params.id, req.user!.userId);
      sendSuccess(res, journey, 'Journey resumed');
    } catch (error) {
      next(error);
    }
  }

  async extendJourney(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const journey = await journeysService.extendJourney(
        req.params.id,
        req.user!.userId,
        req.body
      );
      sendSuccess(res, journey, 'Journey target date extended');
    } catch (error) {
      next(error);
    }
  }

  async completeJourney(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await journeysService.completeJourney(
        req.params.id,
        req.user!.userId,
        req.body
      );
      sendSuccess(res, result, 'Congratulations on finishing your journey!');
    } catch (error) {
      next(error);
    }
  }

  async cancelJourney(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const journey = await journeysService.cancelJourney(req.params.id, req.user!.userId);
      sendSuccess(res, journey, 'Journey archived');
    } catch (error) {
      next(error);
    }
  }
}

export const journeysController = new JourneysController();
