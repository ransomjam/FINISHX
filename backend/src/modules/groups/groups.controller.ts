import { Request, Response, NextFunction } from 'express';
import { groupsService } from './groups.service';
import { sendSuccess } from '../../common/utils/response';

export class GroupsController {
  async getDetails(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const group = await groupsService.getGroupDetails(req.params.id, req.user!.userId);
      sendSuccess(res, group);
    } catch (error) {
      next(error);
    }
  }

  async addReaction(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await groupsService.addFeedReaction(
        req.params.activityId,
        req.user!.userId,
        req.body.reactionType
      );
      sendSuccess(res, result);
    } catch (error) {
      next(error);
    }
  }
}

export const groupsController = new GroupsController();
