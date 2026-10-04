export interface PushDestination {
  deviceRegistrationId: string;
  token: string;
}

export interface PushMessage {
  title: string;
  body: string;
  notificationId: string;
  subscriptionId?: string;
}

export type PushResult =
  | { outcome: 'delivered' }
  | { outcome: 'permanent_failure'; reason: string }
  | { outcome: 'transient_failure'; reason: string };

// Implementations MUST NOT log, return, or persist `destination.token`
// anywhere (structured logs, thrown errors, BullMQ job data). The token may
// exist transiently in memory for the duration of a single send() call.
export interface PushProvider {
  send(destination: PushDestination, message: PushMessage): Promise<PushResult>;
}
