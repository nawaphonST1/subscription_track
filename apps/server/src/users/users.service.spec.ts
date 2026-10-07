import { describe, expect, it, vi, beforeEach } from 'vitest';
import { UsersService } from './users.service';
import * as bcrypt from 'bcryptjs';
import {
  BadRequestException,
  HttpException,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { CacheService } from '../cache/cache.service';

describe('UsersService', () => {
  let service: UsersService;
  let prismaMock: any;

  beforeEach(() => {
    prismaMock = {
      user: {
        findUnique: vi.fn(),
        update: vi.fn(),
      },
      notification: {
        create: vi.fn(),
      },
      $transaction: vi.fn(async (ops) => Promise.all(ops)),
    };

    service = new UsersService(prismaMock);
  });

  describe('getProfile', () => {
    it('should return user profile with pin_configured true when user has pin', async () => {
      const createdAt = new Date();
      const updatedAt = new Date();
      prismaMock.user.findUnique.mockResolvedValue({
        id: 'user-1',
        email: 'user@example.com',
        name: 'John Doe',
        monthly_income: 50000,
        security_pin_hash: 'hashed-pin',
        created_at: createdAt,
        updated_at: updatedAt,
        _count: {
          payment_cards: 2,
          subscriptions: 5,
        },
      });

      const result = await service.getProfile('user-1');
      expect(result).toEqual({
        id: 'user-1',
        email: 'user@example.com',
        name: 'John Doe',
        monthly_income: 50000,
        pin_configured: true,
        active_cards_count: 2,
        active_subscriptions_count: 5,
        created_at: createdAt,
        updated_at: updatedAt,
      });
      expect(prismaMock.user.findUnique).toHaveBeenCalledWith({
        where: { id: 'user-1' },
        select: expect.objectContaining({
          id: true,
          email: true,
          name: true,
          monthly_income: true,
          security_pin_hash: true,
          created_at: true,
          updated_at: true,
        }),
      });
    });

    it('should return pin_configured false when user has no security_pin_hash', async () => {
      prismaMock.user.findUnique.mockResolvedValue({
        id: 'user-2',
        email: 'nopin@example.com',
        name: null,
        monthly_income: 0,
        security_pin_hash: null,
        created_at: new Date(),
        updated_at: new Date(),
        _count: {
          payment_cards: 0,
          subscriptions: 0,
        },
      });

      const result = await service.getProfile('user-2');
      expect(result.pin_configured).toBe(false);
    });

    it('should return pin_configured false for an unrotated default-PIN account', async () => {
      const defaultHash = await bcrypt.hash('111111', 10);
      prismaMock.user.findUnique.mockResolvedValue({
        id: 'user-default-pin',
        email: 'default@example.com',
        name: 'Default User',
        monthly_income: 10000,
        security_pin_hash: defaultHash,
        created_at: new Date(),
        updated_at: new Date(),
        _count: {
          payment_cards: 0,
          subscriptions: 0,
        },
      });

      const result = await service.getProfile('user-default-pin');
      expect(result.pin_configured).toBe(false);
    });

    it('should return pin_configured true after a real PIN is set', async () => {
      const customHash = await bcrypt.hash('987654', 10);
      prismaMock.user.findUnique.mockResolvedValue({
        id: 'user-custom-pin',
        email: 'custom@example.com',
        name: 'Custom User',
        monthly_income: 20000,
        security_pin_hash: customHash,
        created_at: new Date(),
        updated_at: new Date(),
        _count: {
          payment_cards: 0,
          subscriptions: 0,
        },
      });

      const result = await service.getProfile('user-custom-pin');
      expect(result.pin_configured).toBe(true);
    });

    it('should throw NotFoundException when user does not exist', async () => {
      prismaMock.user.findUnique.mockResolvedValue(null);

      await expect(service.getProfile('non-existent-user')).rejects.toThrow(
        NotFoundException,
      );
    });

    it('returns cached profile on subsequent requests without querying database', async () => {
      const mockCache = new CacheService();
      const serviceWithCache = new UsersService(
        prismaMock,
        undefined,
        mockCache,
      );

      prismaMock.user.findUnique.mockResolvedValue({
        id: 'user-cached',
        email: 'cached@example.com',
        name: 'Cache User',
        monthly_income: 45000,
        security_pin_hash: null,
        created_at: new Date(),
        updated_at: new Date(),
        _count: { payment_cards: 1, subscriptions: 2 },
      });

      // Call 1: Miss
      const r1 = await serviceWithCache.getProfile('user-cached');
      expect(r1.email).toBe('cached@example.com');
      expect(prismaMock.user.findUnique).toHaveBeenCalledTimes(1);

      // Call 2: Hit
      const r2 = await serviceWithCache.getProfile('user-cached');
      expect(r2.email).toBe('cached@example.com');
      expect(prismaMock.user.findUnique).toHaveBeenCalledTimes(1);
    });
  });

  describe('updateProfile', () => {
    it('should update name only', async () => {
      const createdAt = new Date();
      const updatedAt = new Date();
      prismaMock.user.update.mockResolvedValue({
        id: 'user-1',
        email: 'user@example.com',
        name: 'New Name',
        monthly_income: 50000,
        security_pin_hash: 'hashed-pin',
        created_at: createdAt,
        updated_at: updatedAt,
      });

      const result = await service.updateProfile('user-1', {
        name: 'New Name',
      });
      expect(result).toEqual({
        id: 'user-1',
        email: 'user@example.com',
        name: 'New Name',
        monthly_income: 50000,
        pin_configured: true,
        created_at: createdAt,
        updated_at: updatedAt,
      });
      expect(prismaMock.user.update).toHaveBeenCalledWith({
        where: { id: 'user-1' },
        data: { name: 'New Name' },
        select: expect.any(Object),
      });
    });

    it('should update monthly_income only', async () => {
      const createdAt = new Date();
      const updatedAt = new Date();
      prismaMock.user.update.mockResolvedValue({
        id: 'user-1',
        email: 'user@example.com',
        name: 'John Doe',
        monthly_income: 75000,
        security_pin_hash: null,
        created_at: createdAt,
        updated_at: updatedAt,
      });

      const result = await service.updateProfile('user-1', {
        monthly_income: 75000,
      });
      expect(result).toEqual({
        id: 'user-1',
        email: 'user@example.com',
        name: 'John Doe',
        monthly_income: 75000,
        pin_configured: false,
        created_at: createdAt,
        updated_at: updatedAt,
      });
      expect(prismaMock.user.update).toHaveBeenCalledWith({
        where: { id: 'user-1' },
        data: { monthly_income: 75000 },
        select: expect.any(Object),
      });
    });

    it('should update both name and monthly_income', async () => {
      const createdAt = new Date();
      const updatedAt = new Date();
      prismaMock.user.update.mockResolvedValue({
        id: 'user-1',
        email: 'user@example.com',
        name: 'Updated Name',
        monthly_income: 60000,
        security_pin_hash: 'hashed-pin',
        created_at: createdAt,
        updated_at: updatedAt,
      });

      const result = await service.updateProfile('user-1', {
        name: 'Updated Name',
        monthly_income: 60000,
      });
      expect(result.name).toBe('Updated Name');
      expect(result.monthly_income).toBe(60000);
      expect(prismaMock.user.update).toHaveBeenCalledWith({
        where: { id: 'user-1' },
        data: { name: 'Updated Name', monthly_income: 60000 },
        select: expect.any(Object),
      });
    });

    it('should throw BadRequestException if no fields provided', async () => {
      await expect(service.updateProfile('user-1', {})).rejects.toThrow(
        BadRequestException,
      );
    });

    it('should throw NotFoundException if user not found in Prisma (P2025)', async () => {
      prismaMock.user.update.mockRejectedValue({ code: 'P2025' });

      await expect(
        service.updateProfile('non-existent', { name: 'Test' }),
      ).rejects.toThrow(NotFoundException);
    });

    it('should evict auth user cache when name is updated and creep score when monthly_income is updated', async () => {
      const mockCache = { del: vi.fn().mockResolvedValue(true) };
      const serviceWithCache = new UsersService(
        prismaMock,
        undefined,
        mockCache as any,
      );

      prismaMock.user.update.mockResolvedValue({
        id: 'user-1',
        email: 'user@example.com',
        name: 'New Name',
        monthly_income: 80000,
        security_pin_hash: null,
        created_at: new Date(),
        updated_at: new Date(),
      });

      await serviceWithCache.updateProfile('user-1', {
        name: 'New Name',
        monthly_income: 80000,
      });

      expect(mockCache.del).toHaveBeenCalledWith('auth:user:user-1');
      expect(mockCache.del).toHaveBeenCalledWith(
        'cache:user:user-1:creep-score',
      );
    });
  });

  describe('verifyPin', () => {
    it('should return valid true for correct 6-digit PIN', async () => {
      const hash = await bcrypt.hash('123456', 10);
      prismaMock.user.findUnique.mockResolvedValue({ security_pin_hash: hash });

      const result = await service.verifyPin('user-1', '123456');
      expect(result.valid).toBe(true);
    });

    it('should return valid false for incorrect PIN', async () => {
      const hash = await bcrypt.hash('123456', 10);
      prismaMock.user.findUnique.mockResolvedValue({ security_pin_hash: hash });

      const result = await service.verifyPin('user-1', '000000');
      expect(result.valid).toBe(false);
    });

    it('should lockout user with 429 Too Many Requests after 5 consecutive failed attempts', async () => {
      const hash = await bcrypt.hash('123456', 10);
      prismaMock.user.findUnique.mockResolvedValue({ security_pin_hash: hash });

      // First 5 failed attempts
      for (let i = 0; i < 5; i++) {
        const result = await service.verifyPin('user-rate-limited', '000000');
        expect(result.valid).toBe(false);
      }

      // 6th attempt is rejected with 429 Too Many Requests
      await expect(
        service.verifyPin('user-rate-limited', '000000'),
      ).rejects.toThrow(HttpException);

      try {
        await service.verifyPin('user-rate-limited', '000000');
      } catch (err: any) {
        expect(err.getStatus()).toBe(429);
        expect(err.getResponse()).toMatchObject({
          statusCode: 429,
          error: 'Too Many Requests',
        });
      }
    });
  });

  describe('changePin', () => {
    it('should throw UnauthorizedException if current PIN is incorrect', async () => {
      const hash = await bcrypt.hash('123456', 10);
      prismaMock.user.findUnique.mockResolvedValue({ security_pin_hash: hash });

      await expect(
        service.changePin('user-1', '999999', '654321'),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('should lockout user from changePin after repeated failed attempts', async () => {
      const hash = await bcrypt.hash('123456', 10);
      prismaMock.user.findUnique.mockResolvedValue({ security_pin_hash: hash });

      for (let i = 0; i < 5; i++) {
        await expect(
          service.changePin('user-change-lockout', '000000', '654321'),
        ).rejects.toThrow(UnauthorizedException);
      }

      // 6th attempt is blocked by rate limiter with 429
      await expect(
        service.changePin('user-change-lockout', '000000', '654321'),
      ).rejects.toThrow(HttpException);
    });

    it('should change PIN and create notification when current PIN is correct', async () => {
      const hash = await bcrypt.hash('123456', 10);
      prismaMock.user.findUnique.mockResolvedValue({ security_pin_hash: hash });
      prismaMock.user.update.mockResolvedValue({ id: 'user-1' });

      const result = await service.changePin('user-1', '123456', '654321');
      expect(result.message).toBe('Security PIN changed successfully');
    });

    it('should evict auth user cache when PIN is changed', async () => {
      const mockCache = { del: vi.fn().mockResolvedValue(true) };
      const serviceWithCache = new UsersService(
        prismaMock,
        undefined,
        mockCache as any,
      );

      const hash = await bcrypt.hash('123456', 10);
      prismaMock.user.findUnique.mockResolvedValue({ security_pin_hash: hash });
      prismaMock.user.update.mockResolvedValue({ id: 'user-1' });

      await serviceWithCache.changePin('user-1', '123456', '654321');
      expect(mockCache.del).toHaveBeenCalledWith('auth:user:user-1');
    });
  });
});
