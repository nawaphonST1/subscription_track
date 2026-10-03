import { ConfigModule } from '@nestjs/config';
import { getQueueToken } from '@nestjs/bullmq';
import { Test, TestingModule } from '@nestjs/testing';
import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';

import { HttpMetricsMiddleware } from '../src/metrics/http-metrics.middleware';
import { MetricsServerService } from '../src/metrics/metrics-server.service';
import { RENEWAL_REMINDER_QUEUE } from '../src/worker/queue/renewal-reminder.queue';
import { WorkerMetricsModule } from '../src/worker/metrics/worker-metrics.module';

/**
 * The worker runs as a Nest *application context* (no HTTP adapter). This
 * test builds the same shape: metrics must be served by the standalone
 * server, and none of the API's Express-bound pieces may be reachable.
 */
describe('Worker metrics in an application context', () => {
  let context: TestingModule;
  let metricsBaseUrl: string;

  const queueMock = {
    getJobCounts: vi.fn().mockResolvedValue({
      waiting: 2,
      active: 0,
      delayed: 1,
      failed: 0,
      completed: 7,
      paused: 0,
    }),
  };

  beforeAll(async () => {
    context = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({
          isGlobal: true,
          ignoreEnvFile: true,
          // Port 0: the OS picks a free port. Mirrors the worker's own
          // 'worker' config namespace, not the API's 'app'.
          load: [() => ({ worker: { metricsPort: 0 } })],
        }),
        WorkerMetricsModule,
      ],
    })
      // No Redis anywhere in this test: the queue is a stub.
      .overrideProvider(getQueueToken(RENEWAL_REMINDER_QUEUE))
      .useValue(queueMock)
      .compile();

    await context.init();

    const port = context.get(MetricsServerService).port;
    expect(port).toBeTypeOf('number');
    metricsBaseUrl = `http://127.0.0.1:${port}`;
  });

  afterAll(async () => {
    await context.close();
  });

  it('1. serves the worker registry on the internal port', async () => {
    const response = await fetch(`${metricsBaseUrl}/metrics`);
    const body = await response.text();

    expect(response.status).toBe(200);
    expect(response.headers.get('content-type')).toContain(
      'text/plain; version=0.0.4',
    );
    expect(body).toContain(
      'worker_queue_jobs{queue="subscription-renewal-reminder",state="waiting"} 2',
    );
    expect(body).toContain(
      'worker_queue_scrape_ok{queue="subscription-renewal-reminder"} 1',
    );
    expect(body).toContain('process_cpu_user_seconds_total');
  });

  it('2. loads none of the API HTTP metrics stack', async () => {
    // The Express middleware provider must not exist in this graph at all.
    expect(() =>
      context.get(HttpMetricsMiddleware, { strict: false }),
    ).toThrow();

    const body = await (await fetch(`${metricsBaseUrl}/metrics`)).text();
    expect(body).not.toContain('http_requests_total');
    expect(body).not.toContain('http_request_duration_seconds');
    expect(body).not.toContain('active_users');
  });

  it('3. releases the metrics port when the context shuts down', async () => {
    await context.close();

    await expect(fetch(`${metricsBaseUrl}/metrics`)).rejects.toThrow();
  });
});
