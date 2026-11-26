import { prisma } from '../../database/prisma';
import { NotFoundError } from '../../common/errors/app-error';
import { UpdateProfileInput, UpdateTimezoneInput } from './users.schema';

export class UsersService {
  async getProfile(userId: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        fullName: true,
        avatarUrl: true,
        timezone: true,
        authProvider: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    if (!user) {
      throw new NotFoundError('User not found');
    }

    return user;
  }

  async updateProfile(userId: string, input: UpdateProfileInput) {
    const user = await prisma.user.update({
      where: { id: userId },
      data: {
        ...(input.fullName !== undefined ? { fullName: input.fullName } : {}),
        ...(input.timezone !== undefined ? { timezone: input.timezone } : {}),
        ...(input.avatarUrl !== undefined ? { avatarUrl: input.avatarUrl } : {}),
      },
      select: {
        id: true,
        email: true,
        fullName: true,
        avatarUrl: true,
        timezone: true,
        updatedAt: true,
      },
    });

    return user;
  }

  async updateTimezone(userId: string, input: UpdateTimezoneInput) {
    return prisma.user.update({
      where: { id: userId },
      data: { timezone: input.timezone },
      select: {
        id: true,
        timezone: true,
        updatedAt: true,
      },
    });
  }

  async deleteAccount(userId: string) {
    await prisma.user.delete({
      where: { id: userId },
    });
  }
}

export const usersService = new UsersService();
