import { prisma } from '../../database/prisma';

export class ArchiveService {
  async getArchive(userId: string) {
    const [history, journeys] = await Promise.all([
      prisma.journeyHistory.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
      }),
      prisma.journey.findMany({
        where: {
          userId,
          status: { in: ['COMPLETED', 'CANCELLED'] },
        },
        include: {
          sessions: {
            where: { status: 'COMPLETED' },
            select: { id: true, actualDurationMinutes: true },
          },
        },
        orderBy: { updatedAt: 'desc' },
      }),
    ]);

    const completedJourneys = journeys.filter((j) => j.status === 'COMPLETED');
    const totalSessions = journeys.reduce((sum, j) => sum + j.completedSessions, 0);
    const totalMinutes = journeys.reduce(
      (sum, j) => sum + j.sessions.reduce((sSum, s) => sSum + (s.actualDurationMinutes || 0), 0),
      0
    );

    return {
      stats: {
        completedCount: completedJourneys.length,
        cancelledCount: journeys.length - completedJourneys.length,
        totalSessions,
        totalHours: Math.round(totalMinutes / 60),
      },
      history,
      journeys: journeys.map((j) => ({
        id: j.id,
        title: j.title,
        category: j.category,
        resourceTitle: j.resourceTitle,
        startDate: j.startDate,
        targetDate: j.targetDate,
        completedAt: j.completedAt,
        status: j.status,
        progressPercentage: j.progressPercentage,
        completedSessions: j.completedSessions,
        totalSessions: j.totalSessions,
      })),
    };
  }
}

export const archiveService = new ArchiveService();
