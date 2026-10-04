import { beforeEach, describe, expect, it, vi } from 'vitest';
import { SubscriptionStatus } from '@prisma/client';
import { RenewalReminderDiscoveryService } from './renewal-reminder-discovery.service';
import { buildRenewalDedupeKey } from './renewal-reminder.policy';

describe('RenewalReminderDiscoveryService', () => {
  let service: RenewalReminderDiscoveryService;
  let prismaMock: any;
  const now = new Date('2026-10-05T12:00:00.000Z');

  function subscription(
    id: string,
    renewalDateIso: string,
    status: SubscriptionStatus = SubscriptionStatus.ACTIVE,
  ) {
    return {
      id,
      user_id: `user-${id}`,
      next_renewal_date: new Date(renewalDateIso),
      status,
    };
  }

  beforeEach(() => {
    prismaMock = {
      userSubscription: { findMany: vi.fn() },
      notification: { findMany: vi.fn() },
    };
    service = new RenewalReminderDiscoveryService(prismaMock);
  });

  it('includes a subscription renewing exactly at the 3-day lead time', async () => {
    prismaMock.userSubscription.findMany.mockResolvedValue([
      subscription('sub-8', '2026-10-08T00:00:00.000Z'),
    ]);
    prismaMock.notification.findMany.mockResolvedValue([]);

    const candidates = await service.findEligibleCandidates(now);

    expect(candidates).toHaveLength(1);
    expect(candidates[0].subscriptionId).toBe('sub-8');
  });

  it.each(['2026-10-07', '2026-10-06', '2026-10-05'])(
    'includes catch-up renewal on %s',
    async (date) => {
      prismaMock.userSubscription.findMany.mockResolvedValue([
        subscription('sub-x', `${date}T00:00:00.000Z`),
      ]);
      prismaMock.notification.findMany.mockResolvedValue([]);

      const candidates = await service.findEligibleCandidates(now);

      expect(candidates).toHaveLength(1);
    },
  );

  it('queries a window that excludes overdue (yesterday) and too-early (day 4) renewals', async () => {
    prismaMock.userSubscription.findMany.mockResolvedValue([]);
    prismaMock.notification.findMany.mockResolvedValue([]);

    const candidates = await service.findEligibleCandidates(now);

    expect(candidates).toHaveLength(0);
    expect(prismaMock.userSubscription.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          next_renewal_date: {
            gte: new Date('2026-10-05T00:00:00.000Z'),
            lt: new Date('2026-10-09T00:00:00.000Z'),
          },
        }),
      }),
    );
  });

  it('scopes the query to ACTIVE status only', async () => {
    prismaMock.userSubscription.findMany.mockResolvedValue([]);
    prismaMock.notification.findMany.mockResolvedValue([]);

    await service.findEligibleCandidates(now);

    expect(prismaMock.userSubscription.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ status: SubscriptionStatus.ACTIVE }),
      }),
    );
  });

  it('filters out subscriptions with an existing durable Notification dedupe key', async () => {
    const renewalDate = new Date('2026-10-08T00:00:00.000Z');
    prismaMock.userSubscription.findMany.mockResolvedValue([
      { id: 'sub-a', user_id: 'user-a', next_renewal_date: renewalDate },
      { id: 'sub-b', user_id: 'user-b', next_renewal_date: renewalDate },
    ]);
    prismaMock.notification.findMany.mockResolvedValue([
      { dedupe_key: buildRenewalDedupeKey('sub-a', renewalDate) },
    ]);

    const candidates = await service.findEligibleCandidates(now);

    expect(candidates).toHaveLength(1);
    expect(candidates[0].subscriptionId).toBe('sub-b');
  });

  it('returns multiple eligible candidates when several subscriptions qualify', async () => {
    prismaMock.userSubscription.findMany.mockResolvedValue([
      subscription('sub-1', '2026-10-05T00:00:00.000Z'),
      subscription('sub-2', '2026-10-06T00:00:00.000Z'),
      subscription('sub-3', '2026-10-08T00:00:00.000Z'),
    ]);
    prismaMock.notification.findMany.mockResolvedValue([]);

    const candidates = await service.findEligibleCandidates(now);

    expect(candidates.map((c) => c.subscriptionId)).toEqual([
      'sub-1',
      'sub-2',
      'sub-3',
    ]);
  });

  it('returns no candidates when nothing is eligible', async () => {
    prismaMock.userSubscription.findMany.mockResolvedValue([]);
    prismaMock.notification.findMany.mockResolvedValue([]);

    const candidates = await service.findEligibleCandidates(now);

    expect(candidates).toEqual([]);
    expect(prismaMock.notification.findMany).not.toHaveBeenCalled();
  });

  it('never touches DeviceRegistration', async () => {
    prismaMock.userSubscription.findMany.mockResolvedValue([]);
    prismaMock.notification.findMany.mockResolvedValue([]);

    await service.findEligibleCandidates(now);

    expect(prismaMock.deviceRegistration).toBeUndefined();
  });
});
