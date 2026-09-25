import { Injectable } from '@nestjs/common';
import { SubscriptionStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import {
  buildRenewalDedupeKey,
  buildReminderWindow,
} from './renewal-reminder.policy';

export interface ReminderCandidate {
  subscriptionId: string;
  userId: string;
  renewalDate: Date;
}

@Injectable()
export class RenewalReminderDiscoveryService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Finds ACTIVE subscriptions whose next_renewal_date falls inside the
   * catch-up eligibility window and that do not already have a durable
   * Notification occurrence (by dedupe_key) for that renewal date.
   *
   * This method never sends push and never touches DeviceRegistration; it
   * only identifies candidates for the caller to enqueue.
   */
  async findEligibleCandidates(
    now: Date = new Date(),
  ): Promise<ReminderCandidate[]> {
    const { start, end } = buildReminderWindow(now);

    const subscriptions = await this.prisma.userSubscription.findMany({
      where: {
        status: SubscriptionStatus.ACTIVE,
        next_renewal_date: {
          gte: start,
          lt: end,
        },
      },
      select: {
        id: true,
        user_id: true,
        next_renewal_date: true,
      },
    });

    if (subscriptions.length === 0) {
      return [];
    }

    const withDedupeKey = subscriptions.map((subscription) => ({
      subscription,
      dedupeKey: buildRenewalDedupeKey(
        subscription.id,
        subscription.next_renewal_date,
      ),
    }));

    const existing = await this.prisma.notification.findMany({
      where: {
        dedupe_key: { in: withDedupeKey.map((entry) => entry.dedupeKey) },
      },
      select: { dedupe_key: true },
    });
    const alreadyReminded = new Set(existing.map((row) => row.dedupe_key));

    return withDedupeKey
      .filter((entry) => !alreadyReminded.has(entry.dedupeKey))
      .map(({ subscription }) => ({
        subscriptionId: subscription.id,
        userId: subscription.user_id,
        renewalDate: subscription.next_renewal_date,
      }));
  }
}
