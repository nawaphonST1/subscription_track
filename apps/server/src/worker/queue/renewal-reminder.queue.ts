import { JobsOptions } from 'bullmq';
import {
  RENEWAL_DISCOVERY_JOB,
  RENEWAL_DISCOVERY_SCHEDULER_ID,
  RENEWAL_REMINDER_QUEUE,
  RENEWAL_SEND_JOB,
} from '../../notifications/renewal-reminder/renewal-reminder.constants';

export {
  RENEWAL_REMINDER_QUEUE,
  RENEWAL_DISCOVERY_JOB,
  RENEWAL_SEND_JOB,
  RENEWAL_DISCOVERY_SCHEDULER_ID,
};

// BE-403 MVP defaults, not domain requirements. PostgreSQL's `dedupe_key`
// unique constraint remains the permanent business dedupe layer even after
// BullMQ job history below is trimmed.
export const REMINDER_JOB_RETRY_OPTIONS: Pick<
  JobsOptions,
  'attempts' | 'backoff'
> = {
  attempts: 3,
  backoff: { type: 'exponential', delay: 5000 },
};

export const REMINDER_JOB_RETENTION_OPTIONS: Pick<
  JobsOptions,
  'removeOnComplete' | 'removeOnFail'
> = {
  removeOnComplete: { count: 500 },
  removeOnFail: { count: 500 },
};

export interface RenewalReminderJobData {
  subscriptionId: string;
  // UTC calendar date key (YYYY-MM-DD) of the renewal occurrence this job was
  // enqueued for. Never the raw push token, user profile, or full
  // subscription/Notification snapshot.
  renewalDate: string;
}
