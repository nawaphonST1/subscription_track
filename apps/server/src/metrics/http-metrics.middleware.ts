import { Injectable, NestMiddleware } from '@nestjs/common';
import { NextFunction, Request, Response } from 'express';

import { HttpMetrics, UNMATCHED_ROUTE } from './http.metrics';

/**
 * Route patterns excluded from HTTP metrics: health probes are polled by
 * Docker and (from phase 3) by blackbox, which would otherwise dominate the
 * request rate and make the RED dashboards meaningless. `/metrics` is served
 * by a separate server that this middleware never sees, and is listed only so
 * the rule survives if that ever changes.
 */
const EXCLUDED_ROUTE_PREFIXES = ['/health', '/metrics'];

/**
 * Reads the matched route pattern defensively. Express' own types declare
 * `route` as always present, but it is genuinely undefined until a handler
 * matches — which is exactly the unmatched case this middleware must detect.
 */
export function extractRoutePath(request: Request): string | undefined {
  const route: unknown = request.route;

  if (typeof route !== 'object' || route === null) {
    return undefined;
  }

  const path: unknown = (route as { path?: unknown }).path;
  return typeof path === 'string' ? path : undefined;
}

/**
 * Joins Express' mount path with the matched route pattern. Nest registers
 * controller routes with their full path on the application router, so
 * `baseUrl` is normally empty; it is included so a future sub-application or
 * `RouterModule` prefix still yields the complete pattern.
 */
export function joinRoutePattern(
  baseUrl: string | undefined,
  routePath: string | undefined,
): string | undefined {
  if (routePath === undefined) {
    return undefined;
  }

  const joined = `${baseUrl ?? ''}${routePath}`.replace(/\/{2,}/g, '/');

  if (joined === '') {
    return '/';
  }

  return joined.length > 1 && joined.endsWith('/')
    ? joined.slice(0, -1)
    : joined;
}

export function isExcludedRoute(route: string): boolean {
  return EXCLUDED_ROUTE_PREFIXES.some(
    (prefix) => route === prefix || route.startsWith(`${prefix}/`),
  );
}

/**
 * Records one counter increment and one histogram observation per finished
 * HTTP response. Applied to every route (including unmatched ones) so 404
 * scans are visible; an interceptor could not do that, because Nest never
 * runs interceptors for requests that match no handler.
 *
 * There is no I/O on the request path: the work happens on the `finish`
 * event, after the response has been written.
 */
@Injectable()
export class HttpMetricsMiddleware implements NestMiddleware {
  constructor(private readonly metrics: HttpMetrics) {}

  use(request: Request, response: Response, next: NextFunction): void {
    const startedAt = process.hrtime.bigint();

    response.once('finish', () => {
      // A failure here must never surface to the client: the response has
      // already been sent, and a broken metric is not worth an error log per
      // request.
      try {
        const durationSeconds =
          Number(process.hrtime.bigint() - startedAt) / 1e9;

        // `route` is only populated once Express has matched a handler, which
        // has happened by the time `finish` fires. Unmatched requests keep it
        // undefined — exactly the case that must collapse to one label value.
        const matched = joinRoutePattern(
          request.baseUrl,
          extractRoutePath(request),
        );
        const route = matched ?? UNMATCHED_ROUTE;

        if (isExcludedRoute(route)) {
          return;
        }

        this.metrics.record(
          request.method,
          route,
          response.statusCode,
          durationSeconds,
        );
      } catch {
        // Intentionally silent, see above.
      }
    });

    next();
  }
}
