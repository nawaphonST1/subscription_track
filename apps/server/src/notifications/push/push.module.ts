import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { WorkerConfiguration } from '../../config/worker.config';
import { PUSH_PROVIDER } from './push.constants';
import { PushProvider } from './push-provider.interface';
import { StubPushProvider } from './stub-push.provider';
import { FcmPushProvider } from './fcm-push.provider';

// Explicit provider selection driven by worker config (PUSH_PROVIDER). There
// is no silent fallback: worker-env.validation already guarantees
// PUSH_PROVIDER is 'stub' or 'fcm' (with FCM credentials present and valid
// JSON when 'fcm') before this factory ever runs, and the un-selected
// implementation is never constructed, so Firebase is never initialized
// unless PUSH_PROVIDER=fcm.
@Module({
  providers: [
    {
      provide: PUSH_PROVIDER,
      inject: [ConfigService],
      useFactory: (configService: ConfigService): PushProvider => {
        const worker = configService.getOrThrow<WorkerConfiguration>('worker');

        if (worker.pushProvider === 'stub') {
          return new StubPushProvider();
        }

        return new FcmPushProvider(worker.fcmServiceAccountJson as string);
      },
    },
  ],
  exports: [PUSH_PROVIDER],
})
export class PushModule {}
