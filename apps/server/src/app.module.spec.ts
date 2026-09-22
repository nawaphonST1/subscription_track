import { Test, TestingModule } from '@nestjs/testing';
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
});
