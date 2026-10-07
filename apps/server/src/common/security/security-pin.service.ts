import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '../../prisma/prisma.service';
import { isPinConfigured } from './pin.util';
import { PinRateLimiter } from './pin-rate-limiter.service';

@Injectable()
export class SecurityPinService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly rateLimiter: PinRateLimiter,
  ) {}

  /**
   * Authoritatively verifies that the user's PIN is configured and matches the submitted PIN.
   * Throws BadRequestException if PIN is missing or invalid format.
   * Throws ForbiddenException if PIN is not configured or incorrect.
   * Throws HttpException (429) if rate limited.
   */
  async verifyPin(userId: string, pin?: string): Promise<boolean> {
    this.rateLimiter.checkLockout(userId);

    if (!pin || typeof pin !== 'string' || !/^\d{6}$/.test(pin)) {
      throw new BadRequestException('Security PIN must be exactly 6 digits');
    }

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { security_pin_hash: true },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const configured = await isPinConfigured(user.security_pin_hash);
    if (!configured) {
      this.rateLimiter.recordFailure(userId);
      throw new ForbiddenException(
        'Security PIN is not configured or has been reset',
      );
    }

    const isValid = await bcrypt.compare(pin, user.security_pin_hash);
    if (!isValid) {
      this.rateLimiter.recordFailure(userId);
      throw new ForbiddenException('Invalid 6-digit security PIN');
    }

    this.rateLimiter.recordSuccess(userId);
    return true;
  }
}
