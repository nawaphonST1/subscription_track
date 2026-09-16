import { describe, expect, it } from 'vitest';
import { validateEnvironment } from './env.validation';

const validEnvironment = {
  DB_HOST: 'localhost',
  DB_NAME: 'subscription_track',
  DB_USER: 'subscription_track',
  DB_PASSWORD: 'test-password',
};

describe('validateEnvironment', () => {
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

  it.each(['DB_HOST', 'DB_NAME', 'DB_USER', 'DB_PASSWORD'] as const)(
    'rejects missing %s',
    (missingVariable) => {
      const environment = { ...validEnvironment };
      delete environment[missingVariable];

      expect(() => validateEnvironment(environment)).toThrow(missingVariable);
    },
  );

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
});
