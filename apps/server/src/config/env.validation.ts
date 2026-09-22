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
  if (
    environment.DATABASE_URL &&
    typeof environment.DATABASE_URL === 'string'
  ) {
    try {
      const parsedUrl = new URL(environment.DATABASE_URL);
      environment.DB_HOST = environment.DB_HOST || parsedUrl.hostname;
      environment.DB_PORT = environment.DB_PORT || parsedUrl.port || 5432;
      environment.DB_NAME =
        environment.DB_NAME || parsedUrl.pathname.replace(/^\//, '');
      environment.DB_USER =
        environment.DB_USER || decodeURIComponent(parsedUrl.username);
      environment.DB_PASSWORD =
        environment.DB_PASSWORD || decodeURIComponent(parsedUrl.password);
    } catch {
      // let schema handle error
    }
  }

  const result = environmentSchema.safeParse(environment);

  if (result.success) {
    if (!process.env.DATABASE_URL) {
      process.env.DATABASE_URL = `postgresql://${result.data.DB_USER}:${result.data.DB_PASSWORD}@${result.data.DB_HOST}:${result.data.DB_PORT}/${result.data.DB_NAME}?schema=public`;
    }
    return result.data;
  }

  const details = result.error.issues
    .map((issue) => `${issue.path.join('.')}: ${issue.message}`)
    .join('; ');

  throw new Error(`Invalid environment configuration: ${details}`);
}
