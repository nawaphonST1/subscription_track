import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';

import { HttpMetrics } from './http.metrics';
import { HttpMetricsMiddleware } from './http-metrics.middleware';
import { MetricsServerService } from './metrics-server.service';
import { METRICS_REGISTRY, createMetricsRegistry } from './metrics.registry';

@Module({
  providers: [
    { provide: METRICS_REGISTRY, useFactory: createMetricsRegistry },
    HttpMetrics,
    HttpMetricsMiddleware,
    MetricsServerService,
  ],
  exports: [METRICS_REGISTRY, HttpMetrics],
})
export class MetricsModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    // Express 5 (path-to-regexp 8) requires a named wildcard; '*' alone is a
    // syntax error. '{*splat}' is the Nest 11+/12 form for "every path".
    consumer.apply(HttpMetricsMiddleware).forRoutes('{*splat}');
  }
}
