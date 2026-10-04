import { EventEmitter } from 'node:events';
import { Registry } from '@prometheus-io/client';
import { beforeEach, describe, expect, it, vi } from 'vitest';

import { HttpMetrics } from './http.metrics';
import { HttpMetricsMiddleware } from './http-metrics.middleware';

import type { NextFunction, Request, Response } from 'express';

interface FakeResponse extends EventEmitter {
  statusCode: number;
}

function createFakeResponse(statusCode = 200): FakeResponse {
  const response = new EventEmitter() as FakeResponse;
  response.statusCode = statusCode;
  return response;
}

/**
 * Covers the `close` half of the middleware: a client that hangs up mid-flight
 * never emits `finish`, so recording only on `finish` dropped the request
 * entirely even though the server had already done the work.
 */
describe('HTTP metrics middleware — aborted requests', () => {
  let registry: Registry;
  let middleware: HttpMetricsMiddleware;

  const start = (request: Partial<Request>, statusCode = 200): FakeResponse => {
    const response = createFakeResponse(statusCode);
    const next: NextFunction = vi.fn();
    middleware.use(request as Request, response as unknown as Response, next);
    expect(next).toHaveBeenCalledTimes(1);
    return response;
  };

  const matched = (path: string): Partial<Request> => ({
    method: 'GET',
    baseUrl: '',
    route: { path },
  });

  beforeEach(() => {
    registry = new Registry();
    middleware = new HttpMetricsMiddleware(new HttpMetrics(registry));
  });

  it('1. records status="aborted" when close fires without finish', async () => {
    start(matched('/subscriptions/:id')).emit('close');

    expect(await registry.metrics()).toContain(
      'http_requests_total{method="GET",route="/subscriptions/:id",status="aborted"} 1',
    );
  });

  it('2. observes the duration histogram for an aborted request', async () => {
    start(matched('/subscriptions/:id')).emit('close');

    expect(await registry.metrics()).toContain(
      'http_request_duration_seconds_count{method="GET",route="/subscriptions/:id",status="aborted"} 1',
    );
  });

  it('3. records exactly once, with the real status, when finish is followed by close', async () => {
    const response = start(matched('/subscriptions/:id'), 201);
    response.emit('finish');
    response.emit('close');

    const body = await registry.metrics();
    expect(body).toContain(
      'http_requests_total{method="GET",route="/subscriptions/:id",status="201"} 1',
    );
    expect(body).not.toContain('status="aborted"');
  });

  it('4. does not double count when close fires twice', async () => {
    const response = start(matched('/subscriptions/:id'));
    response.emit('close');
    response.emit('close');

    expect(await registry.metrics()).toContain(
      'http_requests_total{method="GET",route="/subscriptions/:id",status="aborted"} 1',
    );
  });

  it('5. keeps excluded routes excluded when they are aborted', async () => {
    start(matched('/health')).emit('close');
    start(matched('/metrics')).emit('close');

    const body = await registry.metrics();
    expect(body).not.toContain('route="/health"');
    expect(body).not.toContain('route="/metrics"');
  });

  it('6. collapses an aborted unmatched request onto route="unmatched"', async () => {
    start({ method: 'GET', baseUrl: '', route: undefined }).emit('close');

    expect(await registry.metrics()).toContain(
      'http_requests_total{method="GET",route="unmatched",status="aborted"} 1',
    );
  });

  it('7. never lets a recording failure escape the close handler', () => {
    const exploding = {
      record: vi.fn(() => {
        throw new Error('registry exploded');
      }),
    } as unknown as HttpMetrics;
    const failing = new HttpMetricsMiddleware(exploding);

    const response = createFakeResponse();
    failing.use(
      matched('/subscriptions/:id') as Request,
      response as unknown as Response,
      vi.fn(),
    );

    expect(() => response.emit('close')).not.toThrow();
  });
});
