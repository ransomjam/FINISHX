import { prisma } from '../../database/prisma';
import { NotFoundError } from '../../common/errors/app-error';
import { CreateUpdateInput } from './updates.schema';

export class UpdatesService {
  async createUpdate(userId: string, input: CreateUpdateInput) {
    const journey = await prisma.journey.findFirst({
      where: { id: input.journeyId, userId },
    });

    if (!journey) {
      throw new NotFoundError('Journey not found');
    }

    const update = await prisma.journeyUpdate.create({
      data: {
        journeyId: input.journeyId,
        userId,
        content: input.content,
        milestoneTitle: input.milestoneTitle,
      },
    });

    // If journey has a group, post to feed
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
          activityType: input.milestoneTitle ? 'MILESTONE_REACHED' : 'NOTE_SHARED',
          title: input.milestoneTitle
            ? `${user?.fullName || 'A member'} reached a milestone!`
            : `${user?.fullName || 'A member'} shared an update`,
          content: input.content,
        },
      });
    }

    return update;
  }

  async listUpdatesForJourney(journeyId: string, userId: string) {
    const journey = await prisma.journey.findFirst({
      where: { id: journeyId, userId },
    });

    if (!journey) {
      throw new NotFoundError('Journey not found');
    }

    return prisma.journeyUpdate.findMany({
      where: { journeyId },
      orderBy: { createdAt: 'desc' },
    });
  }
}

export const updatesService = new UpdatesService();
