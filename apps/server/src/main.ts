import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { setupSwagger } from './swagger/swagger.config';

import type { AppConfiguration } from './config/app.config';

async function bootstrap() {
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
