import { Request, Response, NextFunction } from 'express';
import { sessionsService } from './sessions.service';
import { sendSuccess } from '../../common/utils/response';

export class SessionsController {
  async getUpcoming(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const session = await sessionsService.getUpcomingSession(req.user!.userId);
      sendSuccess(res, session);
    } catch (error) {
      next(error);
    }
  }

  async list(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await sessionsService.listSessions(req.user!.userId, req.query as any);
      sendSuccess(res, result.sessions, undefined, 200, result.meta);
    } catch (error) {
      next(error);
    }
  }

  async start(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const session = await sessionsService.startSession(
        req.params.id,
        req.user!.userId,
        req.body
      );
      sendSuccess(res, session, 'Focus session started');
    } catch (error) {
      next(error);
    }
  }

  async end(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const session = await sessionsService.endSession(
        req.params.id,
        req.user!.userId,
        req.body
      );
      sendSuccess(res, session, 'Focus session completed!');
    } catch (error) {
      next(error);
    }
  }

  async reflect(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const reflection = await sessionsService.reflectSession(
        req.params.id,
        req.user!.userId,
        req.body
      );
      sendSuccess(res, reflection, 'Reflection submitted');
    } catch (error) {
      next(error);
    }
  }

  async skip(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const session = await sessionsService.skipSession(
        req.params.id,
        req.user!.userId,
        req.body
      );
      sendSuccess(res, session, 'Session skipped');
    } catch (error) {
      next(error);
    }
  }
}

export const sessionsController = new SessionsController();
