import { EventEmitter } from 'node:events';
import { Registry } from 'prom-client';
import { beforeEach, describe, expect, it, vi } from 'vitest';

import { HttpMetrics } from './http.metrics';
import {
  HttpMetricsMiddleware,
  isExcludedRoute,
  joinRoutePattern,
} from './http-metrics.middleware';

import type { NextFunction, Request, Response } from 'express';

interface FakeResponse extends EventEmitter {
  statusCode: number;
}

function createFakeResponse(statusCode: number): FakeResponse {
  const response = new EventEmitter() as FakeResponse;
  response.statusCode = statusCode;
  return response;
}

describe('HTTP metrics middleware', () => {
  let registry: Registry;
  let middleware: HttpMetricsMiddleware;

  const runRequest = (
    request: Partial<Request>,
    statusCode = 200,
  ): FakeResponse => {
    const response = createFakeResponse(statusCode);
    const next: NextFunction = vi.fn();

    middleware.use(request as Request, response as unknown as Response, next);
    expect(next).toHaveBeenCalledTimes(1);

    response.emit('finish');
    return response;
  };

  beforeEach(() => {
    registry = new Registry();
    middleware = new HttpMetricsMiddleware(new HttpMetrics(registry));
  });

  describe('joinRoutePattern', () => {
    it('1. returns the route pattern unchanged when there is no mount prefix', () => {
      expect(joinRoutePattern('', '/subscriptions/:id')).toBe(
        '/subscriptions/:id',
      );
    });

    it('2. joins a mount prefix with the route pattern without duplicating slashes', () => {
      expect(joinRoutePattern('/subscriptions', '/:id')).toBe(
        '/subscriptions/:id',
      );
      expect(joinRoutePattern('/subscriptions/', '/:id')).toBe(
        '/subscriptions/:id',
      );
    });

    it('3. returns undefined when Express matched no route', () => {
      expect(joinRoutePattern('', undefined)).toBeUndefined();
    });

    it('4. keeps the root route as "/"', () => {
      expect(joinRoutePattern('', '/')).toBe('/');
    });
  });

  describe('isExcludedRoute', () => {
    it('5. excludes health probes and the metrics path, including sub-paths', () => {
      expect(isExcludedRoute('/health')).toBe(true);
      expect(isExcludedRoute('/health/ready')).toBe(true);
      expect(isExcludedRoute('/metrics')).toBe(true);
    });

    it('6. does not exclude application routes with a similar prefix', () => {
      expect(isExcludedRoute('/healthcheck-report')).toBe(false);
      expect(isExcludedRoute('/subscriptions/:id')).toBe(false);
    });
  });

  describe('recorded series', () => {
    it('7. labels a matched request with the full route pattern, not the concrete path', async () => {
      runRequest({
        method: 'GET',
        baseUrl: '',
        route: { path: '/subscriptions/:id' },
      } as Partial<Request>);

      const metrics = await registry.metrics();

      expect(metrics).toContain(
        'http_requests_total{method="GET",route="/subscriptions/:id",status="200"} 1',
      );
      expect(metrics).toContain('http_request_duration_seconds_count');
      // The concrete id must never reach a label value.
      expect(metrics).not.toContain('route="/subscriptions/abc-123"');
    });

    it('8. collapses unmatched paths onto the `unmatched` label', async () => {
      runRequest({ method: 'GET', baseUrl: '', url: '/wp-admin.php' }, 404);
      runRequest({ method: 'GET', baseUrl: '', url: '/.env' }, 404);

      const metrics = await registry.metrics();

      expect(metrics).toContain(
        'http_requests_total{method="GET",route="unmatched",status="404"} 2',
      );
      expect(metrics).not.toContain('wp-admin');
      expect(metrics).not.toContain('.env');
    });

    it('9. records nothing for excluded health routes', async () => {
      runRequest({
        method: 'GET',
        baseUrl: '',
        route: { path: '/health' },
      } as Partial<Request>);

      // HELP/TYPE headers always exist once a metric is registered; what
      // must be absent is any sample line for the excluded route.
      expect(await registry.metrics()).not.toMatch(/^http_requests_total\{/m);
    });

    it('10. normalizes an unknown HTTP verb to OTHER', async () => {
      runRequest({
        method: 'PROPFIND',
        baseUrl: '',
        route: { path: '/subscriptions' },
      } as Partial<Request>);

      expect(await registry.metrics()).toContain('method="OTHER"');
    });

    it('11. never lets a metrics failure escape into the response lifecycle', () => {
      const metrics = new HttpMetrics(new Registry());
      vi.spyOn(metrics, 'record').mockImplementation(() => {
        throw new Error('SYNTHETIC_METRICS_FAILURE');
      });
      const failing = new HttpMetricsMiddleware(metrics);
      const response = createFakeResponse(200);

      failing.use(
        {
          method: 'GET',
          baseUrl: '',
          route: { path: '/x' },
        } as Partial<Request> as Request,
        response as unknown as Response,
        vi.fn(),
      );

      expect(() => response.emit('finish')).not.toThrow();
    });
  });
});
