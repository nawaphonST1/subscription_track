import { Injectable, Logger } from '@nestjs/common';
import type { App } from 'firebase-admin/app';
import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import {
  PushDestination,
  PushMessage,
  PushProvider,
  PushResult,
} from './push-provider.interface';

const FIREBASE_APP_NAME = 'subscription-track-worker';

// Only codes that mean the token itself is permanently unusable. A narrow
// allow-list is intentional: `messaging/invalid-argument` can mean the
// payload was malformed rather than the token being bad, so it must NOT be
// treated as a permanent token failure.
const PERMANENT_TOKEN_ERROR_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
]);

// Known provider/network-side conditions worth a bounded BullMQ retry.
const TRANSIENT_PROVIDER_ERROR_CODES = new Set([
  'messaging/internal-error',
  'messaging/server-unavailable',
  'messaging/unknown-error',
  'messaging/quota-exceeded',
  'messaging/message-rate-exceeded',
  'messaging/device-message-rate-exceeded',
  'messaging/topics-message-rate-exceeded',
]);

function classifyFcmError(error: unknown): PushResult {
  const code = (error as { code?: unknown } | undefined)?.code;

  if (typeof code === 'string' && PERMANENT_TOKEN_ERROR_CODES.has(code)) {
    return { outcome: 'permanent_failure', reason: code };
  }

  if (typeof code === 'string' && TRANSIENT_PROVIDER_ERROR_CODES.has(code)) {
    return { outcome: 'transient_failure', reason: code };
  }

  // Unrecognized/config/programmer error: do not guess. Let it propagate so
  // the job fails loudly instead of silently invalidating a possibly-good
  // token or masking a real bug as a routine retry.
  throw error;
}

@Injectable()
export class FcmPushProvider implements PushProvider {
  private readonly logger = new Logger(FcmPushProvider.name);
  private readonly app: App;

  // Firebase must only be initialized when PUSH_PROVIDER=fcm is actually
  // selected; PushModule's factory guarantees this constructor only runs in
  // that case. Never log `serviceAccountJson` or any of its parsed fields.
  constructor(serviceAccountJson: string) {
    const credentials = JSON.parse(serviceAccountJson) as Record<
      string,
      unknown
    >;

    const existing = getApps().find((app) => app.name === FIREBASE_APP_NAME);
    this.app =
      existing ??
      initializeApp({ credential: cert(credentials) }, FIREBASE_APP_NAME);
  }

  async send(
    destination: PushDestination,
    message: PushMessage,
  ): Promise<PushResult> {
    try {
      await getMessaging(this.app).send({
        token: destination.token,
        notification: {
          title: message.title,
          body: message.body,
        },
        data: {
          notificationId: message.notificationId,
          ...(message.subscriptionId
            ? { subscriptionId: message.subscriptionId }
            : {}),
          type: 'RENEWAL_ALERT',
        },
      });

      return { outcome: 'delivered' };
    } catch (error) {
      this.logger.warn(
        `FCM send failed deviceRegistrationId=${destination.deviceRegistrationId} notificationId=${message.notificationId}`,
      );
      return classifyFcmError(error);
    }
  }
}
