import { Module } from '@nestjs/common';
import { APP_INTERCEPTOR } from '@nestjs/core';

import { SentryErrorInterceptor } from './sentry-error.interceptor';

/**
 * DP-503 wiring. Importing this module registers the Sentry error interceptor
 * globally; whether anything is actually sent is decided entirely by
 * SENTRY_DSN at bootstrap (see sentry.ts). With no DSN the interceptor stays
 * in the chain but captureException() is a no-op, which costs one function
 * call per failed request and nothing at all on the success path.
 */
@Module({
  providers: [
    {
      provide: APP_INTERCEPTOR,
      useClass: SentryErrorInterceptor,
    },
  ],
})
export class ObservabilityModule {}
