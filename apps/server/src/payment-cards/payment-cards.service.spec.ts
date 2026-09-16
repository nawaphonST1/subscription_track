import { describe, expect, it, vi, beforeEach } from 'vitest';
import { PaymentCardsService } from './payment-cards.service';
import { BillingCycle, CardType } from '@prisma/client';
import { NotFoundException } from '@nestjs/common';

describe('PaymentCardsService', () => {
  let service: PaymentCardsService;
  let prismaMock: any;

  beforeEach(() => {
    prismaMock = {
      paymentCard: {
        findMany: vi.fn(),
        findFirst: vi.fn(),
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
    it('should throw NotFoundException when no matching mock card exists', async () => {
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
