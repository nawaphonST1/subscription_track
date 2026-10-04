import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { RENEWAL_DISCOVERY_CRON_PATTERN } from '../../notifications/renewal-reminder/renewal-reminder.constants';
import {
  RENEWAL_DISCOVERY_JOB,
  RENEWAL_DISCOVERY_SCHEDULER_ID,
  RENEWAL_REMINDER_QUEUE,
  REMINDER_JOB_RETRY_OPTIONS,
} from './renewal-reminder.queue';

// Registers (or re-registers, idempotently) the daily discovery schedule
// using BullMQ's JobScheduler API. `upsertJobScheduler` is keyed by a stable
// schedulerId at the Redis level, so multiple Worker instances/replicas
// calling this on startup converge on a single logical schedule instead of
// creating duplicates.
@Injectable()
export class RenewalReminderScheduler implements OnModuleInit {
  private readonly logger = new Logger(RenewalReminderScheduler.name);

  constructor(
    @InjectQueue(RENEWAL_REMINDER_QUEUE) private readonly queue: Queue,
  ) {}

  async onModuleInit(): Promise<void> {
    await this.queue.upsertJobScheduler(
      RENEWAL_DISCOVERY_SCHEDULER_ID,
      { pattern: RENEWAL_DISCOVERY_CRON_PATTERN },
      {
        name: RENEWAL_DISCOVERY_JOB,
        data: {},
        opts: REMINDER_JOB_RETRY_OPTIONS,
      },
    );

    this.logger.log(
      `Renewal reminder discovery scheduler registered (schedulerId=${RENEWAL_DISCOVERY_SCHEDULER_ID}, pattern=${RENEWAL_DISCOVERY_CRON_PATTERN})`,
    );
  }
}
