import { Test, TestingModule } from '@nestjs/testing';

import { BusinessMetrics } from './metrics/business.metrics';
import { HttpMetrics } from './metrics/http.metrics';
import { MetricsServerService } from './metrics/metrics-server.service';
import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';

describe('AppModule', () => {
  let moduleRef: TestingModule;

  beforeAll(async () => {
    vi.stubEnv('NODE_ENV', 'test');
    vi.stubEnv('APP_HOST', '127.0.0.1');
    vi.stubEnv('PORT', '3000');
    vi.stubEnv('DB_HOST', 'localhost');
    vi.stubEnv('DB_PORT', '5432');
    vi.stubEnv('DB_NAME', 'subscription_track_test');
    vi.stubEnv('DB_USER', 'subscription_track');
    vi.stubEnv('DB_PASSWORD', 'test-password');
    vi.stubEnv(
      'DATABASE_URL',
      'postgresql://subscription_track:test-password@localhost:5432/subscription_track_test?schema=public',
    );
    vi.stubEnv(
      'JWT_SECRET',
      'test-only-secret-for-app-module-compilation-32-chars-long',
    );

    const { AppModule } = await import('./app.module');

    moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
  }, 30000);

  afterAll(() => {
    vi.unstubAllEnvs();
  });

  it('should compile the root AppModule successfully', () => {
    expect(moduleRef).toBeDefined();
  });

  // The business counters are injected with `@Optional()`, so deleting the
  // MetricsModule import from AppModule would compile and run with every
  // other test green while all business and HTTP metrics silently vanished.
  // The metrics integration specs cannot catch that: they import
  // MetricsModule directly instead of booting AppModule.
  it('wires the metrics providers into the API container', () => {
    expect(moduleRef.get(BusinessMetrics)).toBeInstanceOf(BusinessMetrics);
    expect(moduleRef.get(HttpMetrics)).toBeInstanceOf(HttpMetrics);
    expect(moduleRef.get(MetricsServerService)).toBeInstanceOf(
      MetricsServerService,
    );
  });

  it('hands AuthService a real BusinessMetrics rather than undefined', async () => {
    const { AuthService } = await import('./auth/auth.service');
    const service = moduleRef.get(AuthService);

    expect(
      (service as unknown as { metrics?: BusinessMetrics }).metrics,
    ).toBeInstanceOf(BusinessMetrics);
  });
});
