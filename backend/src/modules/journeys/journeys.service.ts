import { prisma } from '../../database/prisma';
import {
  BadRequestError,
  ConflictError,
  NotFoundError,
} from '../../common/errors/app-error';
import { logger } from '../../common/logger';
import { commitmentsService } from '../commitments/commitments.service';
import { groupsService } from '../groups/groups.service';
import {
  CreateJourneyInput,
  UpdateJourneyInput,
  SignCommitmentInput,
  PauseJourneyInput,
  ExtendJourneyInput,
  CompleteJourneyInput,
} from './journeys.schema';

export class JourneysService {
  async createJourney(userId: string, input: CreateJourneyInput) {
    const existingActive = await prisma.journey.findFirst({
      where: {
        userId,
        status: { in: ['ACTIVE', 'PAUSED'] },
      },
    });

    const isStartingImmediately = !input.forceQueue && !existingActive;

    const startDate = new Date(input.startDate);
    const targetDate = new Date(input.targetDate);

    if (targetDate <= startDate) {
      throw new BadRequestError('Target date must be strictly after the start date');
    }

    const now = new Date();
    let initialStatus: 'ACTIVE' | 'SCHEDULED' | 'QUEUED' = 'QUEUED';

    if (isStartingImmediately) {
      initialStatus = startDate <= now ? 'ACTIVE' : 'SCHEDULED';
    } else if (!input.forceQueue && existingActive) {
      throw new ConflictError(
        'You already have an active journey ("' +
          existingActive.title +
          '"). Under FinishX philosophy (One Journey. Full Focus), you must finish or cancel it first, or add this journey to your queue.'
      );
    }

    const journey = await prisma.$transaction(async (tx) => {
      const created = await tx.journey.create({
        data: {
          userId,
          title: input.title,
          description: input.description,
          category: input.category,
          resourceTitle: input.resourceTitle,
          resourceType: input.resourceType,
          resourceUrl: input.resourceUrl,
          startDate,
          targetDate,
          status: initialStatus,
        },
      });

      if (input.schedule) {
        const weeklyMinutes = input.schedule.days.reduce(
          (acc, d) => acc + (d.durationMinutes || input.schedule!.sessionDurationMinutes),
          0
        );

        await tx.commitmentSchedule.create({
          data: {
            journeyId: created.id,
            sessionDurationMinutes: input.schedule.sessionDurationMinutes,
            weeklyCommitmentMinutes: weeklyMinutes,
            preferredTime: input.schedule.preferredTime,
            days: {
              create: input.schedule.days.map((d) => ({
                dayOfWeek: d.dayOfWeek,
                startTime: d.startTime,
                durationMinutes: d.durationMinutes || input.schedule!.sessionDurationMinutes,
              })),
            },
          },
        });
      }

      return created;
    });

    // If active or scheduled, assign group and generate sessions
    if (initialStatus === 'ACTIVE' || initialStatus === 'SCHEDULED') {
      await groupsService.autoAssignGroup(userId, journey.id, journey.category);
      if (input.schedule) {
        await commitmentsService.generateSessionsForJourney(journey.id);
      }
    }

    logger.info(`Created journey ${journey.id} with status ${initialStatus} for user ${userId}`);

    return this.getJourneyById(journey.id, userId);
  }

  async getActiveJourney(userId: string) {
    const journey = await prisma.journey.findFirst({
      where: {
        userId,
        status: { in: ['ACTIVE', 'PAUSED'] },
      },
      include: {
        commitmentSchedule: {
          include: { days: true },
        },
        group: {
          include: {
            members: {
              take: 5,
              include: {
                user: { select: { id: true, fullName: true, avatarUrl: true } },
              },
            },
            _count: { select: { members: true } },
          },
        },
        sessions: {
          where: {
            status: { in: ['SCHEDULED', 'IN_PROGRESS'] },
            scheduledAt: { gte: new Date(Date.now() - 2 * 60 * 60 * 1000) },
          },
          orderBy: { scheduledAt: 'asc' },
          take: 3,
        },
      },
    });

    if (!journey) {
      return null;
    }

    // Calculate dynamic stats
    const totalDays = Math.ceil(
      (new Date(journey.targetDate).getTime() - new Date(journey.startDate).getTime()) /
        (1000 * 60 * 60 * 24)
    );
    const daysPassed = Math.max(
      0,
      Math.ceil((Date.now() - new Date(journey.startDate).getTime()) / (1000 * 60 * 60 * 24))
    );
    const daysRemaining = Math.max(0, totalDays - daysPassed);

    const completedSessions = await prisma.session.count({
      where: { journeyId: journey.id, status: 'COMPLETED' },
    });

    const totalSessions = await prisma.session.count({
      where: { journeyId: journey.id },
    });

    const progressPercentage =
      totalSessions > 0 ? Math.round((completedSessions / totalSessions) * 100) : 0;

    return {
      ...journey,
      stats: {
        totalDays,
        daysPassed,
        daysRemaining,
        completedSessions,
        totalSessions,
        progressPercentage,
      },
    };
  }

  async getJourneyById(journeyId: string, userId: string) {
    const journey = await prisma.journey.findFirst({
      where: { id: journeyId, userId },
      include: {
        commitmentSchedule: {
          include: { days: true },
        },
        group: true,
        updates: {
          orderBy: { createdAt: 'desc' },
          take: 10,
        },
        sessions: {
          orderBy: { scheduledAt: 'desc' },
          take: 10,
        },
      },
    });

    if (!journey) {
      throw new NotFoundError('Journey not found');
    }

    return journey;
  }

  async getQueuedJourneys(userId: string) {
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

  async signCommitment(journeyId: string, userId: string, input: SignCommitmentInput) {
    const journey = await prisma.journey.findFirst({
      where: { id: journeyId, userId },
    });

    if (!journey) {
      throw new NotFoundError('Journey not found');
    }

    const updated = await prisma.journey.update({
      where: { id: journeyId },
      data: {
        commitmentSignedAt: new Date(),
        commitmentStatement: input.commitmentStatement,
        status: 'ACTIVE',
      },
    });

    await groupsService.autoAssignGroup(userId, journey.id, journey.category);
    await commitmentsService.generateSessionsForJourney(journey.id);

    return this.getJourneyById(journey.id, userId);
  }

  async pauseJourney(journeyId: string, userId: string, input: PauseJourneyInput) {
    const journey = await prisma.journey.findFirst({
      where: { id: journeyId, userId, status: 'ACTIVE' },
    });

    if (!journey) {
      throw new BadRequestError('Only active journeys can be paused');
    }

    await prisma.$transaction([
      prisma.journey.update({
        where: { id: journeyId },
        data: { status: 'PAUSED' },
      }),
      prisma.journeyPause.create({
        data: {
          journeyId,
          reason: input.reason,
          notes: input.notes,
        },
      }),
    ]);

    logger.info(`Journey paused: ${journeyId} (Reason: ${input.reason})`);
    return this.getJourneyById(journeyId, userId);
  }

  async resumeJourney(journeyId: string, userId: string) {
    const journey = await prisma.journey.findFirst({
      where: { id: journeyId, userId, status: 'PAUSED' },
    });

    if (!journey) {
      throw new BadRequestError('Only paused journeys can be resumed');
    }

    // Close latest pause record
    const latestPause = await prisma.journeyPause.findFirst({
      where: { journeyId, resumedAt: null },
      orderBy: { pausedAt: 'desc' },
    });

    if (latestPause) {
      await prisma.journeyPause.update({
        where: { id: latestPause.id },
        data: { resumedAt: new Date() },
      });
    }

    await prisma.journey.update({
      where: { id: journeyId },
      data: { status: 'ACTIVE' },
    });

    // Re-generate future sessions from today
    await commitmentsService.generateSessionsForJourney(journeyId);

    logger.info(`Journey resumed: ${journeyId}`);
    return this.getJourneyById(journeyId, userId);
  }

  async extendJourney(journeyId: string, userId: string, input: ExtendJourneyInput) {
    const journey = await prisma.journey.findFirst({
      where: { id: journeyId, userId, status: { in: ['ACTIVE', 'PAUSED'] } },
    });

    if (!journey) {
      throw new BadRequestError('Only active or paused journeys can be extended');
    }

    const newTargetDate = new Date(input.newTargetDate);
    if (newTargetDate <= journey.targetDate) {
      throw new BadRequestError('New target date must be later than current target date');
    }

    await prisma.journey.update({
      where: { id: journeyId },
      data: { targetDate: newTargetDate },
    });

    await commitmentsService.generateSessionsForJourney(journeyId);

    return this.getJourneyById(journeyId, userId);
  }

  async completeJourney(journeyId: string, userId: string, input: CompleteJourneyInput) {
    const journey = await prisma.journey.findFirst({
      where: { id: journeyId, userId, status: { in: ['ACTIVE', 'PAUSED'] } },
    });

    if (!journey) {
      throw new BadRequestError('Only active or paused journeys can be marked as completed');
    }

    const completedSessions = await prisma.session.count({
      where: { journeyId, status: 'COMPLETED' },
    });
    const totalSessions = await prisma.session.count({
      where: { journeyId },
    });

    const consistencyRate =
      totalSessions > 0 ? (completedSessions / totalSessions) * 100 : 100;
    const durationDays = Math.ceil(
      (Date.now() - new Date(journey.startDate).getTime()) / (1000 * 60 * 60 * 24)
    );

    const result = await prisma.$transaction(async (tx) => {
      const updated = await tx.journey.update({
        where: { id: journeyId },
        data: {
          status: 'COMPLETED',
          completedAt: new Date(),
          progressPercentage: 100,
        },
      });

      // Archive to JourneyHistory
      await tx.journeyHistory.create({
        data: {
          journeyId,
          userId,
          title: journey.title,
          category: journey.category,
          resourceTitle: journey.resourceTitle,
          durationDays,
          sessionsCompleted: completedSessions,
          consistencyRate,
          outcome: 'COMPLETED_SUCCESSFULLY',
          reflectionNotes: input.reflectionNotes,
        },
      });

      // Check if queue has a pending journey
      const nextQueued = await tx.journey.findFirst({
        where: { userId, status: 'QUEUED' },
        orderBy: { createdAt: 'asc' },
      });

      return { journey: updated, nextQueued };
    });

    logger.info(`Journey completed: ${journeyId}`);

    return {
      journey: result.journey,
      stats: {
        durationDays,
        completedSessions,
        consistencyRate: Math.round(consistencyRate),
      },
      nextQueued: result.nextQueued,
    };
  }

  async cancelJourney(journeyId: string, userId: string) {
    const journey = await prisma.journey.findFirst({
      where: { id: journeyId, userId, status: { in: ['ACTIVE', 'PAUSED', 'QUEUED'] } },
    });

    if (!journey) {
      throw new NotFoundError('Journey not found');
    }

    const updated = await prisma.journey.update({
      where: { id: journeyId },
      data: { status: 'CANCELLED' },
    });

    await prisma.journeyHistory.create({
      data: {
        journeyId,
        userId,
        title: journey.title,
        category: journey.category,
        resourceTitle: journey.resourceTitle,
        durationDays: Math.ceil(
          (Date.now() - new Date(journey.startDate).getTime()) / (1000 * 60 * 60 * 24)
        ),
        sessionsCompleted: await prisma.session.count({
          where: { journeyId, status: 'COMPLETED' },
        }),
        consistencyRate: 0,
        outcome: 'ABANDONED',
      },
    });

    logger.info(`Journey cancelled: ${journeyId}`);
    return updated;
  }
}

export const journeysService = new JourneysService();
