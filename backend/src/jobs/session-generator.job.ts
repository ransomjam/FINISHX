import { prisma } from '../database/prisma';
import { logger } from '../common/logger';
import { commitmentsService } from '../modules/commitments/commitments.service';

export async function runSessionGenerator(): Promise<number> {
  const activeJourneys = await prisma.journey.findMany({
    where: { status: 'ACTIVE' },
    select: { id: true, title: true },
  });

  let totalGenerated = 0;

  for (const j of activeJourneys) {
    try {
      const generated = await commitmentsService.generateSessionsForJourney(j.id, 28);
      totalGenerated += generated;
    } catch (err) {
      logger.error(`Failed to generate sessions for journey ${j.id}:`, err);
    }
  }

  logger.info(`Session generator job complete: ${totalGenerated} sessions generated across ${activeJourneys.length} journeys`);
  return totalGenerated;
}
