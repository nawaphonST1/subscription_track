import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import { validateEnvironment } from './env.validation';
import { validateWorkerEnvironment } from './worker-env.validation';

const TEST_JWT_SECRET = 'deterministic-test-only-jwt-secret-minimum-32-chars';

const validApiEnvironment = {
  DB_HOST: 'localhost',
  DB_NAME: 'subscription_track',
  DB_USER: 'subscription_track',
  DB_PASSWORD: 'test-password',
  JWT_SECRET: TEST_JWT_SECRET,
};

const validWorkerEnvironment = {
  DATABASE_URL: 'postgresql://user:pass@localhost:5432/subscription_track_test',
  PUSH_PROVIDER: 'stub',
};

/**
 * METRICS_PORT=0 is how the tests get an OS-assigned port without clashing
 * with a real metrics server. In production it would start cleanly and then
 * listen on a port that changes on every restart, so nothing could scrape it.
 * Both schemas must refuse it, and must keep accepting it everywhere else.
 */
describe('METRICS_PORT=0 is rejected only in production', () => {
  beforeEach(() => {
    vi.stubEnv(
      'DATABASE_URL',
      'postgresql://test_user:test-password@localhost:5432/subscription_track_test?schema=public',
    );
  });

  afterEach(() => {
    vi.unstubAllEnvs();
  });

  describe('API schema', () => {
    it('1. rejects METRICS_PORT=0 when NODE_ENV=production', () => {
      expect(() =>
        validateEnvironment({
          ...validApiEnvironment,
          NODE_ENV: 'production',
          METRICS_PORT: '0',
        }),
      ).toThrow(/METRICS_PORT must not be 0 in production/);
    });

    it('2. accepts METRICS_PORT=0 in test and development', () => {
      for (const NODE_ENV of ['test', 'development']) {
        expect(
          validateEnvironment({
            ...validApiEnvironment,
            NODE_ENV,
            METRICS_PORT: '0',
          }).METRICS_PORT,
        ).toBe(0);
      }
    });

    it('3. still defaults to 9464 in production when METRICS_PORT is unset', () => {
      expect(
        validateEnvironment({
          ...validApiEnvironment,
          NODE_ENV: 'production',
        }).METRICS_PORT,
      ).toBe(9464);
    });

    it('4. accepts an explicit non-zero port in production', () => {
      expect(
        validateEnvironment({
          ...validApiEnvironment,
          NODE_ENV: 'production',
          METRICS_PORT: '9465',
        }).METRICS_PORT,
      ).toBe(9465);
    });

    it('5. still rejects an out-of-range port in production', () => {
      expect(() =>
        validateEnvironment({
          ...validApiEnvironment,
          NODE_ENV: 'production',
          METRICS_PORT: '70000',
        }),
      ).toThrow(/METRICS_PORT/);
    });

    it('6. does not echo any other environment value in the error', () => {
      try {
        validateEnvironment({
          ...validApiEnvironment,
          NODE_ENV: 'production',
          METRICS_PORT: '0',
        });
        expect.unreachable('expected validation to throw');
      } catch (error) {
        const message = (error as Error).message;
        expect(message).not.toContain(TEST_JWT_SECRET);
        expect(message).not.toContain('test-password');
      }
    });
  });

  describe('worker schema', () => {
    it('7. rejects METRICS_PORT=0 when NODE_ENV=production', () => {
      expect(() =>
        validateWorkerEnvironment({
          ...validWorkerEnvironment,
          NODE_ENV: 'production',
          METRICS_PORT: '0',
        }),
      ).toThrow(/METRICS_PORT must not be 0 in production/);
    });

    it('8. accepts METRICS_PORT=0 in test and development', () => {
      for (const NODE_ENV of ['test', 'development']) {
        expect(
          validateWorkerEnvironment({
            ...validWorkerEnvironment,
            NODE_ENV,
            METRICS_PORT: '0',
          }).METRICS_PORT,
        ).toBe(0);
      }
    });

    it('9. still defaults to 9464 in production when METRICS_PORT is unset', () => {
      expect(
        validateWorkerEnvironment({
          ...validWorkerEnvironment,
          NODE_ENV: 'production',
        }).METRICS_PORT,
      ).toBe(9464);
    });

    it('10. defaults NODE_ENV to development, so 0 stays valid for tests', () => {
      expect(
        validateWorkerEnvironment({
          ...validWorkerEnvironment,
          METRICS_PORT: '0',
        }).METRICS_PORT,
      ).toBe(0);
    });

    it('11. still rejects an out-of-range port in production', () => {
      expect(() =>
        validateWorkerEnvironment({
          ...validWorkerEnvironment,
          NODE_ENV: 'production',
          METRICS_PORT: '70000',
        }),
      ).toThrow(/METRICS_PORT/);
    });
  });
});
