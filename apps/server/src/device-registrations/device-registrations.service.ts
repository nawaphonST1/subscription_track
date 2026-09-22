import { Injectable, Logger } from '@nestjs/common';
import {
  DevicePlatform,
  DeviceRegistrationStatus,
  Prisma,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RegisterDeviceDto } from './dto/register-device.dto';

export interface DeviceRegistrationResponse {
  id: string;
  platform: DevicePlatform;
  status: DeviceRegistrationStatus;
  createdAt: Date;
  updatedAt: Date;
}

export interface RegisterDeviceResult {
  registration: DeviceRegistrationResponse;
  isNew: boolean;
}

function isActiveTokenUniqueConflict(error: unknown): boolean {
  if (
    !(error instanceof Prisma.PrismaClientKnownRequestError) ||
    error.code !== 'P2002'
  ) {
    return false;
  }

  if (error.meta?.modelName !== 'DeviceRegistration') {
    return false;
  }

  const target = error.meta?.target;
  return (
    (Array.isArray(target) &&
      target.length === 1 &&
      target[0] === 'push_token') ||
    target === 'push_token'
  );
}

@Injectable()
export class DeviceRegistrationsService {
  private readonly logger = new Logger(DeviceRegistrationsService.name);

  constructor(private readonly prisma: PrismaService) {}

  async register(
    userId: string,
    dto: RegisterDeviceDto,
  ): Promise<RegisterDeviceResult> {
    try {
      return await this.executeRegister(userId, dto);
    } catch (error) {
      if (isActiveTokenUniqueConflict(error)) {
        this.logger.warn(
          `Concurrent active device-token conflict resolved via one bounded retry for user ${userId}`,
        );
        return await this.executeRegister(userId, dto);
      }
      throw error;
    }
  }

  private async executeRegister(
    userId: string,
    dto: RegisterDeviceDto,
  ): Promise<RegisterDeviceResult> {
    const { pushToken, platform } = dto;

    return this.prisma.$transaction(async (tx) => {
      // 1. Check for any currently ACTIVE registration with this push_token
      const activeRegistration = await tx.deviceRegistration.findFirst({
        where: {
          push_token: pushToken,
          status: DeviceRegistrationStatus.ACTIVE,
        },
      });

      if (activeRegistration) {
        // Case B & E: Same user + same token already active
        if (activeRegistration.user_id === userId) {
          if (activeRegistration.platform !== platform) {
            const updated = await tx.deviceRegistration.update({
              where: { id: activeRegistration.id },
              data: {
                platform,
              },
            });
            return {
              registration: this.mapToResponse(updated),
              isNew: false,
            };
          }
          return {
            registration: this.mapToResponse(activeRegistration),
            isNew: false,
          };
        }

        // Case C: Same token active for another user -> transfer ownership
        // Revoke active destination for previous user so it never remains active for two users
        await tx.deviceRegistration.update({
          where: { id: activeRegistration.id },
          data: {
            status: DeviceRegistrationStatus.REVOKED,
            deactivated_at: new Date(),
          },
        });
      }

      // 2. Check if the current user already has an inactive registration for this token (Case D)
      const existingUserRegistration = await tx.deviceRegistration.findFirst({
        where: {
          user_id: userId,
          push_token: pushToken,
        },
        orderBy: [{ updated_at: 'desc' }, { id: 'desc' }],
      });

      if (existingUserRegistration) {
        const reactivated = await tx.deviceRegistration.update({
          where: { id: existingUserRegistration.id },
          data: {
            platform,
            status: DeviceRegistrationStatus.ACTIVE,
            deactivated_at: null,
          },
        });
        return {
          registration: this.mapToResponse(reactivated),
          isNew: true,
        };
      }

      // Case A: First registration for authenticated user
      const created = await tx.deviceRegistration.create({
        data: {
          user_id: userId,
          push_token: pushToken,
          platform,
          status: DeviceRegistrationStatus.ACTIVE,
        },
      });

      return {
        registration: this.mapToResponse(created),
        isNew: true,
      };
    });
  }

  private mapToResponse(record: {
    id: string;
    platform: DevicePlatform;
    status: DeviceRegistrationStatus;
    created_at: Date;
    updated_at: Date;
  }): DeviceRegistrationResponse {
    return {
      id: record.id,
      platform: record.platform,
      status: record.status,
      createdAt: record.created_at,
      updatedAt: record.updated_at,
    };
  }
}
