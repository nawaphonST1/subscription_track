import { registerAs } from '@nestjs/config';
import { validateWorkerEnvironment } from './worker-env.validation';

export interface WorkerConfiguration {
  redisHost: string;
  redisPort: number;
  pushProvider: 'stub' | 'fcm';
  fcmServiceAccountJson?: string;
}

// Consumed only by WorkerModule. The API composition root (AppModule) never
// loads this config and never requires REDIS_HOST/REDIS_PORT/PUSH_PROVIDER.
export const workerConfig = registerAs('worker', (): WorkerConfiguration => {
  const environment = validateWorkerEnvironment(process.env);

  return {
    redisHost: environment.REDIS_HOST,
    redisPort: environment.REDIS_PORT,
    pushProvider: environment.PUSH_PROVIDER,
    fcmServiceAccountJson: environment.FCM_SERVICE_ACCOUNT_JSON,
  };
});
