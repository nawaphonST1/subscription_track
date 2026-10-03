import { Global, MiddlewareConsumer, Module, NestModule } from '@nestjs/common';

import { ActiveUsersTracker } from './active-users.tracker';
import { BusinessMetrics } from './business.metrics';
import { HttpMetrics } from './http.metrics';
import { HttpMetricsMiddleware } from './http-metrics.middleware';
import { MetricsCoreModule } from './metrics-core.module';

// Global for the same reason PrismaModule is: business metrics are a
// cross-cutting concern, and the alternative is adding an import line to
// every feature module that ever counts something.
// API-side metrics: everything in MetricsCoreModule, plus the HTTP request
// metrics and the business counters. The worker must not import this module
// (it registers Express middleware); it imports MetricsCoreModule instead.
@Global()
@Module({
  imports: [MetricsCoreModule],
  providers: [
    HttpMetrics,
    HttpMetricsMiddleware,
    BusinessMetrics,
    ActiveUsersTracker,
  ],
  // MetricsCoreModule is re-exported as a module, not as individual
  // providers: Nest only lets a module export what it owns, and the module
  // re-export carries METRICS_REGISTRY and MetricsServerService with it.
  exports: [
    MetricsCoreModule,
    HttpMetrics,
    BusinessMetrics,
    ActiveUsersTracker,
  ],
})
export class MetricsModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    // Express 5 (path-to-regexp 8) requires a named wildcard; '*' alone is a
    // syntax error. '{*splat}' is the Nest 11+/12 form for "every path".
    consumer.apply(HttpMetricsMiddleware).forRoutes('{*splat}');
  }
}
