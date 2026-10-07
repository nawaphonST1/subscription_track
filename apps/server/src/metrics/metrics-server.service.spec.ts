import type { Server } from 'node:http';
import { Registry } from '@prometheus-io/client';
import { afterEach, describe, expect, it } from 'vitest';

import {
  METRICS_HEADERS_TIMEOUT_MS,
  METRICS_REQUEST_TIMEOUT_MS,
  MetricsServerService,
} from './metrics-server.service';
import { createMetricsRegistry } from './metrics.registry';

import type { ConfigService } from '@nestjs/config';

// Port 0 asks the OS for a free port, so tests never collide with a real
// metrics server or with each other.
const configStub = {
  get: () => ({ metricsPort: 0 }),
} as unknown as ConfigService;

describe('Metrics server', () => {
  let service: MetricsServerService | undefined;

  afterEach(async () => {
    await service?.onApplicationShutdown();
    service = undefined;
  });

  const start = async (): Promise<{
    service: MetricsServerService;
    baseUrl: string;
  }> => {
    const started = new MetricsServerService(
      createMetricsRegistry(),
      configStub,
    );
    await started.onApplicationBootstrap();
    service = started;

    expect(started.port).toBeTypeOf('number');
    return { service: started, baseUrl: `http://127.0.0.1:${started.port}` };
  };

  it('1. serves the Prometheus exposition format on GET /metrics', async () => {
    const { baseUrl } = await start();

    const response = await fetch(`${baseUrl}/metrics`);
    const body = await response.text();

    expect(response.status).toBe(200);
    expect(response.headers.get('content-type')).toContain('text/plain');
    expect(response.headers.get('content-type')).toContain('version=0.0.4');
    // Raw exposition format, not the API's {success,statusCode,data} envelope.
    expect(body.startsWith('{')).toBe(false);
    expect(body).toContain('process_cpu_user_seconds_total');
    expect(body).toContain('nodejs_eventloop_lag_seconds');
  });

  it('2. answers 404 on any other path or method', async () => {
    const { baseUrl } = await start();

    expect((await fetch(`${baseUrl}/`)).status).toBe(404);
    expect((await fetch(`${baseUrl}/subscriptions`)).status).toBe(404);
    expect((await fetch(`${baseUrl}/metrics`, { method: 'POST' })).status).toBe(
      404,
    );
  });

  it('3. ignores a query string on /metrics', async () => {
    const { baseUrl } = await start();

    expect((await fetch(`${baseUrl}/metrics?format=text`)).status).toBe(200);
  });

  it('4. releases the port on application shutdown', async () => {
    const { service: started, baseUrl } = await start();

    await started.onApplicationShutdown();

    expect(started.port).toBeUndefined();
    await expect(fetch(`${baseUrl}/metrics`)).rejects.toThrow();
  });

  it('5. keeps the application running when the port cannot be bound', async () => {
    const { service: started } = await start();
    const takenPort = started.port as number;

    const blocked = new MetricsServerService(new Registry(), {
      get: () => ({ metricsPort: takenPort }),
    } as unknown as ConfigService);

    await expect(blocked.onApplicationBootstrap()).resolves.toBeUndefined();
    expect(blocked.port).toBeUndefined();
    await blocked.onApplicationShutdown();
  });
});

/**
 * Node's defaults (60s headers, 300s request) are far longer than a scrape
 * needs and let a half-open connection sit on the internal port. These read
 * the private server handle deliberately: the values are properties of the
 * listening socket, and there is no behavioural assertion that does not cost
 * five seconds of wall clock.
 */
describe('MetricsServerService socket timeouts', () => {
  it('applies the header and request timeouts to the listening server', async () => {
    const registry = new Registry();
    const service = new MetricsServerService(registry, configStub);

    await service.onApplicationBootstrap();

    try {
      const server = (service as unknown as { server?: Server }).server;

      expect(server).toBeDefined();
      expect(server?.headersTimeout).toBe(METRICS_HEADERS_TIMEOUT_MS);
      expect(server?.requestTimeout).toBe(METRICS_REQUEST_TIMEOUT_MS);
      // requestTimeout must stay above headersTimeout or Node throws.
      expect(METRICS_REQUEST_TIMEOUT_MS).toBeGreaterThan(
        METRICS_HEADERS_TIMEOUT_MS,
      );
    } finally {
      await service.onApplicationShutdown();
    }
  });
});
