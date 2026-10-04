import { Injectable, Logger } from '@nestjs/common';
import {
  PushDestination,
  PushMessage,
  PushProvider,
  PushResult,
} from './push-provider.interface';

// Development/automated-test provider. Never contacts a real push service and
// never logs the destination token or message content.
@Injectable()
export class StubPushProvider implements PushProvider {
  private readonly logger = new Logger(StubPushProvider.name);

  send(
    destination: PushDestination,
    message: PushMessage,
  ): Promise<PushResult> {
    this.logger.debug(
      `Simulated push deviceRegistrationId=${destination.deviceRegistrationId} notificationId=${message.notificationId}`,
    );

    return Promise.resolve({ outcome: 'delivered' });
  }
}
