import { describe, it, expect, beforeEach, vi } from 'vitest';
import { NotFoundException } from '@nestjs/common';
import { AdminUsersService } from './admin-users.service';
import { PrismaService } from '../../prisma/prisma.service';

describe('AdminUsersService', () => {
  let service: AdminUsersService;
  let prisma: PrismaService;

  const mockPrisma = {
    user: {
      count: vi.fn(),
      findMany: vi.fn(),
      findUnique: vi.fn(),
      delete: vi.fn(),
    },
    userSubscription: {
      count: vi.fn(),
    },
    paymentCard: {
      count: vi.fn(),
    },
    subscriptionPreset: {
      count: vi.fn(),
    },
  };

  beforeEach(() => {
    vi.clearAllMocks();
    prisma = mockPrisma as unknown as PrismaService;
    service = new AdminUsersService(prisma);
  });

  describe('getStats', () => {
    it('returns aggregated counts of users, active subscriptions, cards, and packages', async () => {
      mockPrisma.user.count.mockResolvedValue(10);
      mockPrisma.userSubscription.count.mockResolvedValue(25);
      mockPrisma.paymentCard.count.mockResolvedValue(14);
      mockPrisma.subscriptionPreset.count.mockResolvedValue(8);

      const stats = await service.getStats();

      expect(stats).toEqual({
        totalUsers: 10,
        totalSubscriptions: 25,
        totalCards: 14,
        totalPackages: 8,
      });
      expect(mockPrisma.userSubscription.count).toHaveBeenCalledWith({
        where: { status: 'ACTIVE' },
      });
      expect(mockPrisma.paymentCard.count).toHaveBeenCalledWith({
        where: { is_active: true },
      });
    });
  });

  describe('getUsers', () => {
    it('returns mapped list of users with subscription and card counts', async () => {
      const now = new Date();
      mockPrisma.user.findMany.mockResolvedValue([
        {
          id: 'u-1',
          email: 'user1@example.com',
          name: 'Alice',
          monthly_income: 45000,
          created_at: now,
          _count: {
            subscriptions: 3,
            payment_cards: 2,
          },
        },
      ]);

      const users = await service.getUsers();

      expect(users).toHaveLength(1);
      expect(users[0]).toEqual({
        id: 'u-1',
        email: 'user1@example.com',
        name: 'Alice',
        monthlyIncome: 45000,
        subscriptionsCount: 3,
        cardsCount: 2,
        createdAt: now,
      });
    });
  });

  describe('deleteUser', () => {
    it('throws NotFoundException when user does not exist', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(null);

      await expect(service.deleteUser('non-existent')).rejects.toThrow(
        NotFoundException,
      );
    });

    it('deletes user when found', async () => {
      mockPrisma.user.findUnique.mockResolvedValue({ id: 'u-1' });
      mockPrisma.user.delete.mockResolvedValue({ id: 'u-1' });

      const result = await service.deleteUser('u-1');

      expect(result).toEqual({
        message: 'User successfully removed',
        id: 'u-1',
      });
      expect(mockPrisma.user.delete).toHaveBeenCalledWith({
        where: { id: 'u-1' },
      });
    });
  });

  describe('createSubscription', () => {
    it('creates a new subscription with planTier for a user', async () => {
      mockPrisma.user.findUnique.mockResolvedValue({
        id: 'u-1',
        payment_cards: [{ id: 'card-1', is_active: true }],
      });
      (mockPrisma.userSubscription as any).create = vi.fn().mockResolvedValue({
        id: 'sub-new',
        name: 'YouTube Premium',
        category: 'Streaming',
        price: 179,
        plan_tier: 'Individual',
        preset_id: 'preset-yt',
        billing_cycle: 'MONTHLY',
        start_date: new Date(),
        next_renewal_date: new Date(),
        status: 'ACTIVE',
        usage_status: 'FREQUENT',
        brand_color: '#FF0000',
        notes: null,
        payment_card: null,
      });

      const res = await service.createSubscription('u-1', {
        name: 'YouTube Premium',
        category: 'Streaming',
        price: 179,
        planTier: 'Individual',
        presetId: 'preset-yt',
      });

      expect(res.name).toBe('YouTube Premium');
      expect(res.planTier).toBe('Individual');
      expect(res.presetId).toBe('preset-yt');
      expect((mockPrisma.userSubscription as any).create).toHaveBeenCalled();
    });
  });
});
