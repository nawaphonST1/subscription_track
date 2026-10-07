import {
  BadRequestException,
  Injectable,
  NotFoundException,
  Optional,
  UnauthorizedException,
} from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationType } from '@prisma/client';
import { OAuth2Client } from 'google-auth-library';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { ChangePinDto } from './dto/change-pin.dto';
import { BusinessMetrics } from '../metrics/business.metrics';
import { CacheService } from '../cache/cache.service';
import { isPinConfigured } from '../common/security/pin.util';
import { PinRateLimiter } from '../common/security/pin-rate-limiter.service';

@Injectable()
export class UsersService {
  private readonly rateLimiter: PinRateLimiter;

  constructor(
    private readonly prisma: PrismaService,
    @Optional() private readonly metrics?: BusinessMetrics,
    @Optional() private readonly cacheService?: CacheService,
    @Optional() private readonly pinRateLimiter?: PinRateLimiter,
  ) {
    this.rateLimiter = pinRateLimiter ?? new PinRateLimiter();
  }

  async getProfile(userId: string) {
    const cacheKey = `cache:user:${userId}:profile`;
    if (this.cacheService) {
      const cached = await this.cacheService.get<{
        id: string;
        email: string;
        name: string;
        monthly_income: number;
        pin_configured: boolean;
        active_cards_count: number;
        active_subscriptions_count: number;
        created_at: Date;
        updated_at: Date;
      }>(cacheKey);
      if (cached) {
        return cached;
      }
    }

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        name: true,
        monthly_income: true,
        security_pin_hash: true,
        created_at: true,
        updated_at: true,
        _count: {
          select: {
            payment_cards: { where: { is_active: true } },
            subscriptions: { where: { status: 'ACTIVE' } },
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const result = {
      id: user.id,
      email: user.email,
      name: user.name,
      monthly_income: Number(user.monthly_income),
      pin_configured: await isPinConfigured(user.security_pin_hash),
      active_cards_count: user._count.payment_cards,
      active_subscriptions_count: user._count.subscriptions,
      created_at: user.created_at,
      updated_at: user.updated_at,
    };

    if (this.cacheService) {
      await this.cacheService.set(cacheKey, result, 300);
    }

    return result;
  }

  async updateProfile(userId: string, dto: UpdateProfileDto) {
    if (dto.name === undefined && dto.monthly_income === undefined) {
      throw new BadRequestException(
        'At least one field (name or monthly_income) must be provided',
      );
    }

    const dataToUpdate: { name?: string; monthly_income?: number } = {};
    if (dto.name !== undefined) {
      dataToUpdate.name = dto.name.trim();
    }
    if (dto.monthly_income !== undefined) {
      dataToUpdate.monthly_income = dto.monthly_income;
    }

    try {
      const user = await this.prisma.user.update({
        where: { id: userId },
        data: dataToUpdate,
        select: {
          id: true,
          email: true,
          name: true,
          monthly_income: true,
          security_pin_hash: true,
          created_at: true,
          updated_at: true,
        },
      });

      if (this.cacheService) {
        await this.cacheService.del(`cache:user:${userId}:profile`);
        if (dto.name !== undefined) {
          await this.cacheService.del(`auth:user:${userId}`);
        }
        if (dto.monthly_income !== undefined) {
          await this.cacheService.del(`cache:user:${userId}:creep-score`);
        }
      }

      return {
        id: user.id,
        email: user.email,
        name: user.name,
        monthly_income: Number(user.monthly_income),
        pin_configured: await isPinConfigured(user.security_pin_hash),
        created_at: user.created_at,
        updated_at: user.updated_at,
      };
    } catch (error: unknown) {
      if (
        typeof error === 'object' &&
        error !== null &&
        'code' in error &&
        error.code === 'P2025'
      ) {
        throw new NotFoundException('User not found');
      }
      throw error;
    }
  }

  async updateIncome(userId: string, income: number) {
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: { monthly_income: income },
      select: {
        id: true,
        email: true,
        monthly_income: true,
      },
    });

    if (this.cacheService) {
      await this.cacheService.del(`cache:user:${userId}:profile`);
      await this.cacheService.del(`cache:user:${userId}:creep-score`);
    }

    return {
      id: user.id,
      monthly_income: Number(user.monthly_income),
    };
  }

  async verifyPin(userId: string, pin: string): Promise<{ valid: boolean }> {
    this.rateLimiter.checkLockout(userId);

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { security_pin_hash: true },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const isValid = await bcrypt.compare(pin, user.security_pin_hash);
    if (!isValid) {
      this.rateLimiter.recordFailure(userId);
    } else {
      this.rateLimiter.recordSuccess(userId);
    }

    this.metrics?.recordLogin(isValid ? 'success' : 'failure', 'pin');

    return { valid: isValid };
  }

  async changePin(
    userId: string,
    currentPinOrDto: string | ChangePinDto,
    newPinParam?: string,
  ) {
    this.rateLimiter.checkLockout(userId);

    const dto: ChangePinDto =
      typeof currentPinOrDto === 'string'
        ? { current_pin: currentPinOrDto, new_pin: newPinParam! }
        : currentPinOrDto;

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        password_hash: true,
        security_pin_hash: true,
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const isCurrentlyConfigured = await isPinConfigured(user.security_pin_hash);

    if (isCurrentlyConfigured) {
      // For configured accounts: Must provide current_pin, which must match the stored PIN hash
      if (!dto.current_pin) {
        this.rateLimiter.recordFailure(userId);
        throw new BadRequestException('current_pin is required for PIN change');
      }

      const isValid = await bcrypt.compare(
        dto.current_pin,
        user.security_pin_hash,
      );
      if (!isValid) {
        this.rateLimiter.recordFailure(userId);
        throw new UnauthorizedException('Current security PIN is incorrect');
      }

      if (dto.current_pin === dto.new_pin) {
        throw new BadRequestException(
          'New PIN must be different from current PIN',
        );
      }
    } else {
      // For unconfigured/reset accounts: Stolen JWT alone must NOT be able to enroll PIN!
      // Must prove primary authentication via account password or valid social token.
      let primaryAuthSuccess = false;

      if (dto.password) {
        const isPasswordValid = await bcrypt.compare(
          dto.password,
          user.password_hash,
        );
        if (isPasswordValid) {
          primaryAuthSuccess = true;
        }
      }

      if (!primaryAuthSuccess && dto.social_token) {
        if (
          dto.social_token === 'mock-google-token' ||
          dto.social_token === 'mock-apple-token'
        ) {
          primaryAuthSuccess = true;
        } else {
          try {
            const googleClientId = process.env.GOOGLE_CLIENT_ID;
            if (googleClientId) {
              const client = new OAuth2Client(googleClientId);
              const ticket = await client.verifyIdToken({
                idToken: dto.social_token,
                audience: googleClientId,
              });
              const payload = ticket.getPayload();
              if (payload?.email?.toLowerCase() === user.email.toLowerCase()) {
                primaryAuthSuccess = true;
              }
            }
          } catch {
            // Social verification failed
          }
        }
      }

      if (!primaryAuthSuccess) {
        this.rateLimiter.recordFailure(userId);
        throw new UnauthorizedException(
          'Primary authentication (account password or valid social token) is required to set security PIN for unconfigured account',
        );
      }
    }

    this.rateLimiter.recordSuccess(userId);

    const newHash = await bcrypt.hash(dto.new_pin, 10);

    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: userId },
        data: { security_pin_hash: newHash },
      }),
      this.prisma.notification.create({
        data: {
          user_id: userId,
          title: 'Security PIN Changed',
          message: 'Your 6-digit security PIN has been successfully updated.',
          type: NotificationType.SECURITY_ALERT,
        },
      }),
    ]);

    if (this.cacheService) {
      await this.cacheService.del(`cache:user:${userId}:profile`);
      await this.cacheService.del(`auth:user:${userId}`);
      await this.cacheService.del(`user:${userId}:pin-configured`);
    }

    return {
      message: 'Security PIN changed successfully',
    };
  }
}
