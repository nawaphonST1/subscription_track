import { beforeEach, describe, expect, it, vi } from 'vitest';
import { NotificationType, Prisma } from '@prisma/client';
import { NotificationsService } from './notifications.service';

describe('NotificationsService', () => {
  let service: NotificationsService;
  let prismaMock: any;

  beforeEach(() => {
    prismaMock = {
      notification: {
        findMany: vi.fn(),
        count: vi.fn(),
        findFirst: vi.fn(),
        update: vi.fn(),
        updateMany: vi.fn(),
        upsert: vi.fn(),
        findUniqueOrThrow: vi.fn(),
      },
    };
    service = new NotificationsService(prismaMock);
  });

  describe('findAll', () => {
    it('never selects dedupe_key or subscription_id from Prisma', async () => {
      prismaMock.notification.findMany.mockResolvedValue([]);
      prismaMock.notification.count.mockResolvedValue(0);

      await service.findAll('user-1');

      const selectArg =
        prismaMock.notification.findMany.mock.calls[0][0].select;
      expect(selectArg.dedupe_key).toBeUndefined();
      expect(selectArg.subscription_id).toBeUndefined();
      expect(selectArg).toEqual({
        id: true,
        user_id: true,
        title: true,
        message: true,
        type: true,
        is_read: true,
        created_at: true,
        updated_at: true,
      });
    });
  });

  describe('markAsRead', () => {
    it('never selects dedupe_key or subscription_id on the update response', async () => {
      prismaMock.notification.findFirst.mockResolvedValue({ id: 'n1' });
      prismaMock.notification.update.mockResolvedValue({ id: 'n1' });

      await service.markAsRead('user-1', 'n1');

      const selectArg = prismaMock.notification.update.mock.calls[0][0].select;
      expect(selectArg.dedupe_key).toBeUndefined();
      expect(selectArg.subscription_id).toBeUndefined();
    });
  });

  describe('ensureRenewalNotification', () => {
    const params = {
      userId: 'user-1',
      subscriptionId: 'sub-1',
      renewalDate: new Date('2026-10-08T00:00:00.000Z'),
      title: 'Upcoming renewal',
      message: 'Your subscription renews in 3 days',
    };

    it('upserts with a deterministic dedupe key derived from subscription + renewal date', async () => {
      prismaMock.notification.upsert.mockResolvedValue({ id: 'notif-1' });

      const result = await service.ensureRenewalNotification(params);

      expect(result).toEqual({ id: 'notif-1' });
      expect(prismaMock.notification.upsert).toHaveBeenCalledWith({
        where: { dedupe_key: 'renewal-sub-1-2026-10-08' },
        update: {},
        create: {
          user_id: 'user-1',
          subscription_id: 'sub-1',
          dedupe_key: 'renewal-sub-1-2026-10-08',
          type: NotificationType.RENEWAL_ALERT,
          title: params.title,
          message: params.message,
        },
        select: { id: true },
      });
    });

    it('a retried call with the same inputs resolves to the same dedupe key (idempotent)', async () => {
      prismaMock.notification.upsert.mockResolvedValue({ id: 'notif-1' });

      await service.ensureRenewalNotification(params);
      await service.ensureRenewalNotification(params);

      const dedupeKeys = prismaMock.notification.upsert.mock.calls.map(
        (call: any[]) => call[0].where.dedupe_key,
      );
      expect(dedupeKeys[0]).toBe(dedupeKeys[1]);
    });

    it('falls back to fetching the existing row on a concurrent unique-constraint race', async () => {
      const conflict = new Prisma.PrismaClientKnownRequestError(
        'Unique constraint failed',
        {
          code: 'P2002',
          clientVersion: 'test',
          meta: { modelName: 'Notification', target: ['dedupe_key'] },
        },
      );
      prismaMock.notification.upsert.mockRejectedValue(conflict);
      prismaMock.notification.findUniqueOrThrow.mockResolvedValue({
        id: 'existing-notif',
      });

      const result = await service.ensureRenewalNotification(params);

      expect(result).toEqual({ id: 'existing-notif' });
      expect(prismaMock.notification.findUniqueOrThrow).toHaveBeenCalledWith({
        where: { dedupe_key: 'renewal-sub-1-2026-10-08' },
        select: { id: true },
      });
    });

    it('rethrows unrelated Prisma errors instead of masking them', async () => {
      const unrelated = new Prisma.PrismaClientKnownRequestError('boom', {
        code: 'P2025',
        clientVersion: 'test',
      });
      prismaMock.notification.upsert.mockRejectedValue(unrelated);

      await expect(service.ensureRenewalNotification(params)).rejects.toBe(
        unrelated,
      );
    });
  });
});
