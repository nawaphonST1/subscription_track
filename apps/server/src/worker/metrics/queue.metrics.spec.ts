import { Registry } from '@prometheus-io/client';
import { Queue } from 'bullmq';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import {
  QUEUE_SCRAPE_TIMEOUT_MS,
  QUEUE_STATES,
  QueueMetricsCollector,
  withTimeout,
} from './queue.metrics';

const COUNTS = {
  waiting: 3,
  active: 1,
  delayed: 2,
  failed: 4,
  completed: 10,
  paused: 0,
};

describe('Queue metrics collector', () => {
  let registry: Registry;
  let getJobCounts: ReturnType<typeof vi.fn>;
  let collector: QueueMetricsCollector;

  beforeEach(() => {
    registry = new Registry();
    getJobCounts = vi.fn();
    collector = new QueueMetricsCollector(registry, {
      getJobCounts,
    } as unknown as Queue);
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('1. publishes one gauge per state and scrape_ok=1 on success', async () => {
    getJobCounts.mockResolvedValue(COUNTS);

    const exposition = await registry.metrics();

    expect(getJobCounts).toHaveBeenCalledWith(...QUEUE_STATES);
    expect(exposition).toContain(
      'worker_queue_jobs{queue="subscription-renewal-reminder",state="waiting"} 3',
    );
    expect(exposition).toContain(
      'worker_queue_jobs{queue="subscription-renewal-reminder",state="failed"} 4',
    );
    expect(exposition).toContain(
      'worker_queue_jobs{queue="subscription-renewal-reminder",state="completed"} 10',
    );
    expect(exposition).toContain(
      'worker_queue_scrape_ok{queue="subscription-renewal-reminder"} 1',
    );
  });

  it('2. reports scrape_ok=0 and drops the job gauges when Redis errors', async () => {
    getJobCounts.mockResolvedValueOnce(COUNTS);
    await collector.refresh();

    getJobCounts.mockRejectedValue(
      new Error('SYNTHETIC redis://user:secret@host:6379 connection refused'),
    );
    const exposition = await registry.metrics();

    expect(exposition).toContain(
      'worker_queue_scrape_ok{queue="subscription-renewal-reminder"} 0',
    );
    // Stale counts would read as a healthy idle queue, so they are dropped.
    expect(exposition).not.toContain('worker_queue_jobs{');
    // The connection string from the error must not reach the output.
    expect(exposition).not.toContain('secret');
  });

  it('3. gives up after the scrape timeout instead of hanging', async () => {
    vi.useFakeTimers();
    getJobCounts.mockReturnValue(new Promise(() => {}));

    // Driven through a real scrape: metrics() must come back within the
    // timeout even though the queue never answers.
    const scraped = registry.metrics();
    await vi.advanceTimersByTimeAsync(QUEUE_SCRAPE_TIMEOUT_MS);

    expect(await scraped).toContain(
      'worker_queue_scrape_ok{queue="subscription-renewal-reminder"} 0',
    );
  });

  it('4. recovers to scrape_ok=1 once the queue answers again', async () => {
    getJobCounts.mockRejectedValueOnce(new Error('SYNTHETIC failure'));
    await collector.refresh();
    getJobCounts.mockResolvedValue(COUNTS);

    const exposition = await registry.metrics();

    expect(exposition).toContain(
      'worker_queue_scrape_ok{queue="subscription-renewal-reminder"} 1',
    );
    expect(exposition).toContain(
      'worker_queue_jobs{queue="subscription-renewal-reminder",state="waiting"} 3',
    );
  });

  it('5. uses only the fixed queue and state label values', async () => {
    getJobCounts.mockResolvedValue(COUNTS);
    const exposition = await registry.metrics();

    const states = [
      ...exposition.matchAll(
        /worker_queue_jobs\{queue="([^"]+)",state="([^"]+)"\}/g,
      ),
    ];
    expect(new Set(states.map((match) => match[1]))).toEqual(
      new Set(['subscription-renewal-reminder']),
    );
    expect(new Set(states.map((match) => match[2]))).toEqual(
      new Set(QUEUE_STATES),
    );
  });

  describe('withTimeout', () => {
    it('6. resolves with the value when the operation is fast enough', async () => {
      await expect(withTimeout(Promise.resolve('ok'), 50)).resolves.toBe('ok');
    });

    it('7. rejects once the timeout elapses', async () => {
      vi.useFakeTimers();
      // The assertion attaches the rejection handler up front; advancing the
      // clock afterwards keeps the rejection from being briefly unhandled.
      const assertion = expect(
        withTimeout(new Promise(() => {}), 2000),
      ).rejects.toThrow('queue scrape timed out');

      await vi.advanceTimersByTimeAsync(2000);
      await assertion;
    });
  });
});

/**
 * The state label set is a contract with the dashboards and with
 * docs/metrics.md. The expected list is spelled out literally rather than
 * derived from QUEUE_STATES, so that dropping a state from the source array
 * fails this test instead of quietly rewriting both sides of the comparison.
 */
describe('worker_queue_jobs state label set', () => {
  const DOCUMENTED_STATES = [
    'active',
    'completed',
    'delayed',
    'failed',
    'paused',
    'waiting',
  ];

  it('exposes exactly the documented states', async () => {
    const registry = new Registry();
    const getJobCounts = vi.fn().mockResolvedValue(COUNTS);
    const collector = new QueueMetricsCollector(registry, {
      getJobCounts,
    } as unknown as Queue);

    await collector.refresh();
    const body = await registry.metrics();

    const states = [
      ...new Set(
        [...body.matchAll(/^worker_queue_jobs\{[^}]*state="([^"]+)"/gm)].map(
          (match) => match[1],
        ),
      ),
    ].sort();

    expect(states).toEqual(DOCUMENTED_STATES);
    expect([...QUEUE_STATES].sort()).toEqual(DOCUMENTED_STATES);
  });
});

/**
 * Timer hygiene inside withTimeout. Both properties are invisible to the
 * other tests: dropping the clearTimeout or the unref leaves every assertion
 * in this file green while the worker accumulates pending timers or keeps the
 * event loop alive on shutdown.
 */
describe('withTimeout timer hygiene', () => {
  afterEach(() => {
    vi.useRealTimers();
    vi.restoreAllMocks();
  });

  it('leaves no pending timer after the operation succeeds', async () => {
    vi.useFakeTimers();

    await withTimeout(Promise.resolve('ok'), QUEUE_SCRAPE_TIMEOUT_MS);

    expect(vi.getTimerCount()).toBe(0);
  });

  it('leaves no pending timer after the operation rejects', async () => {
    vi.useFakeTimers();

    await expect(
      withTimeout(Promise.reject(new Error('redis down')), 2000),
    ).rejects.toThrow('redis down');

    expect(vi.getTimerCount()).toBe(0);
  });

  it('unrefs the timeout timer so it never holds the process open', async () => {
    const unref = vi.fn();
    const realSetTimeout = globalThis.setTimeout;

    vi.spyOn(globalThis, 'setTimeout').mockImplementation(
      (handler: () => void, timeout?: number) => {
        const timer = realSetTimeout(handler, timeout);
        timer.unref = unref;
        return timer;
      },
    );

    await withTimeout(Promise.resolve('ok'), QUEUE_SCRAPE_TIMEOUT_MS);

    expect(unref).toHaveBeenCalledTimes(1);
  });
});
