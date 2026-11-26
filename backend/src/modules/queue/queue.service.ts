import { prisma } from '../../database/prisma';
import { BadRequestError, ConflictError, NotFoundError } from '../../common/errors/app-error';
import { commitmentsService } from '../commitments/commitments.service';
import { groupsService } from '../groups/groups.service';
import { logger } from '../../common/logger';

export class QueueService {
  async getQueue(userId: string) {
    return prisma.journey.findMany({
      where: {
        userId,
        status: 'QUEUED',
      },
      include: {
        commitmentSchedule: {
          include: { days: true },
        },
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  async promoteJourney(journeyId: string, userId: string) {
    const existingActive = await prisma.journey.findFirst({
      where: {
        userId,
        status: { in: ['ACTIVE', 'PAUSED'] },
      },
    });

    if (existingActive) {
      throw new ConflictError(
        `Cannot activate journey: you already have an active journey ("${existingActive.title}"). Under FinishX (One Journey. Full Focus), you must finish or cancel it first.`
      );
    }

    const journey = await prisma.journey.findFirst({
      where: { id: journeyId, userId, status: 'QUEUED' },
    });

    if (!journey) {
      throw new NotFoundError('Queued journey not found');
    }

    const now = new Date();
    const newStatus = journey.startDate <= now ? 'ACTIVE' : 'SCHEDULED';

    const updated = await prisma.journey.update({
      where: { id: journeyId },
      data: { status: newStatus },
      include: {
        commitmentSchedule: {
          include: { days: true },
        },
      },
    });

    await groupsService.autoAssignGroup(userId, journey.id, journey.category);
    await commitmentsService.generateSessionsForJourney(journey.id);

    logger.info(`Promoted queued journey ${journeyId} to ${newStatus}`);
    return updated;
  }

  async removeJourney(journeyId: string, userId: string) {
    const journey = await prisma.journey.findFirst({
      where: { id: journeyId, userId, status: 'QUEUED' },
    });

    if (!journey) {
      throw new NotFoundError('Queued journey not found');
    }

    await prisma.journey.delete({
      where: { id: journeyId },
    });

    logger.info(`Removed queued journey ${journeyId}`);
  }
}

export const queueService = new QueueService();
