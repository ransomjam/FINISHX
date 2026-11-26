import argon2 from 'argon2';
import jwt from 'jsonwebtoken';
import { OAuth2Client } from 'google-auth-library';
import { prisma } from '../../database/prisma';
import { config } from '../../config';
import {
  BadRequestError,
  ConflictError,
  NotFoundError,
  UnauthorizedError,
} from '../../common/errors/app-error';
import { logger } from '../../common/logger';
import {
  RegisterInput,
  LoginInput,
  RefreshTokenInput,
  GoogleAuthInput,
} from './auth.schema';

const googleClient = new OAuth2Client();

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresIn: number; // in seconds
  tokenType: string;
}

export interface UserSummary {
  id: string;
  email: string;
  fullName: string;
  avatarUrl: string | null;
  timezone: string;
  hasActiveJourney: boolean;
  activeJourneyId?: string | null;
  createdAt: Date;
}

export class AuthService {
  private generateTokens(userId: string, email: string, tokenId: string): AuthTokens {
    const accessToken = jwt.sign(
      { userId, email },
      config.JWT_ACCESS_SECRET,
      { expiresIn: config.JWT_ACCESS_EXPIRES_IN as any }
    );

    const refreshToken = jwt.sign(
      { userId, tokenId },
      config.JWT_REFRESH_SECRET,
      { expiresIn: config.JWT_REFRESH_EXPIRES_IN as any }
    );

    return {
      accessToken,
      refreshToken,
      expiresIn: 15 * 60, // 15 minutes in seconds
      tokenType: 'Bearer',
    };
  }

  async register(input: RegisterInput): Promise<{ user: UserSummary; tokens: AuthTokens }> {
    const existing = await prisma.user.findUnique({
      where: { email: input.email },
    });

    if (existing) {
      throw new ConflictError('An account with this email already exists');
    }

    const hashedPassword = await argon2.hash(input.password);

    const user = await prisma.user.create({
      data: {
        email: input.email,
        passwordHash: hashedPassword,
        fullName: input.fullName,
        timezone: input.timezone || 'UTC',
        authProvider: 'LOCAL',
      },
    });

    // Create a refresh token record
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 30); // 30 days

    const refreshTokenRecord = await prisma.refreshToken.create({
      data: {
        userId: user.id,
        token: 'pending',
        expiresAt,
      },
    });

    const tokens = this.generateTokens(user.id, user.email, refreshTokenRecord.id);

    // Update with actual hashed or raw token for lookup
    await prisma.refreshToken.update({
      where: { id: refreshTokenRecord.id },
      data: { token: tokens.refreshToken },
    });

    logger.info(`User registered successfully: ${user.id}`);

    return {
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        avatarUrl: user.avatarUrl,
        timezone: user.timezone,
        hasActiveJourney: false,
        createdAt: user.createdAt,
      },
      tokens,
    };
  }

  async login(input: LoginInput): Promise<{ user: UserSummary; tokens: AuthTokens }> {
    const user = await prisma.user.findUnique({
      where: { email: input.email },
      include: {
        journeys: {
          where: { status: { in: ['ACTIVE', 'PAUSED'] } },
          select: { id: true },
          take: 1,
        },
      },
    });

    if (!user || !user.passwordHash) {
      throw new UnauthorizedError('Invalid email or password');
    }

    const validPassword = await argon2.verify(user.passwordHash, input.password);
    if (!validPassword) {
      throw new UnauthorizedError('Invalid email or password');
    }

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 30);

    const refreshTokenRecord = await prisma.refreshToken.create({
      data: {
        userId: user.id,
        token: 'pending',
        expiresAt,
      },
    });

    const tokens = this.generateTokens(user.id, user.email, refreshTokenRecord.id);

    await prisma.refreshToken.update({
      where: { id: refreshTokenRecord.id },
      data: { token: tokens.refreshToken },
    });

    logger.info(`User logged in: ${user.id}`);

    const activeJourney = user.journeys[0];

    return {
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        avatarUrl: user.avatarUrl,
        timezone: user.timezone,
        hasActiveJourney: !!activeJourney,
        activeJourneyId: activeJourney?.id ?? null,
        createdAt: user.createdAt,
      },
      tokens,
    };
  }

  async refreshTokens(input: RefreshTokenInput): Promise<AuthTokens> {
    try {
      const payload = jwt.verify(input.refreshToken, config.JWT_REFRESH_SECRET) as {
        userId: string;
        tokenId: string;
      };

      const tokenRecord = await prisma.refreshToken.findUnique({
        where: { id: payload.tokenId },
        include: { user: true },
      });

      if (!tokenRecord || tokenRecord.isRevoked || tokenRecord.expiresAt < new Date()) {
        // If token reuse detected or invalid, revoke all tokens for this user for security
        if (tokenRecord?.isRevoked) {
          logger.warn(`Revoked refresh token reuse detected for user: ${tokenRecord.userId}`);
          await prisma.refreshToken.updateMany({
            where: { userId: tokenRecord.userId },
            data: { isRevoked: true },
          });
        }
        throw new UnauthorizedError('Invalid or expired refresh token');
      }

      // Revoke current token (rotation)
      await prisma.refreshToken.update({
        where: { id: tokenRecord.id },
        data: { isRevoked: true },
      });

      // Issue new token
      const expiresAt = new Date();
      expiresAt.setDate(expiresAt.getDate() + 30);

      const newRecord = await prisma.refreshToken.create({
        data: {
          userId: tokenRecord.userId,
          token: 'pending',
          expiresAt,
        },
      });

      const tokens = this.generateTokens(tokenRecord.userId, tokenRecord.user.email, newRecord.id);

      await prisma.refreshToken.update({
        where: { id: newRecord.id },
        data: { token: tokens.refreshToken },
      });

      return tokens;
    } catch (err: any) {
      if (err instanceof UnauthorizedError) throw err;
      throw new UnauthorizedError('Invalid or expired refresh token');
    }
  }

  async logout(userId: string, refreshToken?: string): Promise<void> {
    if (refreshToken) {
      try {
        const payload = jwt.verify(refreshToken, config.JWT_REFRESH_SECRET) as { tokenId: string };
        await prisma.refreshToken.updateMany({
          where: { id: payload.tokenId, userId },
          data: { isRevoked: true },
        });
      } catch {
        // Best effort
      }
    } else {
      // Revoke all tokens for user
      await prisma.refreshToken.updateMany({
        where: { userId },
        data: { isRevoked: true },
      });
    }
    logger.info(`User logged out: ${userId}`);
  }

  async googleAuth(input: GoogleAuthInput): Promise<{ user: UserSummary; tokens: AuthTokens }> {
    let email: string | undefined;
    let name: string | undefined;
    let googleId: string | undefined;
    let avatarUrl: string | undefined;

    try {
      const ticket = await googleClient.verifyIdToken({
        idToken: input.idToken,
      });
      const payload = ticket.getPayload();
      if (!payload || !payload.email) {
        throw new BadRequestError('Invalid Google token: missing email');
      }
      email = payload.email;
      name = payload.name || payload.email.split('@')[0];
      googleId = payload.sub;
      avatarUrl = payload.picture;
    } catch (err) {
      // In development mode or test environments, allow simulated Google auth if token is structured
      if (config.NODE_ENV !== 'production' && input.idToken.startsWith('mock_')) {
        email = `mock_${input.idToken.replace('mock_', '')}@gmail.com`;
        name = 'Google User';
        googleId = `google_${Date.now()}`;
      } else {
        throw new UnauthorizedError('Invalid Google authentication token');
      }
    }

    let user = await prisma.user.findFirst({
      where: {
        OR: [{ email }, { googleId }],
      },
      include: {
        journeys: {
          where: { status: { in: ['ACTIVE', 'PAUSED'] } },
          select: { id: true },
          take: 1,
        },
      },
    });

    if (!user) {
      user = await prisma.user.create({
        data: {
          email,
          fullName: name || 'Google User',
          googleId,
          avatarUrl,
          authProvider: 'GOOGLE',
          emailVerified: true,
        },
        include: {
          journeys: {
            where: { status: { in: ['ACTIVE', 'PAUSED'] } },
            select: { id: true },
            take: 1,
          },
        },
      });
    } else if (!user.googleId && googleId) {
      user = await prisma.user.update({
        where: { id: user.id },
        data: { googleId, avatarUrl: avatarUrl || user.avatarUrl },
        include: {
          journeys: {
            where: { status: { in: ['ACTIVE', 'PAUSED'] } },
            select: { id: true },
            take: 1,
          },
        },
      });
    }

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 30);

    const refreshTokenRecord = await prisma.refreshToken.create({
      data: {
        userId: user.id,
        token: 'pending',
        expiresAt,
      },
    });

    const tokens = this.generateTokens(user.id, user.email, refreshTokenRecord.id);

    await prisma.refreshToken.update({
      where: { id: refreshTokenRecord.id },
      data: { token: tokens.refreshToken },
    });

    const activeJourney = user.journeys[0];

    return {
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        avatarUrl: user.avatarUrl,
        timezone: user.timezone,
        hasActiveJourney: !!activeJourney,
        activeJourneyId: activeJourney?.id ?? null,
        createdAt: user.createdAt,
      },
      tokens,
    };
  }

  async getMe(userId: string): Promise<UserSummary> {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        journeys: {
          where: { status: { in: ['ACTIVE', 'PAUSED'] } },
          select: { id: true },
          take: 1,
        },
      },
    });

    if (!user) {
      throw new NotFoundError('User not found');
    }

    const activeJourney = user.journeys[0];

    return {
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      avatarUrl: user.avatarUrl,
      timezone: user.timezone,
      hasActiveJourney: !!activeJourney,
      activeJourneyId: activeJourney?.id ?? null,
      createdAt: user.createdAt,
    };
  }
}

export const authService = new AuthService();
