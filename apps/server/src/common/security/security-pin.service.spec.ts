import { describe, it, expect, beforeEach, vi } from 'vitest';
import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { SecurityPinService } from './security-pin.service';
import { PinRateLimiter } from './pin-rate-limiter.service';
import { DEFAULT_PIN, RESET_PIN_PREFIX } from './pin.util';

describe('SecurityPinService', () => {
  let service: SecurityPinService;
  let mockPrisma: any;
  let rateLimiter: PinRateLimiter;

  beforeEach(() => {
    mockPrisma = {
      user: {
        findUnique: vi.fn(),
      },
    };
    rateLimiter = new PinRateLimiter();
    service = new SecurityPinService(mockPrisma, rateLimiter);
  });

  it('rejects invalid PIN format (non-6 digits) with BadRequestException', async () => {
    await expect(service.verifyPin('user-1', '123')).rejects.toThrow(
      BadRequestException,
    );
    await expect(service.verifyPin('user-1', 'abcdef')).rejects.toThrow(
      BadRequestException,
    );
    await expect(service.verifyPin('user-1', '')).rejects.toThrow(
      BadRequestException,
    );
  });

  it('throws NotFoundException if user does not exist', async () => {
    mockPrisma.user.findUnique.mockResolvedValue(null);

    await expect(service.verifyPin('missing-user', '123456')).rejects.toThrow(
      NotFoundException,
    );
  });

  it('rejects verification if user is on default PIN 111111', async () => {
    const defaultHash = await bcrypt.hash(DEFAULT_PIN, 10);
    mockPrisma.user.findUnique.mockResolvedValue({
      security_pin_hash: defaultHash,
    });

    await expect(service.verifyPin('user-default', '111111')).rejects.toThrow(
      ForbiddenException,
    );
    expect(rateLimiter.getFailedAttempts('user-default')).toBe(1);
  });

  it('rejects verification if user PIN is in reset state', async () => {
    mockPrisma.user.findUnique.mockResolvedValue({
      security_pin_hash: `${RESET_PIN_PREFIX}some-reset-hash`,
    });

    await expect(service.verifyPin('user-reset', '123456')).rejects.toThrow(
      ForbiddenException,
    );
    expect(rateLimiter.getFailedAttempts('user-reset')).toBe(1);
  });

  it('rejects incorrect PIN with ForbiddenException and increments failure counter', async () => {
    const customHash = await bcrypt.hash('847291', 10);
    mockPrisma.user.findUnique.mockResolvedValue({
      security_pin_hash: customHash,
    });

    await expect(service.verifyPin('user-custom', '999999')).rejects.toThrow(
      ForbiddenException,
    );
    expect(rateLimiter.getFailedAttempts('user-custom')).toBe(1);
  });

  it('accepts correct PIN, returns true and resets failure counter', async () => {
    const customHash = await bcrypt.hash('847291', 10);
    mockPrisma.user.findUnique.mockResolvedValue({
      security_pin_hash: customHash,
    });

    // Simulate prior failed attempt
    rateLimiter.recordFailure('user-custom');
    expect(rateLimiter.getFailedAttempts('user-custom')).toBe(1);

    const result = await service.verifyPin('user-custom', '847291');
    expect(result).toBe(true);
    expect(rateLimiter.getFailedAttempts('user-custom')).toBe(0);
  });
});
