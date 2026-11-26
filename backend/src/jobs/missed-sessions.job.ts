import { prisma } from '../database/prisma';
import { logger } from '../common/logger';

export async function runMissedSessionsDetector(): Promise<number> {
  const cutoff = new Date(Date.now() - 3 * 60 * 60 * 1000); // 3 hours past scheduled time

  const missedSessions = await prisma.session.findMany({
    where: {
      status: 'SCHEDULED',
      scheduledAt: { lt: cutoff },
    },
    include: {
      journey: { select: { title: true } },
    },
  });

  let count = 0;

  for (const session of missedSessions) {
    try {
      await prisma.$transaction([
        prisma.session.update({
          where: { id: session.id },
          data: { status: 'MISSED' },
        }),
        prisma.notification.create({
          data: {
            userId: session.userId,
            title: 'Missed Focus Session',
            body: `You missed your scheduled session for "${session.journey.title}". Consistency is built one day at a time—be ready for your next session!`,
            data: { sessionId: session.id, journeyId: session.journeyId },
          },
        }),
      ]);
      count++;
    } catch (err) {
      logger.error(`Failed to mark session ${session.id} as missed:`, err);
    }
  }

  logger.info(`Missed sessions job processed: ${count} sessions marked as missed`);
  return count;
}
