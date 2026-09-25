import { describe, expect, it } from 'vitest';
import { validateWorkerEnvironment } from './worker-env.validation';

const validStubEnvironment = {
  DATABASE_URL: 'postgresql://user:pass@localhost:5432/subscription_track_test',
  PUSH_PROVIDER: 'stub',
};

describe('validateWorkerEnvironment', () => {
  it('accepts PUSH_PROVIDER=stub without any FCM credentials', () => {
    const result = validateWorkerEnvironment(validStubEnvironment);
    expect(result.PUSH_PROVIDER).toBe('stub');
    expect(result.FCM_SERVICE_ACCOUNT_JSON).toBeUndefined();
  });

  it('applies default REDIS_HOST/REDIS_PORT when not provided', () => {
    const result = validateWorkerEnvironment(validStubEnvironment);
    expect(result.REDIS_HOST).toBe('localhost');
    expect(result.REDIS_PORT).toBe(6379);
  });

  it('accepts explicit REDIS_HOST/REDIS_PORT overrides', () => {
    const result = validateWorkerEnvironment({
      ...validStubEnvironment,
      REDIS_HOST: 'redis',
      REDIS_PORT: '6380',
    });
    expect(result.REDIS_HOST).toBe('redis');
    expect(result.REDIS_PORT).toBe(6380);
  });

  it('rejects a missing PUSH_PROVIDER', () => {
    const environment = { ...validStubEnvironment } as Record<string, unknown>;
    delete environment.PUSH_PROVIDER;

    expect(() => validateWorkerEnvironment(environment)).toThrow(
      'PUSH_PROVIDER',
    );
  });

  it('rejects an unknown PUSH_PROVIDER value', () => {
    expect(() =>
      validateWorkerEnvironment({
        ...validStubEnvironment,
        PUSH_PROVIDER: 'apns',
      }),
    ).toThrow('PUSH_PROVIDER');
  });

  it('rejects PUSH_PROVIDER=fcm without FCM_SERVICE_ACCOUNT_JSON', () => {
    expect(() =>
      validateWorkerEnvironment({
        ...validStubEnvironment,
        PUSH_PROVIDER: 'fcm',
      }),
    ).toThrow('FCM_SERVICE_ACCOUNT_JSON is required when PUSH_PROVIDER=fcm');
  });

  it('rejects PUSH_PROVIDER=fcm with malformed FCM_SERVICE_ACCOUNT_JSON before any job processing', () => {
    expect(() =>
      validateWorkerEnvironment({
        ...validStubEnvironment,
        PUSH_PROVIDER: 'fcm',
        FCM_SERVICE_ACCOUNT_JSON: '{not-valid-json',
      }),
    ).toThrow('FCM_SERVICE_ACCOUNT_JSON must be valid JSON');
  });

  it('accepts PUSH_PROVIDER=fcm with valid JSON credentials', () => {
    const serviceAccount = JSON.stringify({
      project_id: 'demo-project',
      client_email: 'worker@demo-project.iam.gserviceaccount.com',
      private_key: 'not-a-real-key',
    });

    const result = validateWorkerEnvironment({
      ...validStubEnvironment,
      PUSH_PROVIDER: 'fcm',
      FCM_SERVICE_ACCOUNT_JSON: serviceAccount,
    });

    expect(result.PUSH_PROVIDER).toBe('fcm');
    expect(result.FCM_SERVICE_ACCOUNT_JSON).toBe(serviceAccount);
  });

  it('rejects a missing DATABASE_URL', () => {
    const environment = { ...validStubEnvironment } as Record<string, unknown>;
    delete environment.DATABASE_URL;

    expect(() => validateWorkerEnvironment(environment)).toThrow(
      'DATABASE_URL',
    );
  });

  it('never exposes FCM_SERVICE_ACCOUNT_JSON contents in validation error messages', () => {
    const sensitiveKey =
      '"private_key":"-----BEGIN PRIVATE KEY-----super-secret"';

    expect(() =>
      validateWorkerEnvironment({
        ...validStubEnvironment,
        PUSH_PROVIDER: 'fcm',
        FCM_SERVICE_ACCOUNT_JSON: `{${sensitiveKey}`,
      }),
    ).toThrowError(expect.not.stringContaining(sensitiveKey));
  });
});
