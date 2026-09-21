import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { validateEnvironment } from './env.validation';

const TEST_JWT_SECRET = 'deterministic-test-only-jwt-secret-minimum-32-chars';

const validEnvironment = {
  DB_HOST: 'localhost',
  DB_NAME: 'subscription_track',
  DB_USER: 'subscription_track',
  DB_PASSWORD: 'test-password',
  JWT_SECRET: TEST_JWT_SECRET,
};

describe('validateEnvironment', () => {
  beforeEach(() => {
    vi.stubEnv(
      'DATABASE_URL',
      'postgresql://test_user:test-password@localhost:5432/subscription_track_test?schema=public',
    );
  });

  afterEach(() => {
    vi.unstubAllEnvs();
  });

  it('parses valid configuration and applies safe defaults', () => {
    expect(validateEnvironment(validEnvironment)).toEqual({
      NODE_ENV: 'development',
      APP_HOST: '0.0.0.0',
      PORT: 3000,
      DB_HOST: 'localhost',
      DB_PORT: 5432,
      DB_NAME: 'subscription_track',
      DB_USER: 'subscription_track',
      DB_PASSWORD: 'test-password',
      JWT_SECRET: TEST_JWT_SECRET,
    });
  });

  it('accepts a Docker Compose service name as DB_HOST', () => {
    expect(
      validateEnvironment({ ...validEnvironment, DB_HOST: 'postgres' }).DB_HOST,
    ).toBe('postgres');
  });

  it.each(['banana', ''])(
    'rejects invalid NODE_ENV values',
    (nodeEnvironment) => {
      expect(() =>
        validateEnvironment({ ...validEnvironment, NODE_ENV: nodeEnvironment }),
      ).toThrow('NODE_ENV');
    },
  );

  it.each(['abc', '-1', '0', '70000', '3000.5'])(
    'rejects invalid PORT values (%s)',
    (port) => {
      expect(() =>
        validateEnvironment({ ...validEnvironment, PORT: port }),
      ).toThrow('PORT');
    },
  );

  it.each(['abc', '-1', '0', '70000', '5432.5'])(
    'rejects invalid DB_PORT values (%s)',
    (port) => {
      expect(() =>
        validateEnvironment({ ...validEnvironment, DB_PORT: port }),
      ).toThrow('DB_PORT');
    },
  );

  it.each([
    'DB_HOST',
    'DB_NAME',
    'DB_USER',
    'DB_PASSWORD',
    'JWT_SECRET',
  ] as const)('rejects missing %s', (missingVariable) => {
    const environment = { ...validEnvironment };
    delete environment[missingVariable];

    expect(() => validateEnvironment(environment)).toThrow(missingVariable);
  });

  it('rejects empty JWT_SECRET', () => {
    expect(() =>
      validateEnvironment({ ...validEnvironment, JWT_SECRET: '' }),
    ).toThrow('JWT_SECRET');

    expect(() =>
      validateEnvironment({ ...validEnvironment, JWT_SECRET: '   ' }),
    ).toThrow('JWT_SECRET');
  });

  it('rejects JWT_SECRET with leading or trailing whitespace instead of changing it', () => {
    const secretWithLeadingWhitespace = ` ${TEST_JWT_SECRET}`;
    const secretWithTrailingWhitespace = `${TEST_JWT_SECRET} `;

    for (const secret of [
      secretWithLeadingWhitespace,
      secretWithTrailingWhitespace,
    ]) {
      expect(() =>
        validateEnvironment({ ...validEnvironment, JWT_SECRET: secret }),
      ).toThrow('JWT_SECRET must not have leading or trailing whitespace');
    }
  });

  it('rejects JWT_SECRET below the minimum length of 32 characters', () => {
    expect(() =>
      validateEnvironment({
        ...validEnvironment,
        JWT_SECRET: 'short-secret-under-32-chars',
      }),
    ).toThrow('at least 32 characters');
  });

  it('never exposes DB_PASSWORD value in validation error messages', () => {
    const sensitivePassword = 'super-secret-production-password-xyz';
    expect(() =>
      validateEnvironment({
        ...validEnvironment,
        DB_PASSWORD: sensitivePassword,
        PORT: 'invalid-port',
      }),
    ).toThrowError(expect.not.stringContaining(sensitivePassword));
  });

  it('never exposes JWT_SECRET value in validation error messages', () => {
    const sensitiveSecret =
      'sensitive-test-secret-that-must-never-be-printed-in-logs';
    expect(() =>
      validateEnvironment({
        ...validEnvironment,
        JWT_SECRET: sensitiveSecret,
        PORT: 'invalid-port',
      }),
    ).toThrowError(expect.not.stringContaining(sensitiveSecret));
  });
});
