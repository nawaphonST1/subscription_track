/**
 * DP-503 — Sentry error tracking, loaded only when SENTRY_DSN is set.
 *
 * Why the SDK is imported dynamically through a non-literal specifier instead
 * of being a normal dependency:
 *
 *   - Sentry is explicitly the droppable item of this epic. Making the build,
 *     the test run and every teammate's `pnpm install` depend on the ~100
 *     packages @sentry/nestjs pulls in (OpenTelemetry instrumentation for
 *     every supported library) is a large, shared cost for a feature that is
 *     off in development and off in CI.
 *   - With no DSN there is nothing to send to. The dynamic import means that
 *     in that case the package is never even resolved, so the process pays
 *     nothing — not import time, not memory, not the instrumentation hooks
 *     @sentry/node installs on require.
 *
 * The cost of that choice, stated plainly: `@sentry/nestjs` is NOT in
 * package.json, so setting SENTRY_DSN without installing it first logs a
 * warning and carries on with error tracking disabled. The install step is in
 * docs/sentry.md and is part of the production runbook, not of this code.
 *
 * Nothing here ever throws: an observability feature that can take the API
 * down is worse than no observability feature.
 */
import { Logger } from '@nestjs/common';

import { scrubEvent, type SentryEventLike } from './sentry.scrub';

/** The slice of the SDK this project uses. */
interface SentryLike {
  init(options: Record<string, unknown>): void;
  captureException(error: unknown): string;
  flush(timeout?: number): Promise<boolean>;
}

export type SentryServiceName = 'api' | 'worker';

const logger = new Logger('Sentry');

let client: SentryLike | null = null;

/** Seam for tests; also what makes a double bootstrap harmless. */
export function resetSentry(): void {
  client = null;
}

export function isSentryEnabled(): boolean {
  return client !== null;
}

function tracesSampleRate(): number {
  const raw = process.env.SENTRY_TRACES_SAMPLE_RATE;
  if (raw === undefined || raw.trim() === '') {
    // Off by default. Traces are billed per unit on the free tier and this
    // project already has its own latency histogram in Prometheus.
    return 0;
  }
  const parsed = Number(raw);
  return Number.isFinite(parsed) && parsed >= 0 && parsed <= 1 ? parsed : 0;
}

/**
 * Initialise Sentry if, and only if, SENTRY_DSN is set.
 *
 * @returns true when Sentry is active, false in every other case — unset DSN,
 *          package not installed, or an SDK that failed to initialise.
 */
export async function initSentry(
  service: SentryServiceName,
  loader: (specifier: string) => Promise<unknown> = defaultLoader,
): Promise<boolean> {
  const dsn = process.env.SENTRY_DSN?.trim();
  if (!dsn) {
    return false;
  }
  if (client) {
    return true;
  }

  let loaded: unknown;
  try {
    loaded = await loader('@sentry/nestjs');
  } catch {
    logger.warn(
      'SENTRY_DSN is set but @sentry/nestjs is not installed — error tracking is off. ' +
        'See apps/server/docs/sentry.md.',
    );
    return false;
  }

  const sdk = loaded as SentryLike | undefined;
  if (!sdk || typeof sdk.init !== 'function') {
    logger.warn(
      '@sentry/nestjs loaded but exposes no init() — error tracking is off.',
    );
    return false;
  }

  try {
    sdk.init({
      dsn,
      environment: process.env.NODE_ENV ?? 'development',
      release: process.env.SENTRY_RELEASE,
      serverName: service,
      // Sentry's own PII collection: IP addresses, cookies, request bodies and
      // usernames. Off. scrubEvent below is the second line of defence, not
      // the first.
      sendDefaultPii: false,
      tracesSampleRate: tracesSampleRate(),
      initialScope: { tags: { service } },
      beforeSend: (event: SentryEventLike) => scrubEvent(event),
      beforeSendTransaction: (event: SentryEventLike) => scrubEvent(event),
    });
  } catch (error) {
    logger.warn(
      `Sentry failed to initialise, continuing without it: ${describe(error)}`,
    );
    return false;
  }

  client = sdk;
  logger.log(`Sentry enabled for the ${service} process`);
  return true;
}

/** Report an exception if Sentry is on; a no-op otherwise. Never throws. */
export function captureException(error: unknown): void {
  if (!client) {
    return;
  }
  try {
    client.captureException(error);
  } catch {
    // An observability failure must not become an application failure.
  }
}

/** Give queued events a chance to leave before the process exits. */
export async function flushSentry(timeoutMs = 2000): Promise<void> {
  if (!client) {
    return;
  }
  try {
    await client.flush(timeoutMs);
  } catch {
    // Same reasoning as captureException.
  }
}

function describe(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

/**
 * The specifier is held in a `string`-typed variable on purpose: with a
 * literal, TypeScript would try to resolve '@sentry/nestjs' at compile time
 * and fail the build of a repository that does not depend on it.
 */
async function defaultLoader(specifier: string): Promise<unknown> {
  const moduleSpecifier: string = specifier;
  return import(moduleSpecifier);
}
