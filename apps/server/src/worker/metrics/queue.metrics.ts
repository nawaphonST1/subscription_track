import { Inject, Injectable, Logger } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { Gauge, Registry } from '@prometheus-io/client';
import { Queue } from 'bullmq';

import { METRICS_REGISTRY } from '../../metrics/metrics.registry';
import { RENEWAL_REMINDER_QUEUE } from '../queue/renewal-reminder.queue';

/**
 * Job states reported as gauges. A fixed list, so the `state` label can
 * never grow: `paused` is included because BullMQ's own default set
 * contains it (and asking for `waiting` implies it anyway).
 */
export const QUEUE_STATES = [
  'waiting',
  'active',
  'delayed',
  'failed',
  'completed',
  'paused',
] as const;

/**
 * Upper bound for one scrape of the queue. Prometheus' own scrape timeout is
 * typically 10s; failing fast at 2s keeps /metrics responsive when Redis is
 * unreachable, which is exactly when the scrape matters most.
 */
export const QUEUE_SCRAPE_TIMEOUT_MS = 2000;

/** Log the first failure, then only every tenth, so a Redis outage cannot flood the log. */
const LOG_EVERY_NTH_FAILURE = 10;

export async function withTimeout<T>(
  operation: Promise<T>,
  timeoutMs: number,
): Promise<T> {
  let timer: NodeJS.Timeout | undefined;

  try {
    return await Promise.race([
      operation,
      new Promise<never>((_resolve, reject) => {
        timer = setTimeout(
          () => reject(new Error('queue scrape timed out')),
          timeoutMs,
        );
        // Never keep the process alive just for this watchdog.
        timer.unref?.();
      }),
    ]);
  } finally {
    if (timer !== undefined) {
      clearTimeout(timer);
    }
  }
}

/**
 * Publishes the state of the renewal-reminder queue, read at scrape time
 * from the Queue instance the worker already owns — no extra Redis
 * connection, no background timer.
 */
@Injectable()
export class QueueMetricsCollector {
  private readonly logger = new Logger(QueueMetricsCollector.name);
  private readonly jobs: Gauge<'queue' | 'state'>;
  private readonly scrapeOk: Gauge<'queue'>;
  private failureCount = 0;
  private inFlight?: Promise<void>;

  constructor(
    @Inject(METRICS_REGISTRY) registry: Registry,
    @InjectQueue(RENEWAL_REMINDER_QUEUE) private readonly queue: Queue,
  ) {
    // Both gauges carry the same collect callback. The registry asks every
    // metric for its value concurrently, so attaching the refresh to only
    // one of them would let the other be serialised from a stale store —
    // it would lag a full scrape behind. refreshOnce() de-duplicates the
    // two calls so Redis is still queried exactly once per scrape.
    const collect = async (): Promise<void> => {
      await this.refreshOnce();
    };

    this.jobs = new Gauge({
      name: 'worker_queue_jobs',
      help: 'Jobs in the queue by state, read at scrape time',
      labelNames: ['queue', 'state'] as const,
      registers: [registry],
      collect,
    });

    this.scrapeOk = new Gauge({
      name: 'worker_queue_scrape_ok',
      help: '1 when the last queue scrape succeeded, 0 when it failed or timed out',
      labelNames: ['queue'] as const,
      registers: [registry],
      collect,
    });
  }

  /** One queue read per scrape, shared by both gauges' collect callbacks. */
  private refreshOnce(): Promise<void> {
    this.inFlight ??= this.refresh().finally(() => {
      this.inFlight = undefined;
    });

    return this.inFlight;
  }

  async refresh(): Promise<void> {
    const queue = RENEWAL_REMINDER_QUEUE;

    try {
      const counts = await withTimeout(
        this.queue.getJobCounts(...QUEUE_STATES),
        QUEUE_SCRAPE_TIMEOUT_MS,
      );

      for (const state of QUEUE_STATES) {
        this.jobs.set({ queue, state }, counts[state] ?? 0);
      }

      this.scrapeOk.set({ queue }, 1);
      this.failureCount = 0;
    } catch {
      // Drop the job gauges rather than keep the last known values: a stale
      // "0 failed, 0 waiting" reads exactly like a healthy idle queue and
      // would hide a Redis outage from both dashboards and alerts. A gap
      // plus worker_queue_scrape_ok=0 says what actually happened.
      this.jobs.reset();
      this.scrapeOk.set({ queue }, 0);
      this.noteFailure();
    }
  }

  private noteFailure(): void {
    this.failureCount += 1;

    if (
      this.failureCount === 1 ||
      this.failureCount % LOG_EVERY_NTH_FAILURE === 0
    ) {
      // No error detail: a Redis client error can carry the connection
      // string, including credentials.
      this.logger.error(
        `Queue metrics scrape failed (consecutive failures: ${this.failureCount})`,
      );
    }
  }
}
