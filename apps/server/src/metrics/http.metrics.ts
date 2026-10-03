import { Inject, Injectable } from '@nestjs/common';
import { Counter, Histogram, Registry } from 'prom-client';

import { METRICS_REGISTRY } from './metrics.registry';

/**
 * Route label used for requests that matched no route (404s, bot scans).
 * Keeping them under one constant bounds cardinality — the raw path is
 * attacker-controlled and must never become a label value — while still
 * making scan traffic visible as a spike on this one series.
 */
export const UNMATCHED_ROUTE = 'unmatched';

/** Method label used for anything outside the known HTTP verb set. */
export const OTHER_METHOD = 'OTHER';

const KNOWN_METHODS = new Set([
  'GET',
  'POST',
  'PUT',
  'PATCH',
  'DELETE',
  'HEAD',
  'OPTIONS',
]);

// Sub-second API with a Postgres round trip per request: the interesting
// resolution is 5ms..1s, with longer buckets only to catch pathological calls.
export const HTTP_DURATION_BUCKETS = [
  0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10,
];

export function normalizeMethod(method: string | undefined): string {
  const candidate = (method ?? '').toUpperCase();
  return KNOWN_METHODS.has(candidate) ? candidate : OTHER_METHOD;
}

/**
 * HTTP request metrics. Every label has a bounded value set:
 *   method — the seven known verbs, or OTHER
 *   route  — a route pattern registered by this app, or `unmatched`
 *   status — an HTTP status code
 * No user id, email, IP, query string or raw path is ever used as a label.
 */
@Injectable()
export class HttpMetrics {
  private readonly requests: Counter<'method' | 'route' | 'status'>;
  private readonly duration: Histogram<'method' | 'route' | 'status'>;

  constructor(@Inject(METRICS_REGISTRY) registry: Registry) {
    this.requests = new Counter({
      name: 'http_requests_total',
      help: 'Total HTTP requests handled, by method, route pattern and status code',
      labelNames: ['method', 'route', 'status'] as const,
      registers: [registry],
    });

    this.duration = new Histogram({
      name: 'http_request_duration_seconds',
      help: 'HTTP request duration in seconds, by method, route pattern and status code',
      labelNames: ['method', 'route', 'status'] as const,
      buckets: HTTP_DURATION_BUCKETS,
      registers: [registry],
    });
  }

  record(
    method: string | undefined,
    route: string,
    status: number,
    durationSeconds: number,
  ): void {
    const labels = {
      method: normalizeMethod(method),
      route,
      status: String(status),
    };

    this.requests.inc(labels);
    this.duration.observe(labels, durationSeconds);
  }
}
