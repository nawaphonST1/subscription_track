import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import {
  captureException,
  flushSentry,
  initSentry,
  isSentryEnabled,
  resetSentry,
} from './sentry';

function fakeSdk() {
  return {
    init: vi.fn(),
    captureException: vi.fn(() => 'event-id'),
    flush: vi.fn(async () => true),
  };
}

describe('Sentry bootstrap', () => {
  const originalEnv = { ...process.env };

  beforeEach(() => {
    resetSentry();
    delete process.env.SENTRY_DSN;
    delete process.env.SENTRY_TRACES_SAMPLE_RATE;
  });

  afterEach(() => {
    resetSentry();
    process.env = { ...originalEnv };
  });

  it('1. does nothing, and loads nothing, without SENTRY_DSN', async () => {
    const loader = vi.fn();

    await expect(initSentry('api', loader)).resolves.toBe(false);

    expect(loader).not.toHaveBeenCalled();
    expect(isSentryEnabled()).toBe(false);
  });

  it('2. treats a whitespace-only DSN as unset', async () => {
    process.env.SENTRY_DSN = '   ';
    const loader = vi.fn();

    await expect(initSentry('api', loader)).resolves.toBe(false);
    expect(loader).not.toHaveBeenCalled();
  });

  it('3. initialises the SDK when a DSN is present', async () => {
    process.env.SENTRY_DSN = 'https://key@o0.ingest.sentry.io/0';
    process.env.NODE_ENV = 'production';
    const sdk = fakeSdk();

    await expect(initSentry('worker', async () => sdk)).resolves.toBe(true);

    expect(isSentryEnabled()).toBe(true);
    const options = sdk.init.mock.calls[0][0] as Record<string, unknown>;
    expect(options.dsn).toBe('https://key@o0.ingest.sentry.io/0');
    expect(options.environment).toBe('production');
    expect(options.serverName).toBe('worker');
    expect(options.sendDefaultPii).toBe(false);
    expect(options.tracesSampleRate).toBe(0);
    expect(typeof options.beforeSend).toBe('function');
    expect(typeof options.beforeSendTransaction).toBe('function');
  });

  it('4. wires beforeSend to the scrubber', async () => {
    process.env.SENTRY_DSN = 'https://key@o0.ingest.sentry.io/0';
    const sdk = fakeSdk();
    await initSentry('api', async () => sdk);

    const options = sdk.init.mock.calls[0][0] as {
      beforeSend: (event: unknown) => { user?: unknown };
    };
    const result = options.beforeSend({ user: { id: 7, email: 'a@b.com' } });

    expect(result.user).toEqual({ id: '7' });
  });

  it('5. stays off, without throwing, when the package is not installed', async () => {
    process.env.SENTRY_DSN = 'https://key@o0.ingest.sentry.io/0';

    await expect(
      initSentry('api', async () => {
        throw new Error("Cannot find module '@sentry/nestjs'");
      }),
    ).resolves.toBe(false);

    expect(isSentryEnabled()).toBe(false);
  });

  it('6. stays off when the SDK throws during init', async () => {
    process.env.SENTRY_DSN = 'https://key@o0.ingest.sentry.io/0';
    const sdk = fakeSdk();
    sdk.init.mockImplementation(() => {
      throw new Error('bad dsn');
    });

    await expect(initSentry('api', async () => sdk)).resolves.toBe(false);
    expect(isSentryEnabled()).toBe(false);
  });

  it('7. captureException and flush are no-ops while disabled', async () => {
    expect(() => captureException(new Error('boom'))).not.toThrow();
    await expect(flushSentry(1)).resolves.toBeUndefined();
  });

  it('8. captureException reaches the SDK once enabled, and swallows SDK errors', async () => {
    process.env.SENTRY_DSN = 'https://key@o0.ingest.sentry.io/0';
    const sdk = fakeSdk();
    await initSentry('api', async () => sdk);

    const error = new Error('boom');
    captureException(error);
    expect(sdk.captureException).toHaveBeenCalledWith(error);

    sdk.captureException.mockImplementation(() => {
      throw new Error('transport down');
    });
    expect(() => captureException(error)).not.toThrow();
  });

  it('9. reads a valid traces sample rate and ignores an invalid one', async () => {
    process.env.SENTRY_DSN = 'https://key@o0.ingest.sentry.io/0';
    process.env.SENTRY_TRACES_SAMPLE_RATE = '0.25';
    const sdk = fakeSdk();
    await initSentry('api', async () => sdk);
    expect(
      (sdk.init.mock.calls[0][0] as Record<string, unknown>).tracesSampleRate,
    ).toBe(0.25);

    resetSentry();
    process.env.SENTRY_TRACES_SAMPLE_RATE = 'nonsense';
    const second = fakeSdk();
    await initSentry('api', async () => second);
    expect(
      (second.init.mock.calls[0][0] as Record<string, unknown>)
        .tracesSampleRate,
    ).toBe(0);
  });

  it('10. is idempotent — a second call does not re-initialise', async () => {
    process.env.SENTRY_DSN = 'https://key@o0.ingest.sentry.io/0';
    const sdk = fakeSdk();

    await initSentry('api', async () => sdk);
    await initSentry('api', async () => sdk);

    expect(sdk.init).toHaveBeenCalledTimes(1);
  });
});
