import { prisma } from '../../database/prisma';
import { BadRequestError, NotFoundError } from '../../common/errors/app-error';
import { logger } from '../../common/logger';
import {
  StartSessionInput,
  EndSessionInput,
  ReflectSessionInput,
  SkipSessionInput,
  ListSessionsQuery,
} from './sessions.schema';

export class SessionsService {
  async getUpcomingSession(userId: string) {
    const activeJourney = await prisma.journey.findFirst({
      where: {
        userId,
        status: 'ACTIVE',
      },
      select: { id: true, title: true },
    });

    if (!activeJourney) {
      return null;
    }

    // Look for IN_PROGRESS session first, then upcoming SCHEDULED
    const inProgress = await prisma.session.findFirst({
      where: {
        journeyId: activeJourney.id,
        status: 'IN_PROGRESS',
      },
      include: {
        journey: { select: { id: true, title: true } },
      },
    });

    if (inProgress) {
      return inProgress;
    }

    const nextScheduled = await prisma.session.findFirst({
      where: {
        journeyId: activeJourney.id,
        status: 'SCHEDULED',
        scheduledAt: { gte: new Date(Date.now() - 2 * 60 * 60 * 1000) },
      },
      orderBy: { scheduledAt: 'asc' },
      include: {
        journey: { select: { id: true, title: true } },
      },
    });

    return nextScheduled;
  }

  async listSessions(userId: string, query: ListSessionsQuery) {
    const where: any = { userId };

    if (query.journeyId) where.journeyId = query.journeyId;
    if (query.status) where.status = query.status;
    if (query.from || query.to) {
      where.scheduledAt = {};
      if (query.from) where.scheduledAt.gte = new Date(query.from);
      if (query.to) where.scheduledAt.lte = new Date(query.to);
    }

    const limit = query.limit || 20;
    const page = query.page || 1;
    const skip = (page - 1) * limit;

    const [total, sessions] = await Promise.all([
      prisma.session.count({ where }),
      prisma.session.findMany({
        where,
        include: {
          reflection: true,
          journey: { select: { id: true, title: true } },
        },
        orderBy: { scheduledAt: 'desc' },
        skip,
        take: limit,
      }),
    ]);

    return {
      sessions,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async startSession(sessionId: string, userId: string, input: StartSessionInput) {
    const session = await prisma.session.findFirst({
      where: { id: sessionId, userId },
      include: { journey: true },
    });

    if (!session) {
      throw new NotFoundError('Session not found');
    }

    if (session.status === 'COMPLETED') {
      throw new BadRequestError('Session is already completed');
    }

    const startedAt = input.startedAt ? new Date(input.startedAt) : new Date();

    const updated = await prisma.session.update({
      where: { id: sessionId },
      data: {
        status: 'IN_PROGRESS',
        startedAt,
      },
      include: { journey: true },
    });

    logger.info(`Session started: ${sessionId} for user ${userId}`);
    return updated;
  }

  async endSession(sessionId: string, userId: string, input: EndSessionInput) {
    const session = await prisma.session.findFirst({
      where: { id: sessionId, userId },
      include: { journey: true },
    });

    if (!session) {
      throw new NotFoundError('Session not found');
    }

    if (session.status === 'COMPLETED') {
      throw new BadRequestError('Session has already been completed');
    }

    const completedAt = input.completedAt ? new Date(input.completedAt) : new Date();

    const result = await prisma.$transaction(async (tx) => {
      const updatedSession = await tx.session.update({
        where: { id: sessionId },
        data: {
          status: 'COMPLETED',
          completedAt,
          actualDurationMinutes: input.actualDurationMinutes,
        },
      });

      // Create reflection if details provided
      if (input.feeling || input.notes || input.rating) {
        await tx.sessionReflection.create({
          data: {
            sessionId,
            feeling: input.feeling || 'FOCUSED',
            rating: input.rating || 5,
            notes: input.notes,
            distractionsLevel: input.distractionsLevel || 1,
          },
        });
      }

      // Update journey completed sessions and progress
      const completedCount = await tx.session.count({
        where: { journeyId: session.journeyId, status: 'COMPLETED' },
      });
      const totalCount = await tx.session.count({
        where: { journeyId: session.journeyId },
      });

      const progressPercentage =
        totalCount > 0 ? Math.round((completedCount / totalCount) * 100) : 0;

      await tx.journey.update({
        where: { id: session.journeyId },
        data: {
          completedSessions: completedCount,
          progressPercentage,
        },
      });

      // Post feed activity if journey is in an accountability group
      if (session.journey.groupId) {
        const user = await tx.user.findUnique({
          where: { id: userId },
          select: { fullName: true },
        });

        await tx.feedActivity.create({
          data: {
            groupId: session.journey.groupId,
            userId,
            journeyId: session.journeyId,
            activityType: 'SESSION_COMPLETED',
            title: `${user?.fullName || 'A member'} completed a focus session!`,
            content: `Finished ${input.actualDurationMinutes} minutes of focus on "${session.journey.title}".`,
          },
        });
      }

      return updatedSession;
    });

    logger.info(`Session ended: ${sessionId} (${input.actualDurationMinutes}m)`);

    return prisma.session.findUnique({
      where: { id: sessionId },
      include: {
        reflection: true,
        journey: { select: { id: true, title: true, progressPercentage: true } },
      },
    });
  }

  async reflectSession(sessionId: string, userId: string, input: ReflectSessionInput) {
    const session = await prisma.session.findFirst({
      where: { id: sessionId, userId },
      include: { reflection: true },
    });

    if (!session) {
      throw new NotFoundError('Session not found');
    }

    if (session.reflection) {
      return prisma.sessionReflection.update({
        where: { id: session.reflection.id },
        data: {
          feeling: input.feeling,
          rating: input.rating,
          notes: input.notes,
          distractionsLevel: input.distractionsLevel,
        },
      });
    }

    return prisma.sessionReflection.create({
      data: {
        sessionId,
        feeling: input.feeling,
        rating: input.rating,
        notes: input.notes,
        distractionsLevel: input.distractionsLevel,
      },
    });
  }

  async skipSession(sessionId: string, userId: string, input: SkipSessionInput) {
    const session = await prisma.session.findFirst({
      where: { id: sessionId, userId },
    });

    if (!session) {
      throw new NotFoundError('Session not found');
    }

    return prisma.session.update({
      where: { id: sessionId },
      data: {
        status: 'SKIPPED',
      },
    });
  }
}

export const sessionsService = new SessionsService();
