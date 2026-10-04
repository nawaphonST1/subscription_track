import { Injectable, NestMiddleware } from '@nestjs/common';
import { NextFunction, Request, Response } from 'express';

import {
  ABORTED_STATUS,
  HttpMetrics,
  UNMATCHED_ROUTE,
  type StatusLabel,
} from './http.metrics';

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
 * There is no I/O on the request path: the work happens on a response event,
 * after the response has been written or the socket has gone away.
 *
 * Both `finish` and `close` are observed. `finish` is the normal path and
 * carries the real status code. `close` fires for every response, so a guard
 * flag keeps the recording to exactly one per request; when `close` arrives
 * without a preceding `finish` the client hung up mid-flight, and the request
 * is recorded as `aborted` rather than dropped. Listening to `finish` alone
 * lost that case entirely, which made an abort storm look like a drop in
 * traffic and biased the latency histogram — aborted requests are
 * disproportionately the slow ones.
 */
@Injectable()
export class HttpMetricsMiddleware implements NestMiddleware {
  constructor(private readonly metrics: HttpMetrics) {}

  use(request: Request, response: Response, next: NextFunction): void {
    const startedAt = process.hrtime.bigint();
    // Set before any early return, so an excluded route is not re-examined by
    // the second event and mistaken for an abort.
    let recorded = false;

    const record = (status: StatusLabel): void => {
      if (recorded) {
        return;
      }
      recorded = true;

      // A failure here must never surface to the client: the response has
      // already been sent, and a broken metric is not worth an error log per
      // request.
      try {
        const durationSeconds =
          Number(process.hrtime.bigint() - startedAt) / 1e9;

        // `route` is only populated once Express has matched a handler, which
        // has happened by the time either event fires. Unmatched requests keep
        // it undefined — exactly the case that must collapse to one label
        // value.
        const matched = joinRoutePattern(
          request.baseUrl,
          extractRoutePath(request),
        );
        const route = matched ?? UNMATCHED_ROUTE;

        if (isExcludedRoute(route)) {
          return;
        }

        this.metrics.record(request.method, route, status, durationSeconds);
      } catch {
        // Intentionally silent, see above.
      }
    };

    response.once('finish', () => record(response.statusCode));
    response.once('close', () => record(ABORTED_STATUS));

    next();
  }
}
