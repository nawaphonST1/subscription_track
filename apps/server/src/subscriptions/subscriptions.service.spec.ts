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

  describe('findOne', () => {
    it('should throw NotFoundException if subscription not found', async () => {
      prismaMock.userSubscription.findFirst.mockResolvedValue(null);

      await expect(service.findOne('user-1', 'non-existent')).rejects.toThrow(
        NotFoundException,
      );
    });
  });
});
