import { describe, expect, it, vi, beforeEach } from 'vitest';
import { UsersService } from './users.service';
import * as bcrypt from 'bcryptjs';
import {
  BadRequestException,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';

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

    it('should throw NotFoundException when user does not exist', async () => {
      prismaMock.user.findUnique.mockResolvedValue(null);

      await expect(service.getProfile('non-existent-user')).rejects.toThrow(
        NotFoundException,
      );
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
  });

  describe('changePin', () => {
    it('should throw UnauthorizedException if current PIN is incorrect', async () => {
      const hash = await bcrypt.hash('123456', 10);
      prismaMock.user.findUnique.mockResolvedValue({ security_pin_hash: hash });

      await expect(
        service.changePin('user-1', '999999', '654321'),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('should change PIN and create notification when current PIN is correct', async () => {
      const hash = await bcrypt.hash('123456', 10);
      prismaMock.user.findUnique.mockResolvedValue({ security_pin_hash: hash });
      prismaMock.user.update.mockResolvedValue({ id: 'user-1' });

      const result = await service.changePin('user-1', '123456', '654321');
      expect(result.message).toBe('Security PIN changed successfully');
    });
  });
});
