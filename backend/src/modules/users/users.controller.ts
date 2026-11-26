import { Request, Response, NextFunction } from 'express';
import { usersService } from './users.service';
import { sendSuccess, sendNoContent } from '../../common/utils/response';

export class UsersController {
  async getProfile(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = await usersService.getProfile(req.user!.userId);
      sendSuccess(res, user);
    } catch (error) {
      next(error);
    }
  }

  async updateProfile(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = await usersService.updateProfile(req.user!.userId, req.body);
      sendSuccess(res, user, 'Profile updated successfully');
    } catch (error) {
      next(error);
    }
  }

  async updateTimezone(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await usersService.updateTimezone(req.user!.userId, req.body);
      sendSuccess(res, result, 'Timezone updated successfully');
    } catch (error) {
      next(error);
    }
  }

  async deleteAccount(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await usersService.deleteAccount(req.user!.userId);
      sendNoContent(res);
    } catch (error) {
      next(error);
    }
  }
}

export const usersController = new UsersController();
