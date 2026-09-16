import { describe, expect, it, vi, beforeEach } from 'vitest';
import { CreepScoreService } from './creep-score.service';
import { BillingCycle, SubscriptionStatus } from '@prisma/client';

describe('CreepScoreService', () => {
  let service: CreepScoreService;
  let prismaMock: any;

  beforeEach(() => {
    prismaMock = {
      user: {
        findUnique: vi.fn(),
      },
      userSubscription: {
        findMany: vi.fn(),
      },
      paymentCard: {
        findMany: vi.fn(),
      },
    };

    service = new CreepScoreService(prismaMock);
  });

  describe('normalizeMonthlyCost', () => {
    it('should return exact price for MONTHLY cycle', () => {
      expect(service.normalizeMonthlyCost(419, BillingCycle.MONTHLY)).toBe(419);
    });

    it('should divide by 12 for YEARLY cycle', () => {
      expect(service.normalizeMonthlyCost(1200, BillingCycle.YEARLY)).toBe(100);
    });

    it('should compute (price * 52) / 12 for WEEKLY cycle', () => {
      expect(
        service.normalizeMonthlyCost(100, BillingCycle.WEEKLY),
      ).toBeCloseTo(433.33, 1);
    });
  });

  describe('determineRiskLevel', () => {
    it('should classify < 5% as SAFE', () => {
      expect(service.determineRiskLevel(3.5)).toBe('SAFE');
      expect(service.determineRiskLevel(4.99)).toBe('SAFE');
    });

    it('should classify 5% to 15% as CAUTION', () => {
      expect(service.determineRiskLevel(5.0)).toBe('CAUTION');
      expect(service.determineRiskLevel(10.5)).toBe('CAUTION');
      expect(service.determineRiskLevel(15.0)).toBe('CAUTION');
    });

    it('should classify > 15% as HIGH_RISK', () => {
      expect(service.determineRiskLevel(15.01)).toBe('HIGH_RISK');
      expect(service.determineRiskLevel(45.2)).toBe('HIGH_RISK');
    });
  });

  describe('getCreepScore', () => {
    it('should calculate creep score against monthly income', async () => {
      const userId = 'user-1';
      prismaMock.user.findUnique.mockResolvedValue({ monthly_income: 50000 });
      prismaMock.paymentCard.findMany.mockResolvedValue([
        { balance: 20000 },
        { balance: 10000 },
      ]);
      prismaMock.userSubscription.findMany.mockResolvedValue([
        {
          id: 'sub-1',
          name: 'Netflix Premium',
          category: 'Streaming',
          price: 419,
          billing_cycle: BillingCycle.MONTHLY,
          next_renewal_date: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000),
          status: SubscriptionStatus.ACTIVE,
          payment_card: { card_nickname: 'KBank', last_4_digits: '9999' },
        },
        {
          id: 'sub-2',
          name: 'Spotify Premium',
          category: 'Music',
          price: 139,
          billing_cycle: BillingCycle.MONTHLY,
          next_renewal_date: new Date(Date.now() + 10 * 24 * 60 * 60 * 1000),
          status: SubscriptionStatus.ACTIVE,
          payment_card: { card_nickname: 'KBank', last_4_digits: '9999' },
        },
      ]);

      const result = await service.getCreepScore(userId);

      // Monthly expenses = 419 + 139 = 558
      // Income = 50000
      // Creep score = (558 / 50000) * 100 = 1.116% -> 1.12%
      expect(result.monthly_total).toBe(558);
      expect(result.creep_score).toBe(1.12);
      expect(result.risk_level).toBe('SAFE');
      expect(result.denominator_used).toBe('monthly_income');
      expect(result.upcoming_renewals).toHaveLength(2);
    });

    it('should fallback to total card funds when monthly income is 0', async () => {
      const userId = 'user-2';
      prismaMock.user.findUnique.mockResolvedValue({ monthly_income: 0 });
      prismaMock.paymentCard.findMany.mockResolvedValue([{ balance: 5000 }]);
      prismaMock.userSubscription.findMany.mockResolvedValue([
        {
          id: 'sub-1',
          name: 'ChatGPT Plus',
          category: 'Productivity',
          price: 720,
          billing_cycle: BillingCycle.MONTHLY,
          next_renewal_date: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000),
          status: SubscriptionStatus.ACTIVE,
          payment_card: { card_nickname: 'SCB', last_4_digits: '8888' },
        },
      ]);

      const result = await service.getCreepScore(userId);

      // Expenses = 720
      // Total card funds = 5000
      // Creep score = (720 / 5000) * 100 = 14.4%
      expect(result.monthly_total).toBe(720);
      expect(result.creep_score).toBe(14.4);
      expect(result.risk_level).toBe('CAUTION');
      expect(result.denominator_used).toBe('total_card_funds');
    });
  });
});
