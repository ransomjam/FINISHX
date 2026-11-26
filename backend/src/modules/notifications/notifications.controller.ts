import { Request, Response, NextFunction } from 'express';
import { notificationsService } from './notifications.service';
import { sendSuccess } from '../../common/utils/response';

export class NotificationsController {
  async list(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const items = await notificationsService.listNotifications(req.user!.userId);
      sendSuccess(res, items);
    } catch (error) {
      next(error);
    }
  }

  async markAsRead(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const updated = await notificationsService.markAsRead(req.params.id, req.user!.userId);
      sendSuccess(res, updated, 'Notification marked as read');
    } catch (error) {
      next(error);
    }
  }

  async registerDevice(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const device = await notificationsService.registerDevice(req.user!.userId, req.body);
      sendSuccess(res, device, 'Device registered successfully');
    } catch (error) {
      next(error);
    }
  }
}

export const notificationsController = new NotificationsController();
