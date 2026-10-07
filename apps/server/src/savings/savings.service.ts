import {
  ForbiddenException,
  Injectable,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '../prisma/prisma.service';
import { CacheService } from '../cache/cache.service';
import { BatchCancelDto } from './dto/batch-cancel.dto';
import {
  BillingCycle,
  NotificationType,
  SubscriptionStatus,
  UsageStatus,
} from '@prisma/client';
import { PinRateLimiter } from '../common/security/pin-rate-limiter.service';
import { isPinConfigured } from '../common/security/pin.util';

@Injectable()
export class SavingsService {
  private readonly rateLimiter: PinRateLimiter;

  constructor(
    private readonly prisma: PrismaService,
    @Optional() private readonly cacheService?: CacheService,
    @Optional() private readonly pinRateLimiter?: PinRateLimiter,
  ) {
    this.rateLimiter = pinRateLimiter ?? new PinRateLimiter();
  }

  private normalizeMonthlyCost(price: number, cycle: BillingCycle): number {
    switch (cycle) {
      case BillingCycle.WEEKLY:
        return (price * 52) / 12;
      case BillingCycle.YEARLY:
        return price / 12;
      case BillingCycle.MONTHLY:
      default:
        return price;
    }
  }

  async getPotentialSavings(userId: string) {
    let unusedSubscriptions = await this.prisma.userSubscription.findMany({
      where: {
        user_id: userId,
        status: SubscriptionStatus.ACTIVE,
        usage_status: UsageStatus.UNUSED,
        payment_card: { is_active: true },
      },
      include: {
        payment_card: {
          select: {
            card_nickname: true,
            last_4_digits: true,
            bank_name: true,
          },
        },
      },
      orderBy: { price: 'desc' },
    });

    if (unusedSubscriptions.length === 0) {
      unusedSubscriptions = await this.prisma.userSubscription.findMany({
        where: {
          user_id: userId,
          status: SubscriptionStatus.ACTIVE,
          payment_card: { is_active: true },
        },
        include: {
          payment_card: {
            select: {
              card_nickname: true,
              last_4_digits: true,
              bank_name: true,
            },
          },
        },
        orderBy: { price: 'desc' },
      });
    }

    let totalMonthlySavings = 0;
    let totalYearlySavings = 0;

    const items = unusedSubscriptions.map((sub) => {
      const monthly = this.normalizeMonthlyCost(
        Number(sub.price),
        sub.billing_cycle,
      );
      const yearly = monthly * 12;

      totalMonthlySavings += monthly;
      totalYearlySavings += yearly;

      return {
        id: sub.id,
        name: sub.name,
        category: sub.category,
        price: Number(sub.price),
        billing_cycle: sub.billing_cycle,
        normalized_monthly_cost: Number(monthly.toFixed(2)),
        yearly_savings_projection: Number(yearly.toFixed(2)),
        brand_color: sub.brand_color,
        payment_card: sub.payment_card,
      };
    });

    return {
      unused_subscriptions_count: items.length,
      total_monthly_savings: Number(totalMonthlySavings.toFixed(2)),
      total_yearly_savings_projection: Number(totalYearlySavings.toFixed(2)),
      recommended_cancellations: items,
    };
  }

  async batchCancel(userId: string, dto: BatchCancelDto) {
    this.rateLimiter.checkLockout(userId);

    // 1. Verify User & Security PIN
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

    const isPinValid = await bcrypt.compare(
      dto.security_pin,
      user.security_pin_hash,
    );
    if (!isPinValid) {
      this.rateLimiter.recordFailure(userId);
      throw new ForbiddenException('Invalid 6-digit security PIN');
    }

    this.rateLimiter.recordSuccess(userId);

    // 2. Fetch targets
    const subscriptions = await this.prisma.userSubscription.findMany({
      where: {
        id: { in: dto.subscription_ids },
        user_id: userId,
      },
    });

    if (subscriptions.length === 0) {
      throw new NotFoundException(
        'No matching subscriptions found for this user',
      );
    }

    const result = await this.prisma.$transaction(async (tx) => {
      let totalYearlySavings = 0;
      const cancellationLogs = [];

      for (const sub of subscriptions) {
        const monthly = this.normalizeMonthlyCost(
          Number(sub.price),
          sub.billing_cycle,
        );
        const yearly = monthly * 12;
        totalYearlySavings += yearly;

        // Set status to CANCELLED
        await tx.userSubscription.update({
          where: { id: sub.id },
          data: { status: SubscriptionStatus.CANCELLED },
        });

        // Add audit log
        const log = await tx.savingsCancellationLog.create({
          data: {
            user_id: userId,
            subscription_id: sub.id,
            subscription_name: sub.name,
            monthly_price: monthly,
            yearly_savings_projection: yearly,
            reason: 'Batch cancellation via Savings Optimizer',
          },
        });
        cancellationLogs.push(log);
      }

      // Notification
      await tx.notification.create({
        data: {
          user_id: userId,
          title: 'Batch Subscriptions Cancelled',
          message: `Successfully cancelled ${subscriptions.length} subscription(s). Unlocked ฿${totalYearlySavings.toFixed(2)} in projected yearly savings.`,
          type: NotificationType.SECURITY_ALERT,
        },
      });

      return {
        message: 'Subscriptions successfully cancelled',
        cancelled_count: subscriptions.length,
        total_yearly_savings_unlocked: Number(totalYearlySavings.toFixed(2)),
        cancelled_subscriptions: subscriptions.map((s) => ({
          id: s.id,
          name: s.name,
          category: s.category,
          price: Number(s.price),
          billing_cycle: s.billing_cycle,
        })),
      };
    });

    if (this.cacheService) {
      await this.cacheService.del(`cache:user:${userId}:creep-score`);
    }

    return result;
  }

  async getCancellationLogs(userId: string) {
    const logs = await this.prisma.savingsCancellationLog.findMany({
      where: { user_id: userId },
      orderBy: { cancelled_at: 'desc' },
    });

    return logs.map((l) => ({
      id: l.id,
      subscription_name: l.subscription_name,
      monthly_price: Number(l.monthly_price),
      yearly_savings_projection: Number(l.yearly_savings_projection),
      reason: l.reason,
      cancelled_at: l.cancelled_at,
    }));
  }
}
