import { prisma } from '../../database/prisma';

export class DashboardService {
  async getDashboardData(userId: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        fullName: true,
        email: true,
        avatarUrl: true,
        timezone: true,
      },
    });

    // 1. Fetch active journey
    const activeJourney = await prisma.journey.findFirst({
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
      },
    });

    let nextSession = null;
    let thisWeek = { completed: 0, target: 0 };
    let consistency = { percentage: 0, label: 'Last 4 weeks' };
    let checkInDue = false;

    if (activeJourney) {
      // Find next session (either currently IN_PROGRESS, or next SCHEDULED)
      const session = await prisma.session.findFirst({
        where: {
          journeyId: activeJourney.id,
          status: { in: ['IN_PROGRESS', 'SCHEDULED'] },
          scheduledAt: { gte: new Date(Date.now() - 2 * 60 * 60 * 1000) },
        },
        orderBy: { scheduledAt: 'asc' },
      });

      if (session) {
        const diffMs = new Date(session.scheduledAt).getTime() - Date.now();
        const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
        const diffMins = Math.floor((diffMs % (1000 * 60 * 60)) / (1000 * 60));

        let countdown = 'Upcoming';
        if (diffMs <= 0) {
          countdown = 'Ready now';
        } else if (diffHours > 24) {
          countdown = `In ${Math.ceil(diffHours / 24)} days`;
        } else if (diffHours > 0) {
          countdown = `In ${diffHours}h ${diffMins}m`;
        } else {
          countdown = `In ${diffMins}m`;
        }

        nextSession = {
          id: session.id,
          title: session.title,
          scheduledAt: session.scheduledAt,
          targetDurationMinutes: session.targetDurationMinutes,
          status: session.status,
          countdown,
        };
      }

      // Calculate This Week's completed sessions
      const now = new Date();
      const day = now.getDay();
      const diff = now.getDate() - day + (day === 0 ? -6 : 1); // Monday
      const weekStart = new Date(now.setDate(diff));
      weekStart.setHours(0, 0, 0, 0);

      const weekEnd = new Date(weekStart);
      weekEnd.setDate(weekEnd.getDate() + 7);

      const completedThisWeek = await prisma.session.count({
        where: {
          journeyId: activeJourney.id,
          status: 'COMPLETED',
          completedAt: { gte: weekStart, lt: weekEnd },
        },
      });

      const targetPerWeek = activeJourney.commitmentSchedule?.days.length || 3;
      thisWeek = {
        completed: completedThisWeek,
        target: targetPerWeek,
      };

      // Calculate last 4 weeks consistency
      const fourWeeksAgo = new Date();
      fourWeeksAgo.setDate(fourWeeksAgo.getDate() - 28);

      const sessionsLast4Weeks = await prisma.session.findMany({
        where: {
          journeyId: activeJourney.id,
          scheduledAt: { gte: fourWeeksAgo },
        },
        select: { status: true },
      });

      if (sessionsLast4Weeks.length > 0) {
        const completed4Weeks = sessionsLast4Weeks.filter((s) => s.status === 'COMPLETED').length;
        consistency.percentage = Math.round((completed4Weeks / sessionsLast4Weeks.length) * 100);
      } else {
        consistency.percentage = activeJourney.progressPercentage || 100;
      }

      // Check if weekly reflection is due (e.g. today is Sunday or reflection not done for this week)
      const reflectionThisWeek = await prisma.weeklyReflection.findFirst({
        where: {
          journeyId: activeJourney.id,
          weekStartDate: { gte: weekStart },
        },
      });

      checkInDue = !reflectionThisWeek && now.getDay() === 0; // Sunday
    }

    return {
      user,
      activeJourney: activeJourney
        ? {
            id: activeJourney.id,
            title: activeJourney.title,
            category: activeJourney.category,
            resourceTitle: activeJourney.resourceTitle,
            resourceType: activeJourney.resourceType,
            startDate: activeJourney.startDate,
            targetDate: activeJourney.targetDate,
            status: activeJourney.status,
            progressPercentage: activeJourney.progressPercentage,
            completedSessions: activeJourney.completedSessions,
            totalSessions: activeJourney.totalSessions,
            commitmentSchedule: activeJourney.commitmentSchedule,
          }
        : null,
      nextSession,
      thisWeek,
      consistency,
      group: activeJourney?.group
        ? {
            id: activeJourney.group.id,
            name: activeJourney.group.name,
            category: activeJourney.group.category,
            leagueTier: activeJourney.group.leagueTier,
            groupHealth: activeJourney.group.groupHealth,
            memberCount: activeJourney.group._count.members,
            members: activeJourney.group.members.map((m) => ({
              id: m.user.id,
              fullName: m.user.fullName,
              avatarUrl: m.user.avatarUrl,
            })),
          }
        : null,
      checkInDue,
    };
  }
}

export const dashboardService = new DashboardService();
