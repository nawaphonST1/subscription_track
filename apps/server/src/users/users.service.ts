import {
  BadRequestException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationType } from '@prisma/client';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async getProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        name: true,
        monthly_income: true,
        created_at: true,
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

    return {
      id: user.id,
      email: user.email,
      name: user.name,
      monthly_income: Number(user.monthly_income),
      active_cards_count: user._count.payment_cards,
      active_subscriptions_count: user._count.subscriptions,
      created_at: user.created_at,
    };
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

    return {
      id: user.id,
      monthly_income: Number(user.monthly_income),
    };
  }

  async verifyPin(userId: string, pin: string): Promise<{ valid: boolean }> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { security_pin_hash: true },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const isValid = await bcrypt.compare(pin, user.security_pin_hash);
    return { valid: isValid };
  }

  async changePin(userId: string, currentPin: string, newPin: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { security_pin_hash: true },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const isValid = await bcrypt.compare(currentPin, user.security_pin_hash);
    if (!isValid) {
      throw new UnauthorizedException('Current security PIN is incorrect');
    }

    if (currentPin === newPin) {
      throw new BadRequestException(
        'New PIN must be different from current PIN',
      );
    }

    const newHash = await bcrypt.hash(newPin, 10);

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

    return {
      message: 'Security PIN changed successfully',
    };
  }
}
