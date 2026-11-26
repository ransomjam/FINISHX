import { prisma } from '../database/prisma';
import { logger } from '../common/logger';
import { fcmService } from '../integrations/firebase/fcm.service';

export async function runReminderNotifications(): Promise<number> {
  const now = new Date();
  const windowStart = new Date(now.getTime() + 10 * 60 * 1000); // 10 minutes ahead
  const windowEnd = new Date(now.getTime() + 25 * 60 * 1000);   // 25 minutes ahead

  // Find sessions scheduled within window
  const sessions = await prisma.session.findMany({
    where: {
      status: 'SCHEDULED',
      scheduledAt: {
        gte: windowStart,
        lte: windowEnd,
      },
    },
    include: {
      journey: { select: { title: true } },
      user: {
        include: {
          devices: true,
        },
      },
    },
  });

  let sentCount = 0;

  for (const session of sessions) {
    try {
      // Check if a reminder was already created
      const existingNotification = await prisma.notification.findFirst({
        where: {
          userId: session.userId,
          title: 'Upcoming Focus Session',
          data: {
            path: ['sessionId'],
            equals: session.id,
          },
        },
      });

      if (existingNotification) continue;

      const title = 'Upcoming Focus Session';
      const body = `Your ${session.targetDurationMinutes}m focus session for "${session.journey.title}" starts in 15 minutes. Prepare your focus space!`;

      // Create notification record
      await prisma.notification.create({
        data: {
          userId: session.userId,
          title,
          body,
          data: { sessionId: session.id, journeyId: session.journeyId },
        },
      });

      // Send push notifications to user's registered devices
      const tokens = session.user.devices.map((d) => d.token);
      if (tokens.length > 0) {
        await fcmService.sendPushNotification(tokens, title, body, {
          sessionId: session.id,
          journeyId: session.journeyId,
        });
      }

      sentCount++;
    } catch (err) {
      logger.error(`Error sending reminder for session ${session.id}:`, err);
    }
  }

  logger.info(`Reminder job sent notifications for ${sentCount} upcoming sessions`);
  return sentCount;
}
