import { describe, expect, it, vi, beforeEach } from 'vitest';
import { PaymentCardsService } from './payment-cards.service';
import { BillingCycle, CardType } from '@prisma/client';
import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { CacheService } from '../cache/cache.service';

describe('PaymentCardsService', () => {
  let service: PaymentCardsService;
  let prismaMock: any;

  beforeEach(() => {
    prismaMock = {
      paymentCard: {
        findMany: vi.fn(),
        findFirst: vi.fn(),
        findUnique: vi.fn(),
        create: vi.fn(),
        update: vi.fn(),
        updateMany: vi.fn(),
        count: vi.fn(),
      },
      mockBankCard: {
        findMany: vi.fn(),
        findFirst: vi.fn(),
        findUnique: vi.fn(),
      },
      subscriptionPreset: {
        findFirst: vi.fn(),
      },
      userSubscription: {
        create: vi.fn(),
      },
      notification: {
        create: vi.fn(),
      },
      $transaction: vi.fn(async (cb) => {
        if (typeof cb === 'function') {
          return cb(prismaMock);
        }
        return Promise.all(cb);
      }),
    };

    service = new PaymentCardsService(prismaMock);
  });

  describe('findAll', () => {
    it('should return active cards with their active subscriptions and count', async () => {
      const mockCard = {
        id: 'card-1',
        card_nickname: 'Ne SCB Platinum',
        card_brand: 'Visa',
        card_type: CardType.CREDIT,
        last_4_digits: '4321',
        bank_name: 'Siam Commercial Bank',
        balance: 25000,
        currency: 'THB',
        is_default: true,
        subscriptions: [
          {
            id: 'sub-1',
            name: 'Netflix Test',
            category: 'Entertainment',
            price: 399,
            billing_cycle: BillingCycle.MONTHLY,
            next_renewal_date: new Date('2026-11-01T00:00:00.000Z'),
            usage_status: 'FREQUENT',
          },
        ],
        _count: {
          subscriptions: 1,
        },
        created_at: new Date('2026-09-01T00:00:00.000Z'),
        updated_at: new Date('2026-09-01T00:00:00.000Z'),
      };

      prismaMock.paymentCard.findMany.mockResolvedValue([mockCard]);

      const result = await service.findAll('user-1');

      expect(prismaMock.paymentCard.findMany).toHaveBeenCalledWith({
        where: { user_id: 'user-1', is_active: true },
        orderBy: [{ is_default: 'desc' }, { created_at: 'desc' }],
        include: {
          subscriptions: {
            where: { status: 'ACTIVE' },
            orderBy: { next_renewal_date: 'asc' },
            select: {
              id: true,
              name: true,
              category: true,
              price: true,
              billing_cycle: true,
              next_renewal_date: true,
              usage_status: true,
            },
          },
          _count: {
            select: { subscriptions: { where: { status: 'ACTIVE' } } },
          },
        },
      });

      expect(result).toHaveLength(1);
      expect(result[0].id).toBe('card-1');
      expect(result[0].active_subscriptions_count).toBe(1);
      expect(result[0].subscriptions).toHaveLength(1);
      expect(result[0].subscriptions[0].name).toBe('Netflix Test');
      expect(result[0].subscriptions[0].price).toBe(399);
    });

    it('returns cached cards on subsequent requests without querying database', async () => {
      const mockCache = new CacheService();
      const serviceWithCache = new PaymentCardsService(prismaMock, mockCache);

      prismaMock.paymentCard.findMany.mockResolvedValue([]);

      // Call 1: Miss
      const r1 = await serviceWithCache.findAll('user-cached-card');
      expect(r1).toEqual([]);
      expect(prismaMock.paymentCard.findMany).toHaveBeenCalledTimes(1);

      // Call 2: Hit
      const r2 = await serviceWithCache.findAll('user-cached-card');
      expect(r2).toEqual([]);
      expect(prismaMock.paymentCard.findMany).toHaveBeenCalledTimes(1);
    });
  });

  describe('getTotalBalance', () => {
    it('should sum balance across active cards', async () => {
      const userId = 'user-1';
      prismaMock.paymentCard.findMany.mockResolvedValue([
        { balance: 15000.5, currency: 'THB' },
        { balance: 25000.25, currency: 'THB' },
      ]);

      const result = await service.getTotalBalance(userId);

      expect(result.total_balance).toBe(40000.75);
      expect(result.currency).toBe('THB');
      expect(result.active_cards_count).toBe(2);
    });

    it('should return 0 balance when user has no active cards', async () => {
      const userId = 'user-empty';
      prismaMock.paymentCard.findMany.mockResolvedValue([]);

      const result = await service.getTotalBalance(userId);

      expect(result.total_balance).toBe(0);
      expect(result.currency).toBe('THB');
      expect(result.active_cards_count).toBe(0);
    });
  });

  describe('linkMockCard', () => {
    it('should throw ForbiddenException when card belongs to another user', async () => {
      prismaMock.paymentCard.findUnique.mockResolvedValue({
        id: 'card-user-2',
        user_id: 'user-2',
        card_nickname: 'Other User Card',
        bank_name: 'Kasikornbank',
      });

      await expect(
        service.linkMockCard('user-1', { card_id: 'card-user-2' }),
      ).rejects.toThrow(ForbiddenException);

      await expect(
        service.linkMockCard('user-1', { card_id: 'card-user-2' }),
      ).rejects.toThrow('This card does not belong to your account.');
    });

    it('should link/activate card when card belongs to current user', async () => {
      const ownCard = {
        id: 'card-user-1',
        user_id: 'user-1',
        card_nickname: 'My Saved Card',
        card_brand: 'Visa',
        card_type: CardType.CREDIT,
        last_4_digits: '4321',
        bank_name: 'SCB',
        balance: 25000,
        currency: 'THB',
        is_default: true,
        is_active: false,
      };

      prismaMock.paymentCard.findUnique.mockResolvedValue(ownCard);
      prismaMock.paymentCard.update.mockResolvedValue({
        ...ownCard,
        is_active: true,
      });

      const result = await service.linkMockCard('user-1', {
        card_id: 'card-user-1',
      });

      expect(prismaMock.paymentCard.update).toHaveBeenCalledWith({
        where: { id: 'card-user-1' },
        data: { is_active: true },
      });
      expect(result.card.id).toBe('card-user-1');
      expect(result.card.balance).toBe(25000);
      expect(result.imported_subscriptions_count).toBe(0);
    });

    it('should throw NotFoundException when no matching mock card exists', async () => {
      prismaMock.paymentCard.findUnique.mockResolvedValue(null);
      prismaMock.mockBankCard.findUnique.mockResolvedValue(null);

      await expect(
        service.linkMockCard('user-1', { mock_card_id: 'non-existent' }),
      ).rejects.toThrow(NotFoundException);
    });

    it('should create payment card and clone mock subscriptions into user subscriptions', async () => {
      const userId = 'user-1';
      const mockCard = {
        id: 'mock-1',
        card_nickname: 'KBank Platinum Debit',
        card_brand: 'Visa',
        card_type: CardType.DEBIT,
        last_4_digits: '9999',
        bank_name: 'Kasikornbank',
        balance: 15000,
        currency: 'THB',
        subscriptions: [
          {
            name: 'Netflix Premium',
            category: 'Streaming',
            price: 419,
            billing_cycle: BillingCycle.MONTHLY,
            brand_color: '#E50914',
          },
        ],
      };

      prismaMock.mockBankCard.findUnique.mockResolvedValue(mockCard);
      prismaMock.paymentCard.count.mockResolvedValue(0);
      prismaMock.paymentCard.create.mockResolvedValue({
        ...mockCard,
        id: 'user-card-1',
        user_id: userId,
        is_default: true,
      });
      prismaMock.subscriptionPreset.findFirst.mockResolvedValue({
        id: 'preset-netflix',
        brand_color: '#E50914',
      });
      prismaMock.userSubscription.create.mockResolvedValue({
        id: 'sub-created-1',
        name: 'Netflix Premium',
        category: 'Streaming',
        price: 419,
        billing_cycle: BillingCycle.MONTHLY,
        next_renewal_date: new Date(),
      });

      const result = await service.linkMockCard(userId, {
        mock_card_id: 'mock-1',
      });

      expect(result.card.id).toBe('user-card-1');
      expect(result.imported_subscriptions_count).toBe(1);
      expect(prismaMock.userSubscription.create).toHaveBeenCalled();
      expect(prismaMock.notification.create).toHaveBeenCalled();
    });
  });
});
