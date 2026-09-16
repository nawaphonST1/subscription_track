import { z } from 'zod';

const nodeEnvironments = ['development', 'test', 'production'] as const;

const environmentSchema = z.object({
  NODE_ENV: z.enum(nodeEnvironments).default('development'),
  APP_HOST: z.string().trim().min(1).default('0.0.0.0'),
  PORT: z.coerce.number().int().min(1).max(65535).default(3000),
  DB_HOST: z.string().trim().min(1, 'DB_HOST is required'),
  DB_PORT: z.coerce.number().int().min(1).max(65535).default(5432),
  DB_NAME: z.string().trim().min(1, 'DB_NAME is required'),
  DB_USER: z.string().trim().min(1, 'DB_USER is required'),
  DB_PASSWORD: z.string().trim().min(1, 'DB_PASSWORD is required'),
});

export type EnvironmentVariables = z.output<typeof environmentSchema>;

export function validateEnvironment(
  environment: Record<string, unknown>,
): EnvironmentVariables {
  const result = environmentSchema.safeParse(environment);

  if (result.success) {
    return result.data;
  }

  const details = result.error.issues
    .map((issue) => `${issue.path.join('.')}: ${issue.message}`)
    .join('; ');

  throw new Error(`Invalid environment configuration: ${details}`);
}
