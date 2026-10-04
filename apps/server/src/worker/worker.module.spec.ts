import { Test, TestingModule } from '@nestjs/testing';
import { getQueueToken } from '@nestjs/bullmq';
import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';

import { MetricsServerService } from '../metrics/metrics-server.service';
import { METRICS_REGISTRY } from '../metrics/metrics.registry';
import { PrismaService } from '../prisma/prisma.service';
import { QueueMetricsCollector } from './metrics/queue.metrics';
import { WorkerJobMetrics } from './metrics/worker-job.metrics';
import { RENEWAL_REMINDER_QUEUE } from './queue/renewal-reminder.queue';

/**
 * Pins the metrics wiring of the worker's composition root.
 *
 * The worker metrics are injected with `@Optional()`, so deleting the
 * `WorkerMetricsModule` import from WorkerModule would compile, run and leave
 * every other test green while the queue gauges and job counters silently
 * disappeared. The existing worker-metrics integration spec cannot catch that:
 * it imports WorkerMetricsModule directly rather than booting WorkerModule.
 *
 * `compile()` is deliberate — it instantiates the providers without running
 * lifecycle hooks, so no BullMQ worker is started, Prisma never connects and
 * no Redis socket is opened.
 */
describe('WorkerModule metrics wiring', () => {
  let context: TestingModule;

  const queueMock = {
    getJobCounts: vi.fn().mockResolvedValue({}),
    upsertJobScheduler: vi.fn().mockResolvedValue({}),
  };

  beforeAll(async () => {
    vi.stubEnv('NODE_ENV', 'test');
    vi.stubEnv(
      'DATABASE_URL',
      'postgresql://test_user:test-password@localhost:5432/subscription_track_test?schema=public',
    );
    vi.stubEnv('PUSH_PROVIDER', 'stub');
    vi.stubEnv('METRICS_PORT', '0');
    // WorkerModule's ConfigModule.forRoot does not set ignoreEnvFile, so it
    // merges whatever .env happens to sit next to it. Pinning this value
    // keeps the spec independent of a developer's local file; with
    // PUSH_PROVIDER=stub it is never parsed or used.
    vi.stubEnv('FCM_SERVICE_ACCOUNT_JSON', '{}');

    const { WorkerModule } = await import('./worker.module');

    context = await Test.createTestingModule({ imports: [WorkerModule] })
      // No Redis and no Postgres anywhere in this test.
      .overrideProvider(getQueueToken(RENEWAL_REMINDER_QUEUE))
      .useValue(queueMock)
      .overrideProvider(PrismaService)
      .useValue({})
      .compile();
  }, 30000);

  afterAll(async () => {
    await context?.close();
    vi.unstubAllEnvs();
  });

  it('1. resolves WorkerJobMetrics from the worker container', () => {
    expect(context.get(WorkerJobMetrics)).toBeInstanceOf(WorkerJobMetrics);
  });

  it('2. resolves the queue metrics collector from the worker container', () => {
    expect(context.get(QueueMetricsCollector)).toBeInstanceOf(
      QueueMetricsCollector,
    );
  });

  it('3. resolves the metrics server and its registry', () => {
    expect(context.get(MetricsServerService)).toBeInstanceOf(
      MetricsServerService,
    );
    expect(context.get(METRICS_REGISTRY)).toBeDefined();
  });

  it('4. gives the processor its metrics recorder rather than leaving it undefined', async () => {
    const { RenewalReminderProcessor } =
      await import('./jobs/renewal-reminder.processor');
    const processor = context.get(RenewalReminderProcessor);

    // `@Optional()` means a broken import would hand the processor
    // `undefined` here instead of failing to construct.
    expect(
      (processor as unknown as { metrics?: WorkerJobMetrics }).metrics,
    ).toBeInstanceOf(WorkerJobMetrics);
  });
});
