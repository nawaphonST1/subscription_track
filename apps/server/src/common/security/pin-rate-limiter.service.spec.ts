import { describe, it, expect, beforeEach } from 'vitest';
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
});
