import { describe, expect, it, vi, beforeEach } from 'vitest';
import { SavingsService } from './savings.service';
import { BillingCycle, SubscriptionStatus, UsageStatus } from '@prisma/client';
import * as bcrypt from 'bcryptjs';
import { ForbiddenException } from '@nestjs/common';

describe('SavingsService', () => {
  let service: SavingsService;
  let prismaMock: any;

  beforeEach(() => {
    prismaMock = {
      user: {
        findUnique: vi.fn(),
      },
      userSubscription: {
        findMany: vi.fn(),
        update: vi.fn(),
      },
      savingsCancellationLog: {
        create: vi.fn(),
        findMany: vi.fn(),
      },
      notification: {
        create: vi.fn(),
      },
      $transaction: vi.fn(async (cb) => cb(prismaMock)),
    };

    service = new SavingsService(prismaMock);
  });

  describe('getPotentialSavings', () => {
    it('should detect unused subscriptions and project yearly savings correctly', async () => {
      const userId = 'user-1';
      prismaMock.userSubscription.findMany.mockResolvedValue([
        {
          id: 'sub-1',
          name: 'Gym Pass',
          category: 'Health',
          price: 1000,
          billing_cycle: BillingCycle.MONTHLY,
          usage_status: UsageStatus.UNUSED,
          status: SubscriptionStatus.ACTIVE,
          payment_card: {
            card_nickname: 'Card 1',
            last_4_digits: '1234',
            bank_name: 'BBL',
          },
        },
        {
          id: 'sub-2',
          name: 'Domain Renewal',
          category: 'Tech',
          price: 1200,
          billing_cycle: BillingCycle.YEARLY,
          usage_status: UsageStatus.UNUSED,
          status: SubscriptionStatus.ACTIVE,
          payment_card: {
            card_nickname: 'Card 1',
            last_4_digits: '1234',
            bank_name: 'BBL',
          },
        },
      ]);

      const result = await service.getPotentialSavings(userId);

      // Sub 1: 1000/mo -> 12000/yr
      // Sub 2: 1200/yr -> 100/mo -> 1200/yr
      // Total monthly: 1100, Total yearly: 13200
      expect(result.unused_subscriptions_count).toBe(2);
      expect(result.total_monthly_savings).toBe(1100);
      expect(result.total_yearly_savings_projection).toBe(13200);
      expect(result.recommended_cancellations).toHaveLength(2);
    });
  });

  describe('batchCancel', () => {
    it('should reject batch cancellation if PIN is invalid', async () => {
      const userId = 'user-1';
      const realPinHash = await bcrypt.hash('111111', 10);
      prismaMock.user.findUnique.mockResolvedValue({
        security_pin_hash: realPinHash,
      });

      await expect(
        service.batchCancel(userId, {
          subscription_ids: ['sub-1'],
          security_pin: '999999', // wrong pin
        }),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should cancel subscriptions and log audit records when PIN is valid', async () => {
      const userId = 'user-1';
      const realPinHash = await bcrypt.hash('111111', 10);
      prismaMock.user.findUnique.mockResolvedValue({
        security_pin_hash: realPinHash,
      });
      prismaMock.userSubscription.findMany.mockResolvedValue([
        {
          id: 'sub-1',
          name: 'Old Magazine',
          category: 'Entertainment',
          price: 200,
          billing_cycle: BillingCycle.MONTHLY,
        },
      ]);
      prismaMock.savingsCancellationLog.create.mockResolvedValue({
        id: 'log-1',
      });

      const result = await service.batchCancel(userId, {
        subscription_ids: ['sub-1'],
        security_pin: '111111',
      });

      expect(result.cancelled_count).toBe(1);
      expect(result.total_yearly_savings_unlocked).toBe(2400);
      expect(prismaMock.userSubscription.update).toHaveBeenCalledWith({
        where: { id: 'sub-1' },
        data: { status: SubscriptionStatus.CANCELLED },
      });
      expect(prismaMock.savingsCancellationLog.create).toHaveBeenCalled();
    });
  });
});
