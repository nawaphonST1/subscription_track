/**
 * Worker runtime entrypoint. Bootstraps the BullMQ worker/scheduler in the
 * same monolithic codebase as the API, as a separate process. This must
 * never bind an HTTP port or load Swagger — it uses
 * `NestFactory.createApplicationContext`, not `NestFactory.create`.
 */
import { NestFactory } from '@nestjs/core';
import { validateWorkerEnvironment } from './config/worker-env.validation';
import { initSentry } from './observability/sentry';
import { WorkerModule } from './worker/worker.module';

async function bootstrapWorker(): Promise<void> {
  // Fail fast, before any Nest DI machinery spins up, if the Worker-only
  // environment (Redis, PUSH_PROVIDER, FCM credentials) is invalid.
  validateWorkerEnvironment(process.env);

  // DP-503. The worker has no HTTP pipeline, so there is no interceptor here:
  // what Sentry adds to this process is the SDK's own handlers for uncaught
  // exceptions and unhandled rejections, which is exactly how a BullMQ
  // processor dies when it dies.
  await initSentry('worker');

  const app = await NestFactory.createApplicationContext(WorkerModule);
  app.enableShutdownHooks();
}

if (require.main === module) {
  void bootstrapWorker();
}
