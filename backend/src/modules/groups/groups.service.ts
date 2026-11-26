import { prisma } from '../../database/prisma';
import { logger } from '../../common/logger';
import { NotFoundError, BadRequestError } from '../../common/errors/app-error';

export class GroupsService {
  private formatCategoryName(category: string): string {
    switch (category) {
      case 'LEARNING_SKILL':
        return 'Skills & Mastery';
      case 'CAREER_EXAM':
        return 'Certifications & Exams';
      case 'HEALTH_FITNESS':
        return 'Health & Fitness';
      case 'CREATIVE_WRITING':
        return 'Writers & Creators';
      case 'BUSINESS_STARTUP':
        return 'Entrepreneurs & Builders';
      default:
        return 'FinishX Focus';
    }
  }

  async autoAssignGroup(userId: string, journeyId: string, category: any) {
    // Check if user is already a member of an active group for this journey
    const existingMembership = await prisma.groupMember.findFirst({
      where: { userId, journeyId },
      include: { group: true },
    });

    if (existingMembership) {
      return existingMembership.group;
    }

    // Find an open group in this category with < 10 members
    const candidateGroups = await prisma.accountabilityGroup.findMany({
      where: {
        category,
        isActive: true,
      },
      include: {
        _count: {
          select: { members: true },
        },
      },
    });

    const openGroup = candidateGroups.find((g) => g._count.members < 10);

    let group = openGroup;

    if (!group) {
      const groupCount = await prisma.accountabilityGroup.count({
        where: { category },
      });

      const prettyName = this.formatCategoryName(category);
      group = await prisma.accountabilityGroup.create({
        data: {
          name: `${prettyName} Group #${groupCount + 1}`,
          description: `A dedicated cohort committed to finishing their ${prettyName.toLowerCase()} journeys together.`,
          category,
          leagueTier: 'LEAGUE_II',
          groupHealth: 85,
        },
      });
      logger.info(`Created new accountability group: ${group.name} (${group.id})`);
    }

    // Add user as member
    await prisma.groupMember.create({
      data: {
        groupId: group.id,
        userId,
        journeyId,
        role: 'MEMBER',
      },
    });

    // Update journey with groupId
    await prisma.journey.update({
      where: { id: journeyId },
      data: { groupId: group.id },
    });

    // Create feed activity
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { fullName: true },
    });

    const journey = await prisma.journey.findUnique({
      where: { id: journeyId },
      select: { title: true },
    });

    await prisma.feedActivity.create({
      data: {
        groupId: group.id,
        userId,
        journeyId,
        activityType: 'JOURNEY_STARTED',
        title: `${user?.fullName || 'A new member'} joined the group!`,
        content: `Starting journey: "${journey?.title || 'Personal Focus'}"`,
      },
    });

    logger.info(`Assigned user ${userId} to group ${group.id}`);
    return group;
  }

  async getGroupDetails(groupId: string, userId: string) {
    const group = await prisma.accountabilityGroup.findUnique({
      where: { id: groupId },
      include: {
        members: {
          include: {
            user: {
              select: {
                id: true,
                fullName: true,
                avatarUrl: true,
              },
            },
            journey: {
              select: {
                id: true,
                title: true,
                progressPercentage: true,
                status: true,
              },
            },
          },
        },
        feedActivities: {
          take: 20,
          orderBy: { createdAt: 'desc' },
          include: {
            user: {
              select: {
                id: true,
                fullName: true,
                avatarUrl: true,
              },
            },
            reactions: true,
          },
        },
      },
    });

    if (!group) {
      throw new NotFoundError('Accountability group not found');
    }

    return group;
  }

  async addFeedReaction(
    activityId: string,
    userId: string,
    reactionType: any
  ) {
    const activity = await prisma.feedActivity.findUnique({
      where: { id: activityId },
    });

    if (!activity) {
      throw new NotFoundError('Feed activity not found');
    }

    const existing = await prisma.feedReaction.findUnique({
      where: {
        activityId_userId: {
          activityId,
          userId,
        },
      },
    });

    if (existing) {
      if (existing.reactionType === reactionType) {
        // Toggle off
        await prisma.feedReaction.delete({
          where: { id: existing.id },
        });
        return { action: 'removed' };
      } else {
        // Update reaction
        const updated = await prisma.feedReaction.update({
          where: { id: existing.id },
          data: { reactionType },
        });
        return { action: 'updated', reaction: updated };
      }
    }

    const created = await prisma.feedReaction.create({
      data: {
        activityId,
        userId,
        reactionType,
      },
    });

    return { action: 'created', reaction: created };
  }
}

export const groupsService = new GroupsService();
