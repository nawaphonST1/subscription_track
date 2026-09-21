import { describe, expect, it, vi, beforeEach } from 'vitest';
import { SubscriptionsService } from './subscriptions.service';
import { BillingCycle, SubscriptionStatus } from '@prisma/client';
import { BadRequestException, NotFoundException } from '@nestjs/common';

describe('SubscriptionsService', () => {
  let service: SubscriptionsService;
  let prismaMock: any;

  beforeEach(() => {
    prismaMock = {
      userSubscription: {
        findMany: vi.fn(),
        findFirst: vi.fn(),
        create: vi.fn(),
        update: vi.fn(),
        delete: vi.fn(),
      },
      paymentCard: {
        findFirst: vi.fn(),
      },
      subscriptionPreset: {
        findMany: vi.fn(),
      },
    };

    service = new SubscriptionsService(prismaMock);
  });

  describe('create', () => {
    it('should throw BadRequestException if card does not belong to user', async () => {
      prismaMock.paymentCard.findFirst.mockResolvedValue(null);

      await expect(
        service.create('user-1', {
          payment_card_id: 'invalid-card',
          name: 'Disney+',
          category: 'Streaming',
          price: 289,
          billing_cycle: BillingCycle.MONTHLY,
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it('should create subscription and calculate renewal date if not provided', async () => {
      prismaMock.paymentCard.findFirst.mockResolvedValue({ id: 'card-1' });
      prismaMock.userSubscription.create.mockImplementation(
        ({ data }: { data: Record<string, unknown> }) => ({
          id: 'sub-new',
          ...data,
        }),
      );

      const result = await service.create('user-1', {
        payment_card_id: 'card-1',
        name: 'Disney+',
        category: 'Streaming',
        price: 289,
        billing_cycle: BillingCycle.MONTHLY,
      });

      expect(result.id).toBe('sub-new');
      expect(result.name).toBe('Disney+');
      expect(result.price).toBe(289);
      expect(result.status).toBe(SubscriptionStatus.ACTIVE);
      expect(result.next_renewal_date).toBeDefined();
    });
  });

  describe('findOne', () => {
    it('should throw NotFoundException if subscription not found', async () => {
      prismaMock.userSubscription.findFirst.mockResolvedValue(null);

      await expect(service.findOne('user-1', 'non-existent')).rejects.toThrow(
        NotFoundException,
      );
    });
  });
});
