import { HttpException, HttpStatus } from '@nestjs/common';
import type { CallHandler, ExecutionContext } from '@nestjs/common';
import { lastValueFrom, of, throwError } from 'rxjs';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import { SentryErrorInterceptor } from './sentry-error.interceptor';
import { initSentry, resetSentry } from './sentry';

const context = {} as ExecutionContext;

function handlerThrowing(error: unknown): CallHandler {
  return { handle: () => throwError(() => error) };
}

describe('SentryErrorInterceptor', () => {
  const captured: unknown[] = [];
  const interceptor = new SentryErrorInterceptor();

  beforeEach(async () => {
    captured.length = 0;
    resetSentry();
    process.env.SENTRY_DSN = 'https://key@o0.ingest.sentry.io/0';
    await initSentry('api', async () => ({
      init: vi.fn(),
      captureException: (error: unknown) => {
        captured.push(error);
        return 'id';
      },
      flush: async () => true,
    }));
  });

  afterEach(() => {
    resetSentry();
    delete process.env.SENTRY_DSN;
  });

  it('1. passes a successful response through untouched', async () => {
    const result = await lastValueFrom(
      interceptor.intercept(context, { handle: () => of({ ok: true }) }),
    );

    expect(result).toEqual({ ok: true });
    expect(captured).toHaveLength(0);
  });

  it('2. reports a non-HttpException and rethrows it unchanged', async () => {
    const error = new Error('database is on fire');

    await expect(
      lastValueFrom(interceptor.intercept(context, handlerThrowing(error))),
    ).rejects.toBe(error);

    expect(captured).toEqual([error]);
  });

  it('3. reports 5xx HttpExceptions', async () => {
    const error = new HttpException('upstream failed', HttpStatus.BAD_GATEWAY);

    await expect(
      lastValueFrom(interceptor.intercept(context, handlerThrowing(error))),
    ).rejects.toBe(error);

    expect(captured).toEqual([error]);
  });

  it('4. ignores 4xx HttpExceptions — a scanner must not fill the quota', async () => {
    const notFound = new HttpException('nope', HttpStatus.NOT_FOUND);
    const badRequest = new HttpException('bad', HttpStatus.BAD_REQUEST);

    await expect(
      lastValueFrom(interceptor.intercept(context, handlerThrowing(notFound))),
    ).rejects.toBe(notFound);
    await expect(
      lastValueFrom(
        interceptor.intercept(context, handlerThrowing(badRequest)),
      ),
    ).rejects.toBe(badRequest);

    expect(captured).toHaveLength(0);
  });
});
