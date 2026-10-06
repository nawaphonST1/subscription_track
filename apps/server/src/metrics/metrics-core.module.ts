import { Module } from '@nestjs/common';

import { MetricsServerService } from './metrics-server.service';
import { METRICS_REGISTRY, createMetricsRegistry } from './metrics.registry';

/**
 * Transport-agnostic half of the metrics setup: the registry and the
 * standalone HTTP server that exposes it.
 *
 * It is separate from MetricsModule because the worker process is built with
 * `NestFactory.createApplicationContext` and must never load Express: the
 * API-side module registers middleware through `MiddlewareConsumer`, which
 * only exists in an HTTP application. The worker imports this module, the
 * API imports MetricsModule, and both end up with one registry served on
 * METRICS_PORT by the same plain `node:http` server.
 */
@Module({
  providers: [
    { provide: METRICS_REGISTRY, useFactory: createMetricsRegistry },
    MetricsServerService,
  ],
  exports: [METRICS_REGISTRY, MetricsServerService],
})
export class MetricsCoreModule {}
