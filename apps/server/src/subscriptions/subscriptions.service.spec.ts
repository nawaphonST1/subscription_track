import { describe, expect, it, vi, beforeEach } from 'vitest';
import { SubscriptionsService } from './subscriptions.service';
import { BillingCycle, SubscriptionStatus, UsageStatus } from '@prisma/client';
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

  describe('findAll', () => {
    const mockRawSubscription = {
      id: 'sub-1',
      name: 'Netflix Premium',
      category: 'Streaming',
      price: { toString: () => '419.00' }, // Decimal-like
      billing_cycle: BillingCycle.MONTHLY,
      start_date: new Date('2026-09-01T00:00:00.000Z'),
      next_renewal_date: new Date('2026-10-01T00:00:00.000Z'),
      usage_status: UsageStatus.FREQUENT,
      status: SubscriptionStatus.ACTIVE,
      brand_color: '#E50914',
      notes: 'Family plan',
      payment_card: {
        id: 'card-1',
        card_nickname: 'Main Visa',
        card_brand: 'Visa',
        last_4_digits: '4242',
        bank_name: 'KBANK',
      },
      created_at: new Date('2026-09-01T00:00:00.000Z'),
      updated_at: new Date('2026-09-01T00:00:00.000Z'),
    };

    it('should return subscriptions belonging to authenticated user with converted price', async () => {
      prismaMock.userSubscription.findMany.mockResolvedValue([
        mockRawSubscription,
      ]);

      const result = await service.findAll('user-1', {});

      expect(prismaMock.userSubscription.findMany).toHaveBeenCalledWith({
        where: { user_id: 'user-1' },
        orderBy: [{ next_renewal_date: 'asc' }, { id: 'asc' }],
        include: {
          payment_card: {
            select: {
              id: true,
              card_nickname: true,
              card_brand: true,
              last_4_digits: true,
              bank_name: true,
            },
          },
        },
      });

      expect(result).toHaveLength(1);
      expect(result[0].id).toBe('sub-1');
      expect(result[0].name).toBe('Netflix Premium');
      expect(result[0].price).toBe(419);
      expect(typeof result[0].price).toBe('number');
      expect(result[0].payment_card).toEqual(mockRawSubscription.payment_card);
    });

    it('should return an empty array when user has no subscriptions', async () => {
      prismaMock.userSubscription.findMany.mockResolvedValue([]);

      const result = await service.findAll('user-empty', {});

      expect(result).toEqual([]);
      expect(prismaMock.userSubscription.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { user_id: 'user-empty' },
        }),
      );
    });

    it('should filter by status correctly', async () => {
      prismaMock.userSubscription.findMany.mockResolvedValue([]);

      await service.findAll('user-1', { status: SubscriptionStatus.ACTIVE });

      expect(prismaMock.userSubscription.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: {
            user_id: 'user-1',
            status: SubscriptionStatus.ACTIVE,
          },
        }),
      );
    });

    it('should filter by category case-insensitively', async () => {
      prismaMock.userSubscription.findMany.mockResolvedValue([]);

      await service.findAll('user-1', { category: 'streaming' });

      expect(prismaMock.userSubscription.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: {
            user_id: 'user-1',
            category: { equals: 'streaming', mode: 'insensitive' },
          },
        }),
      );
    });

    it('should filter by search using case-insensitive contains', async () => {
      prismaMock.userSubscription.findMany.mockResolvedValue([]);

      await service.findAll('user-1', { search: 'flix' });

      expect(prismaMock.userSubscription.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: {
            user_id: 'user-1',
            name: { contains: 'flix', mode: 'insensitive' },
          },
        }),
      );
    });

    it('should filter by usage_status correctly', async () => {
      prismaMock.userSubscription.findMany.mockResolvedValue([]);

      await service.findAll('user-1', { usage_status: UsageStatus.UNUSED });

      expect(prismaMock.userSubscription.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: {
            user_id: 'user-1',
            usage_status: UsageStatus.UNUSED,
          },
        }),
      );
    });

    it('should use deterministic ordering [{ next_renewal_date: "asc" }, { id: "asc" }]', async () => {
      prismaMock.userSubscription.findMany.mockResolvedValue([]);

      await service.findAll('user-1', {});

      expect(prismaMock.userSubscription.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          orderBy: [{ next_renewal_date: 'asc' }, { id: 'asc' }],
        }),
      );
    });

    it('should limit payment_card inclusion to selected presentation fields', async () => {
      prismaMock.userSubscription.findMany.mockResolvedValue([]);

      await service.findAll('user-1', {});

      expect(prismaMock.userSubscription.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          include: {
            payment_card: {
              select: {
                id: true,
                card_nickname: true,
                card_brand: true,
                last_4_digits: true,
                bank_name: true,
              },
            },
          },
        }),
      );
    });
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

  describe('findUpcoming', () => {
    it('should return upcoming renewals with calculated days_until_renewal', async () => {
      const futureDate = new Date(Date.now() + 5 * 24 * 60 * 60 * 1000);
      prismaMock.userSubscription.findMany.mockResolvedValue([
        {
          id: 'sub-upcoming',
          name: 'Spotify',
          category: 'Music',
          price: { toString: () => '139.00' },
          billing_cycle: BillingCycle.MONTHLY,
          next_renewal_date: futureDate,
          brand_color: '#1DB954',
          payment_card: {
            card_nickname: 'Main',
            last_4_digits: '1234',
            bank_name: 'SCB',
          },
        },
      ]);

      const result = await service.findUpcoming('user-1', 5);

      expect(prismaMock.userSubscription.findMany).toHaveBeenCalledWith({
        where: {
          user_id: 'user-1',
          status: SubscriptionStatus.ACTIVE,
        },
        orderBy: { next_renewal_date: 'asc' },
        take: 5,
        include: {
          payment_card: {
            select: {
              card_nickname: true,
              last_4_digits: true,
              bank_name: true,
            },
          },
        },
      });

      expect(result).toHaveLength(1);
      expect(result[0].name).toBe('Spotify');
      expect(result[0].price).toBe(139);
      expect(result[0].days_until_renewal).toBeGreaterThanOrEqual(4);
    });
  });

  describe('listPresets', () => {
    it('should return preset catalog ordered by category and name', async () => {
      prismaMock.subscriptionPreset.findMany.mockResolvedValue([
        {
          id: 'preset-1',
          name: 'Netflix',
          category: 'Streaming',
          default_price: { toString: () => '419.00' },
          billing_cycle: BillingCycle.MONTHLY,
          brand_color: '#E50914',
          icon_url: 'https://example.com/netflix.png',
          description: 'Streaming service',
        },
      ]);

      const result = await service.listPresets();

      expect(prismaMock.subscriptionPreset.findMany).toHaveBeenCalledWith({
        orderBy: [{ category: 'asc' }, { name: 'asc' }],
      });
      expect(result).toHaveLength(1);
      expect(result[0].default_price).toBe(419);
      expect(typeof result[0].default_price).toBe('number');
    });
  });

  describe('findOne', () => {
    it('should return subscription details with card and preset when found and owned by user', async () => {
      const mockDetail = {
        id: 'sub-1',
        name: 'Netflix',
        category: 'Entertainment',
        price: { toString: () => '419.00' },
        billing_cycle: BillingCycle.MONTHLY,
        start_date: new Date('2026-09-01'),
        next_renewal_date: new Date('2026-10-01'),
        usage_status: UsageStatus.FREQUENT,
        status: SubscriptionStatus.ACTIVE,
        brand_color: '#E50914',
        notes: 'Family plan',
        payment_card: {
          id: 'card-1',
          card_nickname: 'Main Card',
          card_brand: 'Visa',
          last_4_digits: '4242',
          bank_name: 'KBANK',
          balance: { toString: () => '5000.00' },
        },
        preset: {
          id: 'preset-1',
          name: 'Netflix Preset',
          icon_url: 'https://example.com/icon.png',
        },
        created_at: new Date('2026-09-01'),
        updated_at: new Date('2026-09-01'),
      };

      prismaMock.userSubscription.findFirst.mockResolvedValue(mockDetail);

      const result = await service.findOne('user-1', 'sub-1');

      expect(prismaMock.userSubscription.findFirst).toHaveBeenCalledWith({
        where: { id: 'sub-1', user_id: 'user-1' },
        include: {
          payment_card: true,
          preset: true,
        },
      });
      expect(result.id).toBe('sub-1');
      expect(result.price).toBe(419);
      expect(result.payment_card.balance).toBe(5000);
      expect(result.preset?.name).toBe('Netflix Preset');
    });

    it('should throw NotFoundException if subscription not found or belongs to another user (BE-206)', async () => {
      prismaMock.userSubscription.findFirst.mockResolvedValue(null);

      await expect(service.findOne('user-1', 'sub-foreign')).rejects.toThrow(
        NotFoundException,
      );
      expect(prismaMock.userSubscription.findFirst).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'sub-foreign', user_id: 'user-1' },
        }),
      );
    });
  });

  describe('update', () => {
    const existingSub = {
      id: 'sub-1',
      user_id: 'user-1',
      payment_card_id: 'card-1',
      name: 'Old Name',
      category: 'Work',
      price: 100,
    };

    it('should throw NotFoundException if subscription does not exist or belongs to another user (BE-206)', async () => {
      prismaMock.userSubscription.findFirst.mockResolvedValue(null);

      await expect(
        service.update('user-1', 'sub-foreign', { name: 'New Name' }),
      ).rejects.toThrow(NotFoundException);

      expect(prismaMock.userSubscription.findFirst).toHaveBeenCalledWith({
        where: { id: 'sub-foreign', user_id: 'user-1' },
      });
      expect(prismaMock.userSubscription.update).not.toHaveBeenCalled();
    });

    it('should update subscription fields successfully (BE-204)', async () => {
      prismaMock.userSubscription.findFirst.mockResolvedValue(existingSub);
      prismaMock.userSubscription.update.mockResolvedValue({
        ...existingSub,
        name: 'New Name',
        price: { toString: () => '150.00' },
        notes: 'Updated note',
      });

      const result = await service.update('user-1', 'sub-1', {
        name: 'New Name',
        price: 150,
        notes: 'Updated note',
      });

      expect(result.name).toBe('New Name');
      expect(result.price).toBe(150);
      expect(prismaMock.userSubscription.update).toHaveBeenCalledWith({
        where: { id: 'sub-1' },
        data: expect.objectContaining({
          name: 'New Name',
          price: 150,
          notes: 'Updated note',
        }),
      });
    });

    it('should allow changing payment card if card belongs to user and is active (BE-204)', async () => {
      prismaMock.userSubscription.findFirst.mockResolvedValue(existingSub);
      prismaMock.paymentCard.findFirst.mockResolvedValue({
        id: 'card-2',
        user_id: 'user-1',
        is_active: true,
      });
      prismaMock.userSubscription.update.mockResolvedValue({
        ...existingSub,
        payment_card_id: 'card-2',
        price: 100,
      });

      const result = await service.update('user-1', 'sub-1', {
        payment_card_id: 'card-2',
      });

      expect(prismaMock.paymentCard.findFirst).toHaveBeenCalledWith({
        where: { id: 'card-2', user_id: 'user-1', is_active: true },
      });
      expect(result.payment_card_id).toBe('card-2');
    });

    it('should throw BadRequestException if new payment card does not belong to user (BE-204, BE-206)', async () => {
      prismaMock.userSubscription.findFirst.mockResolvedValue(existingSub);
      prismaMock.paymentCard.findFirst.mockResolvedValue(null);

      await expect(
        service.update('user-1', 'sub-1', {
          payment_card_id: 'card-foreign',
        }),
      ).rejects.toThrow(BadRequestException);

      expect(prismaMock.userSubscription.update).not.toHaveBeenCalled();
    });
  });

  describe('remove', () => {
    it('should throw NotFoundException if subscription does not exist or belongs to another user (BE-206)', async () => {
      prismaMock.userSubscription.findFirst.mockResolvedValue(null);

      await expect(service.remove('user-1', 'sub-foreign')).rejects.toThrow(
        NotFoundException,
      );

      expect(prismaMock.userSubscription.findFirst).toHaveBeenCalledWith({
        where: { id: 'sub-foreign', user_id: 'user-1' },
      });
      expect(prismaMock.userSubscription.delete).not.toHaveBeenCalled();
    });

    it('should delete subscription when owned by user (BE-205)', async () => {
      prismaMock.userSubscription.findFirst.mockResolvedValue({
        id: 'sub-1',
        user_id: 'user-1',
      });
      prismaMock.userSubscription.delete.mockResolvedValue({ id: 'sub-1' });

      const result = await service.remove('user-1', 'sub-1');

      expect(prismaMock.userSubscription.delete).toHaveBeenCalledWith({
        where: { id: 'sub-1' },
      });
      expect(result).toEqual({ message: 'Subscription deleted successfully' });
    });
  });
});
