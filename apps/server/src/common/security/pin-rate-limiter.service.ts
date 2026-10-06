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
  private readonly cooldownMs = 15 * 60_000; // 15 minutes cooldown with no failed attempts to reset failure history

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
   * During a sustained attack across multiple lockout cycles, lockout durations escalate.
   * Failure counts only reset after a full cooldown period without failures.
   */
  recordFailure(userId: string): void {
    const now = Date.now();
    const record = this.attempts.get(userId) ?? {
      failedAttempts: 0,
      lastAttemptTime: now,
    };

    // If full cooldown elapsed with no attempts, reset counter
    const lastActive = record.lockedUntil
      ? Math.max(record.lockedUntil, record.lastAttemptTime)
      : record.lastAttemptTime;
    if (now - lastActive > this.cooldownMs) {
      record.failedAttempts = 0;
      record.lockedUntil = undefined;
    } else if (record.lockedUntil && now >= record.lockedUntil) {
      // Previous lockout expired, but we are still within the cooldown window (sustained attack).
      // Clear expired lockout so new attempt is evaluated, preserving failure history so backoff escalates.
      record.lockedUntil = undefined;
    }

    record.failedAttempts += 1;
    record.lastAttemptTime = now;

    if (record.failedAttempts >= this.maxAttempts) {
      // Exponential backoff: baseLockoutMs * 2^(excess attempts), capped at 2^10 to prevent overflow
      const excess = record.failedAttempts - this.maxAttempts;
      const multiplier = Math.pow(2, Math.min(excess, 10));
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
   * Get lockout expiration timestamp for a user (useful for testing).
   */
  getLockoutUntil(userId: string): number | undefined {
    return this.attempts.get(userId)?.lockedUntil;
  }

  /**
   * Reset all attempts (useful for testing).
   */
  reset(): void {
    this.attempts.clear();
  }
}
