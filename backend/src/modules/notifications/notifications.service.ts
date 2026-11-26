import { prisma } from '../../database/prisma';
import { NotFoundError } from '../../common/errors/app-error';
import { RegisterDeviceInput } from './notifications.schema';
import { logger } from '../../common/logger';

export class NotificationsService {
  async listNotifications(userId: string) {
    return prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
  }

  async markAsRead(notificationId: string, userId: string) {
    const notification = await prisma.notification.findFirst({
      where: { id: notificationId, userId },
    });

    if (!notification) {
      throw new NotFoundError('Notification not found');
    }

    return prisma.notification.update({
      where: { id: notificationId },
      data: { isRead: true },
    });
  }

  async registerDevice(userId: string, input: RegisterDeviceInput) {
    const device = await prisma.device.upsert({
      where: { token: input.token },
      update: {
        userId,
        platform: input.platform,
        appVersion: input.appVersion,
        lastActiveAt: new Date(),
      },
      create: {
        userId,
        token: input.token,
        platform: input.platform,
        appVersion: input.appVersion,
      },
    });

    logger.info(`Registered device token for user ${userId} (${input.platform})`);
    return device;
  }
}

export const notificationsService = new NotificationsService();
