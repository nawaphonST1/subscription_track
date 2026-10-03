import { Inject, Injectable, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Counter, Gauge, Registry } from '@prometheus-io/client';

import type { AppConfiguration } from '../config/app.config';
import { METRICS_REGISTRY } from './metrics.registry';

export const DEFAULT_ACTIVE_USERS_WINDOW_SECONDS = 900;

/**
 * Hard ceiling on tracked users. 10 000 entries of (uuid -> timestamp) is
 * well under a megabyte, and the counter below makes the ceiling visible
 * instead of letting the gauge quietly under-report.
 */
export const ACTIVE_USERS_MAX_ENTRIES = 10_000;

/**
 * Counts distinct users seen on an authenticated request inside a rolling
 * window.
 *
 * The user id lives only as a key in this in-process Map: it is never a
 * metric label, never exported, and never logged — the only thing that
 * leaves this class is a count. The value is therefore per process and
 * resets on restart; with more than one API replica the per-replica values
 * overlap and must not be summed naively.
 */
@Injectable()
export class ActiveUsersTracker {
  /** userId -> last seen (ms). Insertion order is kept equal to recency. */
  private readonly lastSeen = new Map<string, number>();
  private readonly dropped: Counter<string>;
  private readonly windowSeconds: number;

  constructor(
    @Inject(METRICS_REGISTRY) registry: Registry,
    @Optional() configService?: ConfigService,
  ) {
    this.windowSeconds =
      configService?.get<AppConfiguration>('app')?.activeUsersWindowSeconds ??
      DEFAULT_ACTIVE_USERS_WINDOW_SECONDS;

    this.dropped = new Counter({
      name: 'active_users_tracker_dropped_total',
      help: 'Users evicted from the active-user window because the tracker hit its entry cap',
      registers: [registry],
    });

    const gauge = new Gauge({
      name: 'active_users',
      help: 'Distinct users seen on an authenticated request within the window',
      labelNames: ['window'] as const,
      registers: [registry],
      // Evaluated at scrape time, which is also the only moment expired
      // entries are pruned — there is no background timer.
      collect: () => {
        gauge.set({ window: `${this.windowSeconds}s` }, this.countActive());
      },
    });
  }

  /** O(1). Called on every authenticated request, so it must stay O(1). */
  record(userId: string): void {
    try {
      if (userId === '') {
        return;
      }

      // delete + set keeps the Map ordered oldest-first, which is what makes
      // both the eviction below and the prune in countActive() cheap.
      this.lastSeen.delete(userId);
      this.lastSeen.set(userId, Date.now());

      if (this.lastSeen.size > ACTIVE_USERS_MAX_ENTRIES) {
        const oldest = this.lastSeen.keys().next();
        if (oldest.done !== true) {
          this.lastSeen.delete(oldest.value);
          this.dropped.inc();
        }
      }
    } catch {
      // Never let bookkeeping break an authenticated request.
    }
  }

  /** Number tracked right now, after dropping everything past the window. */
  countActive(now: number = Date.now()): number {
    const cutoff = now - this.windowSeconds * 1000;

    for (const [userId, seenAt] of this.lastSeen) {
      // Oldest first: the first entry still inside the window ends the scan.
      if (seenAt > cutoff) {
        break;
      }
      this.lastSeen.delete(userId);
    }

    return this.lastSeen.size;
  }
}
