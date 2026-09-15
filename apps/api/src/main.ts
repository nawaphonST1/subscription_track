import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import type { AppConfiguration } from './config/app.config';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const configuration = app
    .get(ConfigService)
    .getOrThrow<AppConfiguration>('app');

  await app.listen(configuration.port, configuration.host);
}

void bootstrap();
