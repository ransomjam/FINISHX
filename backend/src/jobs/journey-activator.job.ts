import { prisma } from '../database/prisma';
import { logger } from '../common/logger';
import { commitmentsService } from '../modules/commitments/commitments.service';
import { groupsService } from '../modules/groups/groups.service';

export async function runJourneyActivator(): Promise<number> {
  const now = new Date();
  const scheduledJourneys = await prisma.journey.findMany({
    where: {
      status: 'SCHEDULED',
      startDate: { lte: now },
    },
  });

  let activatedCount = 0;

  for (const journey of scheduledJourneys) {
    try {
      // Check if user already has an active journey
      const existingActive = await prisma.journey.findFirst({
        where: {
          userId: journey.userId,
          status: 'ACTIVE',
          id: { not: journey.id },
        },
      });

      if (existingActive) {
        // Keep in queue/scheduled until active finishes
        continue;
      }

      await prisma.journey.update({
        where: { id: journey.id },
        data: { status: 'ACTIVE' },
      });

      await groupsService.autoAssignGroup(journey.userId, journey.id, journey.category);
      await commitmentsService.generateSessionsForJourney(journey.id);

      activatedCount++;
      logger.info(`Activated scheduled journey: ${journey.id} ("${journey.title}")`);
    } catch (err) {
      logger.error(`Failed to activate scheduled journey ${journey.id}:`, err);
    }
  }

  return activatedCount;
}
