import admin from 'firebase-admin';
import { config } from '../../config';
import { logger } from '../../common/logger';

class FcmService {
  private initialized = false;

  constructor() {
    this.initialize();
  }

  private initialize(): void {
    if (this.initialized) return;

    if (
      config.FIREBASE_PROJECT_ID &&
      config.FIREBASE_CLIENT_EMAIL &&
      config.FIREBASE_PRIVATE_KEY
    ) {
      try {
        const privateKey = config.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n');
        admin.initializeApp({
          credential: admin.credential.cert({
            projectId: config.FIREBASE_PROJECT_ID,
            clientEmail: config.FIREBASE_CLIENT_EMAIL,
            privateKey,
          }),
        });
        this.initialized = true;
        logger.info('Firebase Admin SDK initialized successfully');
      } catch (err) {
        logger.warn('Failed to initialize Firebase Admin SDK:', err);
      }
    } else {
      logger.info('Firebase credentials not provided; FCM push notifications running in mock mode');
    }
  }

  async sendPushNotification(
    tokens: string[],
    title: string,
    body: string,
    data?: Record<string, string>
  ): Promise<{ successCount: number; failureCount: number }> {
    if (!tokens || tokens.length === 0) {
      return { successCount: 0, failureCount: 0 };
    }

    if (!this.initialized) {
      logger.info(`[MOCK FCM] Sending push to ${tokens.length} tokens: "${title}" - "${body}"`);
      return { successCount: tokens.length, failureCount: 0 };
    }

    try {
      const response = await admin.messaging().sendEachForMulticast({
        tokens,
        notification: {
          title,
          body,
        },
        data,
      });

      logger.info(
        `FCM push sent: ${response.successCount} succeeded, ${response.failureCount} failed`
      );
      return {
        successCount: response.successCount,
        failureCount: response.failureCount,
      };
    } catch (error) {
      logger.error('Error sending FCM push notification:', error);
      return { successCount: 0, failureCount: tokens.length };
    }
  }
}

export const fcmService = new FcmService();
