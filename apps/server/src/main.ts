import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { initSentry } from './observability/sentry';
import { setupSwagger } from './swagger/swagger.config';

import type { AppConfiguration } from './config/app.config';

async function bootstrap() {
  // DP-503. Before anything else so that a failure during Nest's own startup
  // is still reported. Returns false and logs a warning when SENTRY_DSN is
  // unset or the optional SDK is absent — it never prevents the API starting.
  await initSentry('api');

  const app = await NestFactory.create(AppModule);
  const configuration = app
    .get(ConfigService)
    .getOrThrow<AppConfiguration>('app');

  app.enableCors();
  app.useGlobalPipes(
    new ValidationPipe({
      transform: true,
      whitelist: true,
      forbidNonWhitelisted: true,
    }),
  );

  setupSwagger(app, configuration.environment);

  // Required so the internal metrics server is closed on SIGTERM/SIGINT and
  // releases its port on restart. It also makes the existing
  // OnModuleDestroy hooks (e.g. PrismaService.$disconnect) run on shutdown,
  // which previously only happened on an explicit app.close().
  app.enableShutdownHooks();

  await app.listen(configuration.port, configuration.host);
}

void bootstrap();
