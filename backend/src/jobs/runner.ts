import { logger } from '../common/logger';
import { disconnectPrisma } from '../database/prisma';
import { runJourneyActivator } from './journey-activator.job';
import { runSessionGenerator } from './session-generator.job';
import { runMissedSessionsDetector } from './missed-sessions.job';
import { runReminderNotifications } from './reminder-notifications.job';

async function main() {
  const startTime = Date.now();
  logger.info('=== Starting FinishX Scheduled Background Jobs Runner ===');

  try {
    logger.info('[1/4] Running Journey Activator Job...');
    const activatedJourneys = await runJourneyActivator();

    logger.info('[2/4] Running Session Generator Job...');
    const generatedSessions = await runSessionGenerator();

    logger.info('[3/4] Running Missed Sessions Detector Job...');
    const missedSessions = await runMissedSessionsDetector();

    logger.info('[4/4] Running Reminder Notifications Job...');
    const remindersSent = await runReminderNotifications();

    const elapsed = Date.now() - startTime;
    logger.info(
      `=== All FinishX Jobs Completed Successfully in ${elapsed}ms ===\n` +
        `Summary:\n` +
        ` - Activated Journeys: ${activatedJourneys}\n` +
        ` - Generated Sessions: ${generatedSessions}\n` +
        ` - Missed Sessions Handled: ${missedSessions}\n` +
        ` - Push Reminders Sent: ${remindersSent}`
    );

    await disconnectPrisma();
    process.exit(0);
  } catch (error) {
    logger.error('Fatal error during background job execution:', error);
    await disconnectPrisma().catch(() => {});
    process.exit(1);
  }
}

main();
