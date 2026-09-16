import { registerAs } from '@nestjs/config';
import { validateEnvironment } from './env.validation';

export interface DatabaseConfiguration {
  host: string;
  port: number;
  name: string;
  user: string;
  password: string;
}

export const databaseConfig = registerAs(
  'database',
  (): DatabaseConfiguration => {
    const environment = validateEnvironment(process.env);

    return {
      host: environment.DB_HOST,
      port: environment.DB_PORT,
      name: environment.DB_NAME,
      user: environment.DB_USER,
      password: environment.DB_PASSWORD,
    };
  },
);
