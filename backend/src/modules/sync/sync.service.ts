import { prisma } from '../../database/prisma';
import { logger } from '../../common/logger';
import { SyncBatchInput } from './sync.schema';
import { sessionsService } from '../sessions/sessions.service';
import { journeysService } from '../journeys/journeys.service';
import { reflectionsService } from '../reflections/reflections.service';

export class SyncService {
  async processBatch(userId: string, input: SyncBatchInput) {
    const processedIds: string[] = [];
    const failedIds: { id: string; error: string }[] = [];

    for (const item of input.events) {
      try {
        // Idempotency check: see if event was already recorded
        const existing = await prisma.syncEvent.findUnique({
          where: { id: item.id },
        });

        if (existing) {
          processedIds.push(item.id);
          continue;
        }

        // Record incoming event
        await prisma.syncEvent.create({
          data: {
            id: item.id,
            userId,
            eventType: item.eventType,
            payload: item.payload,
            clientTimestamp: new Date(item.clientTimestamp),
            deviceId: item.deviceId,
            status: 'RECEIVED',
          },
        });

        // Dispatch based on eventType
        await this.handleEvent(userId, item);

        // Mark event as PROCESSED
        await prisma.syncEvent.update({
          where: { id: item.id },
          data: { status: 'PROCESSED' },
        });

        processedIds.push(item.id);
      } catch (err: any) {
        logger.error(`Error processing sync event ${item.id} (${item.eventType}):`, err);
        failedIds.push({ id: item.id, error: err.message || 'Processing failed' });

        // Record failure in SyncEvent
        await prisma.syncEvent.upsert({
          where: { id: item.id },
          update: { status: 'FAILED' },
          create: {
            id: item.id,
            userId,
            eventType: item.eventType,
            payload: item.payload,
            clientTimestamp: new Date(item.clientTimestamp),
            deviceId: item.deviceId,
            status: 'FAILED',
          },
        }).catch(() => {});
      }
    }

    return {
      success: true,
      processedCount: processedIds.length,
      failedCount: failedIds.length,
      processedIds,
      failedIds,
      serverTime: new Date().toISOString(),
    };
  }

  private async handleEvent(userId: string, item: any): Promise<void> {
    const { eventType, payload } = item;

    switch (eventType) {
      case 'session.start':
        if (payload.sessionId) {
          await sessionsService.startSession(payload.sessionId, userId, {
            startedAt: payload.startedAt || item.clientTimestamp,
          });
        }
        break;

      case 'session.end':
        if (payload.sessionId) {
          await sessionsService.endSession(payload.sessionId, userId, {
            actualDurationMinutes: payload.actualDurationMinutes || payload.durationMinutes || 25,
            completedAt: payload.completedAt || item.clientTimestamp,
            notes: payload.notes,
            feeling: payload.feeling,
            rating: payload.rating,
          });
        }
        break;

      case 'journey.pause':
        if (payload.journeyId) {
          await journeysService.pauseJourney(payload.journeyId, userId, {
            reason: payload.reason || 'OTHER',
            notes: payload.notes,
          });
        }
        break;

      case 'reflection.weekly':
        if (payload.journeyId) {
          await reflectionsService.submitWeeklyReflection(userId, {
            journeyId: payload.journeyId,
            completedCommitments: payload.completedCommitments || 'YES',
            biggestWin: payload.biggestWin || 'Completed focus goals',
            biggestChallenge: payload.biggestChallenge || 'Time management',
            nextWeekFocus: payload.nextWeekFocus || 'Keep momentum',
            weekNumber: payload.weekNumber,
          });
        }
        break;

      default:
        logger.info(`Unknown or informational sync event: ${eventType}`);
        break;
    }
  }
}

export const syncService = new SyncService();
