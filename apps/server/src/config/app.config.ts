import { registerAs } from '@nestjs/config';
import { validateEnvironment } from './env.validation';

export interface AppConfiguration {
  environment: 'development' | 'test' | 'production';
  host: string;
  port: number;
}

export const appConfig = registerAs('app', (): AppConfiguration => {
  const environment = validateEnvironment(process.env);

  return {
    environment: environment.NODE_ENV,
    host: environment.APP_HOST,
    port: environment.PORT,
  };
});
