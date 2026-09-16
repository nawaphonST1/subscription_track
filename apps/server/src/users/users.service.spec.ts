import { describe, expect, it, vi, beforeEach } from 'vitest';
import { UsersService } from './users.service';
import * as bcrypt from 'bcryptjs';
import { UnauthorizedException } from '@nestjs/common';

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
