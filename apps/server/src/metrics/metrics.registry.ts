import { Registry, collectDefaultMetrics } from '@prometheus-io/client';

/**
 * Injection token for the single Prometheus registry of this process.
 *
 * One registry per process, never the client library's global one: tests create
 * and discard their own registry, so metric names can never collide between
 * test files, and nothing leaks across them.
 */
export const METRICS_REGISTRY = Symbol('METRICS_REGISTRY');

export function createMetricsRegistry(): Registry {
  const registry = new Registry();

  // Process-level metrics: event-loop lag, heap/RSS, GC, CPU, handles.
  // The client gathers these at scrape time, so this registers no interval
  // timer and costs nothing between scrapes.
  collectDefaultMetrics({ register: registry });

  return registry;
}
