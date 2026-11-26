import { prisma } from '../../database/prisma';
import { NotFoundError, BadRequestError } from '../../common/errors/app-error';
import { logger } from '../../common/logger';
import { SubmitWeeklyReflectionInput } from './reflections.schema';

export class ReflectionsService {
  async submitWeeklyReflection(userId: string, input: SubmitWeeklyReflectionInput) {
    const journey = await prisma.journey.findFirst({
      where: { id: input.journeyId, userId },
      include: { group: true },
    });

    if (!journey) {
      throw new NotFoundError('Journey not found');
    }

    // Determine week start date (most recent Monday or Sunday)
    const now = new Date();
    const day = now.getDay();
    const diff = now.getDate() - day + (day === 0 ? -6 : 1); // Monday
    const weekStartDate = new Date(now.setDate(diff));
    weekStartDate.setHours(0, 0, 0, 0);

    const weekNumber =
      input.weekNumber ||
      Math.max(
        1,
        Math.ceil(
          (Date.now() - new Date(journey.startDate).getTime()) /
            (1000 * 60 * 60 * 24 * 7)
        )
      );

    const reflection = await prisma.weeklyReflection.create({
      data: {
        journeyId: input.journeyId,
        userId,
        weekStartDate,
        weekNumber,
        completedCommitments: input.completedCommitments,
        biggestWin: input.biggestWin,
        biggestChallenge: input.biggestChallenge,
        nextWeekFocus: input.nextWeekFocus,
      },
    });

    // Create feed activity if group exists
    if (journey.groupId) {
      const user = await prisma.user.findUnique({
        where: { id: userId },
        select: { fullName: true },
      });

      await prisma.feedActivity.create({
        data: {
          groupId: journey.groupId,
          userId,
          journeyId: journey.id,
          activityType: 'WEEKLY_REFLECTION',
          title: `${user?.fullName || 'A member'} submitted their weekly reflection!`,
          content: `Win: "${input.biggestWin}" | Next: "${input.nextWeekFocus}"`,
        },
      });
    }

    logger.info(`Weekly reflection submitted: ${reflection.id} for journey ${input.journeyId}`);
    return reflection;
  }

  async getReflectionsForJourney(journeyId: string, userId: string) {
    const journey = await prisma.journey.findFirst({
      where: { id: journeyId, userId },
    });

    if (!journey) {
      throw new NotFoundError('Journey not found');
    }

    return prisma.weeklyReflection.findMany({
      where: { journeyId },
      orderBy: { createdAt: 'desc' },
    });
  }
}

export const reflectionsService = new ReflectionsService();
