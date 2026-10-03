import { Global, MiddlewareConsumer, Module, NestModule } from '@nestjs/common';

import { ActiveUsersTracker } from './active-users.tracker';
import { BusinessMetrics } from './business.metrics';
import { HttpMetrics } from './http.metrics';
import { HttpMetricsMiddleware } from './http-metrics.middleware';
import { MetricsServerService } from './metrics-server.service';
import { METRICS_REGISTRY, createMetricsRegistry } from './metrics.registry';

// Global for the same reason PrismaModule is: business metrics are a
// cross-cutting concern, and the alternative is adding an import line to
// every feature module that ever counts something.
@Global()
@Module({
  providers: [
    { provide: METRICS_REGISTRY, useFactory: createMetricsRegistry },
    HttpMetrics,
    HttpMetricsMiddleware,
    MetricsServerService,
    BusinessMetrics,
    ActiveUsersTracker,
  ],
  exports: [METRICS_REGISTRY, HttpMetrics, BusinessMetrics, ActiveUsersTracker],
})
export class MetricsModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    // Express 5 (path-to-regexp 8) requires a named wildcard; '*' alone is a
    // syntax error. '{*splat}' is the Nest 11+/12 form for "every path".
    consumer.apply(HttpMetricsMiddleware).forRoutes('{*splat}');
  }
}
