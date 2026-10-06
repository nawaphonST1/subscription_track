import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_FILTER, APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { appConfig } from './config/app.config';
import { databaseConfig } from './config/database.config';
import { validateEnvironment } from './config/env.validation';
import { PrismaModule } from './prisma/prisma.module';
import { HealthModule } from './health/health.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { PaymentCardsModule } from './payment-cards/payment-cards.module';
import { SubscriptionsModule } from './subscriptions/subscriptions.module';
import { CreepScoreModule } from './creep-score/creep-score.module';
import { SavingsModule } from './savings/savings.module';
import { NotificationsModule } from './notifications/notifications.module';
import { AdminPackagesModule } from './admin/packages/admin-packages.module';
import { DeviceRegistrationsModule } from './device-registrations/device-registrations.module';
import { PackagesModule } from './packages/packages.module';
import { MetricsModule } from './metrics/metrics.module';
import { CacheModule } from './cache/cache.module';
import { ObservabilityModule } from './observability/observability.module';
import { SecurityModule } from './common/security/security.module';
import { JwtAuthGuard } from './common/guards/jwt-auth.guard';
import { PinSetupGuard } from './common/guards/pin-setup.guard';
import { SecurityPinGuard } from './common/guards/security-pin.guard';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import { TransformInterceptor } from './common/interceptors/transform.interceptor';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [appConfig, databaseConfig],
      validate: validateEnvironment,
    }),
    PrismaModule,
    CacheModule,
    SecurityModule,
    // Registers the HTTP metrics middleware for every route and starts the
    // internal metrics server; adds no route to the public API surface.
    MetricsModule,
    // DP-503. Registers the Sentry error interceptor globally. Inert unless
    // SENTRY_DSN is set at bootstrap.
    ObservabilityModule,
    HealthModule,
    AuthModule,
    UsersModule,
    PaymentCardsModule,
    SubscriptionsModule,
    CreepScoreModule,
    SavingsModule,
    NotificationsModule,
    AdminPackagesModule,
    DeviceRegistrationsModule,
    PackagesModule,
  ],
  controllers: [AppController],
  providers: [
    AppService,
    {
      provide: APP_GUARD,
      useClass: JwtAuthGuard,
    },
    {
      provide: APP_GUARD,
      useClass: PinSetupGuard,
    },
    {
      provide: APP_GUARD,
      useClass: SecurityPinGuard,
    },
    {
      provide: APP_FILTER,
      useClass: HttpExceptionFilter,
    },
    {
      provide: APP_INTERCEPTOR,
      useClass: TransformInterceptor,
    },
  ],
})
export class AppModule {}
