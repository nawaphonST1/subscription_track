import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { BullModule } from '@nestjs/bullmq';
import { PrismaModule } from '../prisma/prisma.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { PushModule } from '../notifications/push/push.module';
import { RenewalReminderDiscoveryService } from '../notifications/renewal-reminder/renewal-reminder-discovery.service';
import { validateWorkerEnvironment } from '../config/worker-env.validation';
import { workerConfig } from '../config/worker.config';
import type { WorkerConfiguration } from '../config/worker.config';
import { RenewalReminderScheduler } from './queue/renewal-reminder.scheduler';
import { RenewalReminderProcessor } from './jobs/renewal-reminder.processor';
import { RENEWAL_REMINDER_QUEUE } from './queue/renewal-reminder.queue';

// Worker runtime composition root. This module MUST NOT import AppModule,
// main.ts, or anything that bootstraps HTTP/Swagger/JwtAuthGuard: the Worker
// is a background execution boundary in the same monolithic codebase, not a
// microservice, and is started only via `NestFactory.createApplicationContext`
// (see worker.ts), which never opens an HTTP listener.
@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [workerConfig],
      validate: validateWorkerEnvironment,
    }),
    PrismaModule,
    NotificationsModule,
    PushModule,
    BullModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => {
        const worker = configService.getOrThrow<WorkerConfiguration>('worker');
        return {
          connection: {
            host: worker.redisHost,
            port: worker.redisPort,
          },
        };
      },
    }),
    BullModule.registerQueue({ name: RENEWAL_REMINDER_QUEUE }),
  ],
  providers: [
    RenewalReminderDiscoveryService,
    RenewalReminderScheduler,
    RenewalReminderProcessor,
  ],
})
export class WorkerModule {}
