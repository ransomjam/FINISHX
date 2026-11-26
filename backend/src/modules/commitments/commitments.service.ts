import { prisma } from '../../database/prisma';
import { logger } from '../../common/logger';

export class CommitmentsService {
  /**
   * Generates upcoming sessions for a journey based on its active commitment schedule.
   * Idempotent: checks for existing sessions at the given scheduled time to avoid duplication.
   */
  async generateSessionsForJourney(
    journeyId: string,
    horizonDays = 28
  ): Promise<number> {
    const journey = await prisma.journey.findUnique({
      where: { id: journeyId },
      include: {
        commitmentSchedule: {
          include: {
            days: true,
          },
        },
      },
    });

    if (
      !journey ||
      !journey.commitmentSchedule ||
      journey.commitmentSchedule.days.length === 0 ||
      (journey.status !== 'ACTIVE' && journey.status !== 'SCHEDULED')
    ) {
      return 0;
    }

    const schedule = journey.commitmentSchedule;
    const now = new Date();
    const startDate = new Date(journey.startDate);
    const targetDate = new Date(journey.targetDate);

    // Generation starts from max(now, startDate)
    let cursor = new Date(Math.max(now.getTime(), startDate.getTime()));
    // Set cursor to start of day
    cursor.setHours(0, 0, 0, 0);

    const endDate = new Date(cursor);
    endDate.setDate(endDate.getDate() + horizonDays);
    const finalDate = new Date(Math.min(targetDate.getTime(), endDate.getTime()));

    let createdCount = 0;

    // Build map of dayOfWeek -> days config
    const dayMap = new Map<number, typeof schedule.days[0]>();
    for (const d of schedule.days) {
      dayMap.set(d.dayOfWeek, d);
    }

    const daysToScan = Math.ceil((finalDate.getTime() - cursor.getTime()) / (1000 * 60 * 60 * 24));

    for (let i = 0; i <= daysToScan; i++) {
      const current = new Date(cursor);
      current.setDate(current.getDate() + i);

      // JS getDay(): 0 = Sun, 1 = Mon ... 6 = Sat
      // Our ISO dayOfWeek: 1 = Mon ... 7 = Sun
      const jsDay = current.getDay();
      const isoDay = jsDay === 0 ? 7 : jsDay;

      const dayConfig = dayMap.get(isoDay);
      if (!dayConfig) continue;

      const [hours, minutes] = dayConfig.startTime.split(':').map(Number);
      const scheduledAt = new Date(current);
      scheduledAt.setHours(hours, minutes, 0, 0);

      // Don't generate sessions in the past if now is already past that time today
      if (scheduledAt.getTime() < now.getTime() - 1000 * 60 * 60 * 2) {
        continue;
      }

      // Check if session exists within a 30-minute window for this journey
      const windowStart = new Date(scheduledAt.getTime() - 30 * 60 * 1000);
      const windowEnd = new Date(scheduledAt.getTime() + 30 * 60 * 1000);

      const existing = await prisma.session.findFirst({
        where: {
          journeyId: journey.id,
          scheduledAt: {
            gte: windowStart,
            lte: windowEnd,
          },
        },
      });

      if (!existing) {
        await prisma.session.create({
          data: {
            journeyId: journey.id,
            userId: journey.userId,
            title: `${journey.title} Focus Session`,
            scheduledAt,
            targetDurationMinutes: dayConfig.durationMinutes || schedule.sessionDurationMinutes,
            status: 'SCHEDULED',
          },
        });
        createdCount++;
      }
    }

    // Update total planned sessions on journey
    const totalSessions = await prisma.session.count({
      where: { journeyId: journey.id },
    });

    await prisma.journey.update({
      where: { id: journey.id },
      data: { totalSessions },
    });

    logger.info(`Generated ${createdCount} sessions for journey ${journey.id}`);
    return createdCount;
  }
}

export const commitmentsService = new CommitmentsService();
