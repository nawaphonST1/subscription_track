import { z } from 'zod';

const pushProviders = ['stub', 'fcm'] as const;

const workerEnvironmentSchema = z
  .object({
    DATABASE_URL: z.string().trim().min(1, 'DATABASE_URL is required'),
    REDIS_HOST: z.string().trim().min(1).default('localhost'),
    REDIS_PORT: z.coerce.number().int().min(1).max(65535).default(6379),
    PUSH_PROVIDER: z.enum(pushProviders, {
      message: `PUSH_PROVIDER is required and must be one of: ${pushProviders.join(', ')}`,
    }),
    FCM_SERVICE_ACCOUNT_JSON: z.string().min(1).optional(),
  })
  .superRefine((environment, context) => {
    if (
      environment.PUSH_PROVIDER === 'fcm' &&
      !environment.FCM_SERVICE_ACCOUNT_JSON
    ) {
      context.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['FCM_SERVICE_ACCOUNT_JSON'],
        message: 'FCM_SERVICE_ACCOUNT_JSON is required when PUSH_PROVIDER=fcm',
      });
      return;
    }

    if (environment.PUSH_PROVIDER === 'fcm') {
      try {
        JSON.parse(environment.FCM_SERVICE_ACCOUNT_JSON as string);
      } catch {
        context.addIssue({
          code: z.ZodIssueCode.custom,
          path: ['FCM_SERVICE_ACCOUNT_JSON'],
          message: 'FCM_SERVICE_ACCOUNT_JSON must be valid JSON',
        });
      }
    }
  });

export type WorkerEnvironmentVariables = z.output<
  typeof workerEnvironmentSchema
>;

// Worker-only environment validation. The API (main.ts / AppModule /
// env.validation.ts) MUST NOT depend on this: REDIS_HOST, REDIS_PORT,
// PUSH_PROVIDER and FCM_SERVICE_ACCOUNT_JSON are Worker runtime concerns and
// the API must remain able to start without them.
export function validateWorkerEnvironment(
  environment: Record<string, unknown>,
): WorkerEnvironmentVariables {
  const result = workerEnvironmentSchema.safeParse(environment);

  if (result.success) {
    return result.data;
  }

  const details = result.error.issues
    .map((issue) => `${issue.path.join('.')}: ${issue.message}`)
    .join('; ');

  throw new Error(`Invalid worker environment configuration: ${details}`);
}
