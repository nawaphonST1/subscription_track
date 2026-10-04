import { beforeEach, describe, expect, it, vi } from 'vitest';
import { DeviceRegistrationStatus, SubscriptionStatus } from '@prisma/client';
import { RenewalReminderProcessor } from './renewal-reminder.processor';
import {
  RENEWAL_DISCOVERY_JOB,
  RENEWAL_SEND_JOB,
} from '../queue/renewal-reminder.queue';

function job(name: string, data: any = {}) {
  return { name, data } as any;
}

describe('RenewalReminderProcessor', () => {
  let processor: RenewalReminderProcessor;
  let prismaMock: any;
  let notificationsServiceMock: any;
  let discoveryServiceMock: any;
  let queueMock: any;
  let pushProviderMock: any;

  const now = new Date('2026-10-05T12:00:00.000Z');

  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(now);

    prismaMock = {
      userSubscription: { findUnique: vi.fn() },
      deviceRegistration: { findMany: vi.fn(), updateMany: vi.fn() },
    };
    notificationsServiceMock = {
      ensureRenewalNotification: vi.fn().mockResolvedValue({ id: 'notif-1' }),
    };
    discoveryServiceMock = { findEligibleCandidates: vi.fn() };
    queueMock = { add: vi.fn() };
    pushProviderMock = { send: vi.fn() };

    processor = new RenewalReminderProcessor(
      prismaMock,
      notificationsServiceMock,
      discoveryServiceMock,
      queueMock,
      pushProviderMock,
    );
  });

  function activeSubscription(
    overrides: Partial<Record<string, unknown>> = {},
  ) {
    return {
      id: 'sub-1',
      user_id: 'user-1',
      name: 'Netflix',
      status: SubscriptionStatus.ACTIVE,
      next_renewal_date: new Date('2026-10-08T00:00:00.000Z'),
      ...overrides,
    };
  }

  function activeDevice(id: string, pushToken = `token-${id}`) {
    return { id, push_token: pushToken };
  }

  describe('unsupported job names', () => {
    it('throws instead of silently ignoring an unknown job', async () => {
      await expect(processor.process(job('some-other-job'))).rejects.toThrow(
        'Unsupported renewal reminder job',
      );
    });
  });

  describe('discovery job', () => {
    it('enqueues one reminder job per eligible candidate with reference-only data', async () => {
      discoveryServiceMock.findEligibleCandidates.mockResolvedValue([
        {
          subscriptionId: 'sub-1',
          userId: 'user-1',
          renewalDate: new Date('2026-10-08T00:00:00.000Z'),
        },
      ]);

      await processor.process(job(RENEWAL_DISCOVERY_JOB));

      expect(queueMock.add).toHaveBeenCalledWith(
        RENEWAL_SEND_JOB,
        { subscriptionId: 'sub-1', renewalDate: '2026-10-08' },
        expect.objectContaining({ jobId: 'remind-sub-1-2026-10-08' }),
      );
    });

    it('enqueues nothing when there are no eligible candidates', async () => {
      discoveryServiceMock.findEligibleCandidates.mockResolvedValue([]);

      await processor.process(job(RENEWAL_DISCOVERY_JOB));

      expect(queueMock.add).not.toHaveBeenCalled();
    });
  });

  describe('reminder job stale checks', () => {
    it('does nothing when the subscription no longer exists', async () => {
      prismaMock.userSubscription.findUnique.mockResolvedValue(null);

      await processor.process(
        job(RENEWAL_SEND_JOB, {
          subscriptionId: 'sub-1',
          renewalDate: '2026-10-08',
        }),
      );

      expect(
        notificationsServiceMock.ensureRenewalNotification,
      ).not.toHaveBeenCalled();
      expect(pushProviderMock.send).not.toHaveBeenCalled();
    });

    it.each([SubscriptionStatus.CANCELLED, SubscriptionStatus.PAUSED])(
      'does nothing when subscription status is %s',
      async (status) => {
        prismaMock.userSubscription.findUnique.mockResolvedValue(
          activeSubscription({ status }),
        );

        await processor.process(
          job(RENEWAL_SEND_JOB, {
            subscriptionId: 'sub-1',
            renewalDate: '2026-10-08',
          }),
        );

        expect(
          notificationsServiceMock.ensureRenewalNotification,
        ).not.toHaveBeenCalled();
        expect(pushProviderMock.send).not.toHaveBeenCalled();
      },
    );

    it('skips a stale job when the renewal date has since changed', async () => {
      prismaMock.userSubscription.findUnique.mockResolvedValue(
        activeSubscription({
          next_renewal_date: new Date('2026-10-09T00:00:00.000Z'),
        }),
      );

      await processor.process(
        job(RENEWAL_SEND_JOB, {
          subscriptionId: 'sub-1',
          renewalDate: '2026-10-08',
        }),
      );

      expect(
        notificationsServiceMock.ensureRenewalNotification,
      ).not.toHaveBeenCalled();
      expect(pushProviderMock.send).not.toHaveBeenCalled();
    });

    it('skips when the current renewal date is now outside the eligibility window', async () => {
      // now = 2026-10-05T12:00Z, window end = 2026-10-09T00:00Z (exclusive)
      prismaMock.userSubscription.findUnique.mockResolvedValue(
        activeSubscription({
          next_renewal_date: new Date('2026-10-09T00:00:00.000Z'),
        }),
      );

      await processor.process(
        job(RENEWAL_SEND_JOB, {
          subscriptionId: 'sub-1',
          renewalDate: '2026-10-09',
        }),
      );

      expect(
        notificationsServiceMock.ensureRenewalNotification,
      ).not.toHaveBeenCalled();
    });
  });

  describe('durable Notification + push (critical regression guard)', () => {
    it('always attempts push even when the durable Notification already existed', async () => {
      prismaMock.userSubscription.findUnique.mockResolvedValue(
        activeSubscription(),
      );
      prismaMock.deviceRegistration.findMany.mockResolvedValue([
        activeDevice('dev-1'),
      ]);
      pushProviderMock.send.mockResolvedValue({ outcome: 'delivered' });

      await processor.process(
        job(RENEWAL_SEND_JOB, {
          subscriptionId: 'sub-1',
          renewalDate: '2026-10-08',
        }),
      );
      await processor.process(
        job(RENEWAL_SEND_JOB, {
          subscriptionId: 'sub-1',
          renewalDate: '2026-10-08',
        }),
      );

      expect(
        notificationsServiceMock.ensureRenewalNotification,
      ).toHaveBeenCalledTimes(2);
      expect(pushProviderMock.send).toHaveBeenCalledTimes(2);
    });
  });

  describe('no ACTIVE devices', () => {
    it('completes successfully with zero push calls, keeping the durable Notification', async () => {
      prismaMock.userSubscription.findUnique.mockResolvedValue(
        activeSubscription(),
      );
      prismaMock.deviceRegistration.findMany.mockResolvedValue([]);

      await expect(
        processor.process(
          job(RENEWAL_SEND_JOB, {
            subscriptionId: 'sub-1',
            renewalDate: '2026-10-08',
          }),
        ),
      ).resolves.toBeUndefined();

      expect(
        notificationsServiceMock.ensureRenewalNotification,
      ).toHaveBeenCalledTimes(1);
      expect(pushProviderMock.send).not.toHaveBeenCalled();
    });
  });

  describe('multi-device delivery', () => {
    it('sends to every ACTIVE device and succeeds when all are delivered', async () => {
      prismaMock.userSubscription.findUnique.mockResolvedValue(
        activeSubscription(),
      );
      prismaMock.deviceRegistration.findMany.mockResolvedValue([
        activeDevice('dev-a'),
        activeDevice('dev-b'),
        activeDevice('dev-c'),
      ]);
      pushProviderMock.send.mockResolvedValue({ outcome: 'delivered' });

      await expect(
        processor.process(
          job(RENEWAL_SEND_JOB, {
            subscriptionId: 'sub-1',
            renewalDate: '2026-10-08',
          }),
        ),
      ).resolves.toBeUndefined();

      expect(pushProviderMock.send).toHaveBeenCalledTimes(3);
    });

    it('never leaks the raw push token into the send() call args in a way distinguishable from a deviceRegistrationId reference', async () => {
      prismaMock.userSubscription.findUnique.mockResolvedValue(
        activeSubscription(),
      );
      prismaMock.deviceRegistration.findMany.mockResolvedValue([
        activeDevice('dev-a', 'raw-secret-token'),
      ]);
      pushProviderMock.send.mockResolvedValue({ outcome: 'delivered' });

      await processor.process(
        job(RENEWAL_SEND_JOB, {
          subscriptionId: 'sub-1',
          renewalDate: '2026-10-08',
        }),
      );

      const [destination] = pushProviderMock.send.mock.calls[0];
      expect(destination).toEqual({
        deviceRegistrationId: 'dev-a',
        token: 'raw-secret-token',
      });
    });
  });

  describe('permanent token failure', () => {
    it('marks the device INVALID with deactivated_at and does not throw', async () => {
      prismaMock.userSubscription.findUnique.mockResolvedValue(
        activeSubscription(),
      );
      prismaMock.deviceRegistration.findMany.mockResolvedValue([
        activeDevice('dev-a'),
      ]);
      pushProviderMock.send.mockResolvedValue({
        outcome: 'permanent_failure',
        reason: 'messaging/registration-token-not-registered',
      });

      await expect(
        processor.process(
          job(RENEWAL_SEND_JOB, {
            subscriptionId: 'sub-1',
            renewalDate: '2026-10-08',
          }),
        ),
      ).resolves.toBeUndefined();

      expect(prismaMock.deviceRegistration.updateMany).toHaveBeenCalledWith({
        where: { id: 'dev-a', status: DeviceRegistrationStatus.ACTIVE },
        data: {
          status: DeviceRegistrationStatus.INVALID,
          deactivated_at: expect.any(Date),
        },
      });
    });

    it('continues processing other devices after one permanent failure', async () => {
      prismaMock.userSubscription.findUnique.mockResolvedValue(
        activeSubscription(),
      );
      prismaMock.deviceRegistration.findMany.mockResolvedValue([
        activeDevice('dev-a'),
        activeDevice('dev-b'),
      ]);
      pushProviderMock.send
        .mockResolvedValueOnce({ outcome: 'permanent_failure', reason: 'x' })
        .mockResolvedValueOnce({ outcome: 'delivered' });

      await expect(
        processor.process(
          job(RENEWAL_SEND_JOB, {
            subscriptionId: 'sub-1',
            renewalDate: '2026-10-08',
          }),
        ),
      ).resolves.toBeUndefined();

      expect(pushProviderMock.send).toHaveBeenCalledTimes(2);
    });
  });

  describe('transient failure', () => {
    it('throws a sanitized error (no raw token) so BullMQ retries, without invalidating the device', async () => {
      prismaMock.userSubscription.findUnique.mockResolvedValue(
        activeSubscription(),
      );
      prismaMock.deviceRegistration.findMany.mockResolvedValue([
        activeDevice('dev-a', 'super-secret-token'),
      ]);
      pushProviderMock.send.mockResolvedValue({
        outcome: 'transient_failure',
        reason: 'messaging/server-unavailable',
      });

      const rejection = processor.process(
        job(RENEWAL_SEND_JOB, {
          subscriptionId: 'sub-1',
          renewalDate: '2026-10-08',
        }),
      );

      await expect(rejection).rejects.toThrow();
      await rejection.catch((error: Error) => {
        expect(error.message).not.toContain('super-secret-token');
      });
      expect(prismaMock.deviceRegistration.updateMany).not.toHaveBeenCalled();
    });

    it('throws once even with a mix of delivered, permanent, and transient outcomes', async () => {
      prismaMock.userSubscription.findUnique.mockResolvedValue(
        activeSubscription(),
      );
      prismaMock.deviceRegistration.findMany.mockResolvedValue([
        activeDevice('dev-a'),
        activeDevice('dev-b'),
        activeDevice('dev-c'),
      ]);
      pushProviderMock.send
        .mockResolvedValueOnce({ outcome: 'delivered' })
        .mockResolvedValueOnce({ outcome: 'permanent_failure', reason: 'x' })
        .mockResolvedValueOnce({ outcome: 'transient_failure', reason: 'y' });

      await expect(
        processor.process(
          job(RENEWAL_SEND_JOB, {
            subscriptionId: 'sub-1',
            renewalDate: '2026-10-08',
          }),
        ),
      ).rejects.toThrow();

      expect(pushProviderMock.send).toHaveBeenCalledTimes(3);
      expect(prismaMock.deviceRegistration.updateMany).toHaveBeenCalledTimes(1);
    });
  });
});
