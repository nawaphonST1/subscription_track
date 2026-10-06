import { describe, it, expect, beforeEach, vi } from 'vitest';
import { HttpException, HttpStatus } from '@nestjs/common';
import { PinRateLimiter } from './pin-rate-limiter.service';

describe('PinRateLimiter', () => {
  let rateLimiter: PinRateLimiter;

  beforeEach(() => {
    rateLimiter = new PinRateLimiter();
  });

  it('allows attempts within the maximum attempt threshold', () => {
    const userId = 'user-1';
    for (let i = 0; i < 4; i++) {
      expect(() => rateLimiter.checkLockout(userId)).not.toThrow();
      rateLimiter.recordFailure(userId);
    }
    expect(rateLimiter.getFailedAttempts(userId)).toBe(4);
    expect(() => rateLimiter.checkLockout(userId)).not.toThrow();
  });

  it('rejects attempt with 429 Too Many Requests once failure limit is reached', () => {
    const userId = 'user-1';
    for (let i = 0; i < 5; i++) {
      expect(() => rateLimiter.checkLockout(userId)).not.toThrow();
      rateLimiter.recordFailure(userId);
    }

    expect(() => rateLimiter.checkLockout(userId)).toThrow(HttpException);
    try {
      rateLimiter.checkLockout(userId);
    } catch (err: any) {
      expect(err.getStatus()).toBe(HttpStatus.TOO_MANY_REQUESTS);
      expect(err.getResponse()).toMatchObject({
        statusCode: 429,
        error: 'Too Many Requests',
      });
    }
  });

  it('resets failed attempt counter upon successful PIN verification', () => {
    const userId = 'user-1';
    for (let i = 0; i < 4; i++) {
      rateLimiter.recordFailure(userId);
    }
    expect(rateLimiter.getFailedAttempts(userId)).toBe(4);

    rateLimiter.recordSuccess(userId);
    expect(rateLimiter.getFailedAttempts(userId)).toBe(0);
    expect(() => rateLimiter.checkLockout(userId)).not.toThrow();
  });

  it('isolates failed attempts between distinct users', () => {
    const user1 = 'user-1';
    const user2 = 'user-2';

    for (let i = 0; i < 5; i++) {
      rateLimiter.recordFailure(user1);
    }

    expect(() => rateLimiter.checkLockout(user1)).toThrow(HttpException);
    expect(() => rateLimiter.checkLockout(user2)).not.toThrow();
  });

  it('escalates lockout duration cycle over cycle during sustained attack across 5 cycles', () => {
    vi.useFakeTimers();
    try {
      const userId = 'sustained-attacker';
      let currentTime = 1_000_000_000;
      vi.setSystemTime(currentTime);

      // Cycle 1: 5 failures -> triggers initial 1-minute lockout (60,000ms = 60,000 * 2^0)
      for (let i = 0; i < 5; i++) {
        rateLimiter.recordFailure(userId);
      }
      expect(() => rateLimiter.checkLockout(userId)).toThrow(HttpException);
      const lockout1Duration =
        rateLimiter.getLockoutUntil(userId)! - currentTime;
      expect(lockout1Duration).toBe(60_000); // 1 min

      // Wait for lockout 1 to expire and retry
      currentTime += 60_000;
      vi.setSystemTime(currentTime);
      expect(() => rateLimiter.checkLockout(userId)).not.toThrow();

      // Cycle 2: Patient attacker fails again -> escalates to 2-minute lockout (60,000 * 2^1)
      rateLimiter.recordFailure(userId);
      expect(() => rateLimiter.checkLockout(userId)).toThrow(HttpException);
      const lockout2Duration =
        rateLimiter.getLockoutUntil(userId)! - currentTime;
      expect(lockout2Duration).toBe(120_000); // 2 min
      expect(lockout2Duration).toBeGreaterThan(lockout1Duration);

      // Wait for lockout 2 to expire and retry
      currentTime += 120_000;
      vi.setSystemTime(currentTime);
      expect(() => rateLimiter.checkLockout(userId)).not.toThrow();

      // Cycle 3: Attacker fails again -> escalates to 4-minute lockout (60,000 * 2^2)
      rateLimiter.recordFailure(userId);
      expect(() => rateLimiter.checkLockout(userId)).toThrow(HttpException);
      const lockout3Duration =
        rateLimiter.getLockoutUntil(userId)! - currentTime;
      expect(lockout3Duration).toBe(240_000); // 4 min
      expect(lockout3Duration).toBeGreaterThan(lockout2Duration);

      // Wait for lockout 3 to expire and retry
      currentTime += 240_000;
      vi.setSystemTime(currentTime);
      expect(() => rateLimiter.checkLockout(userId)).not.toThrow();

      // Cycle 4: Attacker fails again -> escalates to 8-minute lockout (60,000 * 2^3)
      rateLimiter.recordFailure(userId);
      expect(() => rateLimiter.checkLockout(userId)).toThrow(HttpException);
      const lockout4Duration =
        rateLimiter.getLockoutUntil(userId)! - currentTime;
      expect(lockout4Duration).toBe(480_000); // 8 min
      expect(lockout4Duration).toBeGreaterThan(lockout3Duration);

      // Wait for lockout 4 to expire and retry
      currentTime += 480_000;
      vi.setSystemTime(currentTime);
      expect(() => rateLimiter.checkLockout(userId)).not.toThrow();

      // Cycle 5: Attacker fails again -> escalates to 16-minute lockout (60,000 * 2^4)
      rateLimiter.recordFailure(userId);
      expect(() => rateLimiter.checkLockout(userId)).toThrow(HttpException);
      const lockout5Duration =
        rateLimiter.getLockoutUntil(userId)! - currentTime;
      expect(lockout5Duration).toBe(960_000); // 16 min
      expect(lockout5Duration).toBeGreaterThan(lockout4Duration);

      // Cooldown test: after full 15 minutes of inactivity following lockout expiration, history resets
      currentTime += 960_000 + 15 * 60_000 + 1;
      vi.setSystemTime(currentTime);
      expect(() => rateLimiter.checkLockout(userId)).not.toThrow();

      // Next failure starts fresh at 1 attempt (not locked out)
      rateLimiter.recordFailure(userId);
      expect(rateLimiter.getFailedAttempts(userId)).toBe(1);
      expect(() => rateLimiter.checkLockout(userId)).not.toThrow();
    } finally {
      vi.useRealTimers();
    }
  });
});
