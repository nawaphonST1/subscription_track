import { HttpException, HttpStatus, Injectable } from '@nestjs/common';

export interface PinRateLimitRecord {
  failedAttempts: number;
  lockedUntil?: number;
  lastAttemptTime: number;
}

@Injectable()
export class PinRateLimiter {
  // NOTE (XC-5 / Fix 12): In-memory failed-attempt counter with backoff for single-instance demo deployment.
  // This state does not survive a process restart and does not work across multiple instances.
  // If deployment topology scales horizontally, replace with Redis-backed rate limiting / @nestjs/throttler.
  private readonly attempts = new Map<string, PinRateLimitRecord>();

  private readonly maxAttempts = 5;
  private readonly baseLockoutMs = 60_000; // 1 minute base lockout

  /**
   * Checks whether the user is currently locked out before attempting PIN verification.
   * Throws 429 Too Many Requests if currently locked out.
   */
  checkLockout(userId: string): void {
    const record = this.attempts.get(userId);
    if (!record) return;

    const now = Date.now();
    if (record.lockedUntil && now < record.lockedUntil) {
      const waitSeconds = Math.max(
        1,
        Math.ceil((record.lockedUntil - now) / 1000),
      );
      throw new HttpException(
        {
          success: false,
          statusCode: HttpStatus.TOO_MANY_REQUESTS,
          message: `Too many failed PIN attempts. Please wait ${waitSeconds} seconds before retrying.`,
          error: 'Too Many Requests',
        },
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
  }

  /**
   * Record a failed PIN attempt. Increments count and calculates backoff if limit reached.
   */
  recordFailure(userId: string): void {
    const now = Date.now();
    const record = this.attempts.get(userId) ?? {
      failedAttempts: 0,
      lastAttemptTime: now,
    };

    // If previous lockout expired, reset counter before recording new failure
    if (record.lockedUntil && now >= record.lockedUntil) {
      record.failedAttempts = 0;
      record.lockedUntil = undefined;
    }

    record.failedAttempts += 1;
    record.lastAttemptTime = now;

    if (record.failedAttempts >= this.maxAttempts) {
      // Exponential backoff: baseLockoutMs * 2^(excess attempts)
      const multiplier = Math.pow(2, record.failedAttempts - this.maxAttempts);
      record.lockedUntil = now + this.baseLockoutMs * multiplier;
    }

    this.attempts.set(userId, record);
  }

  /**
   * Record a successful PIN verification. Resets failed attempt counter.
   */
  recordSuccess(userId: string): void {
    this.attempts.delete(userId);
  }

  /**
   * Get current failed attempt count for a user (useful for testing).
   */
  getFailedAttempts(userId: string): number {
    return this.attempts.get(userId)?.failedAttempts ?? 0;
  }

  /**
   * Reset all attempts (useful for testing).
   */
  reset(): void {
    this.attempts.clear();
  }
}
