import { z } from 'zod';

export const nodeEnvironments = ['development', 'test', 'production'] as const;

/**
 * METRICS_PORT=0 lets the OS pick a free port, which is how the tests avoid
 * clashing with a real metrics server. In production it is a silent failure:
 * the process starts, the endpoint listens on a port that changes on every
 * restart, and nothing can scrape it.
 *
 * Lives in its own module so the API and the worker schemas share one rule
 * without the worker having to import the API's environment schema — the two
 * are deliberately independent (see worker-env.validation.ts).
 */
export function rejectEphemeralMetricsPortInProduction(
  nodeEnv: string,
  metricsPort: number,
  context: z.RefinementCtx,
): void {
  if (nodeEnv === 'production' && metricsPort === 0) {
    context.addIssue({
      code: z.ZodIssueCode.custom,
      path: ['METRICS_PORT'],
      message:
        'METRICS_PORT must not be 0 in production: 0 binds an OS-assigned ephemeral port that changes on every restart, so nothing can scrape it. Leave it unset to use the default 9464, or set an explicit port.',
    });
  }
}
