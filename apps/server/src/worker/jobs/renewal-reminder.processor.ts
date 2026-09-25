import { Inject, Logger } from '@nestjs/common';
import { InjectQueue, Processor, WorkerHost } from '@nestjs/bullmq';
import { Job, Queue } from 'bullmq';
import { DeviceRegistrationStatus, SubscriptionStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../../notifications/notifications.service';
import { RenewalReminderDiscoveryService } from '../../notifications/renewal-reminder/renewal-reminder-discovery.service';
import {
  buildReminderJobId,
  isWithinReminderWindow,
  startOfUtcDay,
  toUtcDateKey,
} from '../../notifications/renewal-reminder/renewal-reminder.policy';
import { PUSH_PROVIDER } from '../../notifications/push/push.constants';
import { PushProvider } from '../../notifications/push/push-provider.interface';
import {
  RENEWAL_DISCOVERY_JOB,
  RENEWAL_REMINDER_QUEUE,
  RENEWAL_SEND_JOB,
  REMINDER_JOB_RETENTION_OPTIONS,
  REMINDER_JOB_RETRY_OPTIONS,
  RenewalReminderJobData,
} from '../queue/renewal-reminder.queue';

function buildReminderContent(
  subscriptionName: string,
  renewalDate: Date,
  now: Date,
): { title: string; body: string } {
  const daysRemaining = Math.round(
    (renewalDate.getTime() - startOfUtcDay(now).getTime()) /
      (24 * 60 * 60 * 1000),
  );

  const body =
    daysRemaining <= 0
      ? `Your ${subscriptionName} subscription renews today.`
      : `Your ${subscriptionName} subscription renews in ${daysRemaining} day${daysRemaining === 1 ? '' : 's'}.`;

  return { title: 'Upcoming renewal', body };
}

@Processor(RENEWAL_REMINDER_QUEUE)
export class RenewalReminderProcessor extends WorkerHost {
  private readonly logger = new Logger(RenewalReminderProcessor.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
    private readonly discoveryService: RenewalReminderDiscoveryService,
    @InjectQueue(RENEWAL_REMINDER_QUEUE) private readonly queue: Queue,
    @Inject(PUSH_PROVIDER) private readonly pushProvider: PushProvider,
  ) {
    super();
  }

  async process(
    job: Job<RenewalReminderJobData | Record<string, never>>,
  ): Promise<void> {
    switch (job.name) {
      case RENEWAL_DISCOVERY_JOB:
        await this.processDiscovery();
        return;
      case RENEWAL_SEND_JOB:
        await this.processReminder(job as Job<RenewalReminderJobData>);
        return;
      default:
        throw new Error(`Unsupported renewal reminder job: ${job.name}`);
    }
  }

  private async processDiscovery(): Promise<void> {
    const now = new Date();
    const candidates = await this.discoveryService.findEligibleCandidates(now);

    for (const candidate of candidates) {
      const jobData: RenewalReminderJobData = {
        subscriptionId: candidate.subscriptionId,
        renewalDate: toUtcDateKey(candidate.renewalDate),
      };

      await this.queue.add(RENEWAL_SEND_JOB, jobData, {
        jobId: buildReminderJobId(
          candidate.subscriptionId,
          candidate.renewalDate,
        ),
        ...REMINDER_JOB_RETRY_OPTIONS,
        ...REMINDER_JOB_RETENTION_OPTIONS,
      });
    }

    this.logger.log(
      `Renewal reminder discovery enqueued ${candidates.length} candidate(s)`,
    );
  }

  private async processReminder(
    job: Job<RenewalReminderJobData>,
  ): Promise<void> {
    const subscription = await this.prisma.userSubscription.findUnique({
      where: { id: job.data.subscriptionId },
      select: {
        id: true,
        user_id: true,
        name: true,
        status: true,
        next_renewal_date: true,
      },
    });

    if (!subscription || subscription.status !== SubscriptionStatus.ACTIVE) {
      this.logger.log(
        `Skipping reminder for subscriptionId=${job.data.subscriptionId}: subscription missing or not ACTIVE`,
      );
      return;
    }

    const currentRenewalDateKey = toUtcDateKey(subscription.next_renewal_date);
    if (currentRenewalDateKey !== job.data.renewalDate) {
      this.logger.log(
        `Skipping stale reminder job for subscriptionId=${subscription.id}: renewal date changed`,
      );
      return;
    }

    const now = new Date();
    if (!isWithinReminderWindow(subscription.next_renewal_date, now)) {
      this.logger.log(
        `Skipping reminder for subscriptionId=${subscription.id}: outside current eligibility window`,
      );
      return;
    }

    const { title, body } = buildReminderContent(
      subscription.name,
      subscription.next_renewal_date,
      now,
    );

    const notification =
      await this.notificationsService.ensureRenewalNotification({
        userId: subscription.user_id,
        subscriptionId: subscription.id,
        renewalDate: subscription.next_renewal_date,
        title,
        message: body,
      });

    const devices = await this.prisma.deviceRegistration.findMany({
      where: {
        user_id: subscription.user_id,
        status: DeviceRegistrationStatus.ACTIVE,
      },
      select: { id: true, push_token: true },
    });

    if (devices.length === 0) {
      this.logger.log(
        `No ACTIVE devices for subscriptionId=${subscription.id}; durable Notification retained without push`,
      );
      return;
    }

    let hadTransientFailure = false;

    for (const device of devices) {
      const result = await this.pushProvider.send(
        { deviceRegistrationId: device.id, token: device.push_token },
        {
          title,
          body,
          notificationId: notification.id,
          subscriptionId: subscription.id,
        },
      );

      if (result.outcome === 'permanent_failure') {
        await this.prisma.deviceRegistration.updateMany({
          where: {
            id: device.id,
            status: DeviceRegistrationStatus.ACTIVE,
          },
          data: {
            status: DeviceRegistrationStatus.INVALID,
            deactivated_at: new Date(),
          },
        });
        this.logger.warn(
          `Marked deviceRegistrationId=${device.id} INVALID (reason=${result.reason})`,
        );
      } else if (result.outcome === 'transient_failure') {
        hadTransientFailure = true;
        this.logger.warn(
          `Transient push failure for deviceRegistrationId=${device.id} (reason=${result.reason})`,
        );
      }
    }

    if (hadTransientFailure) {
      throw new Error(
        `Renewal reminder push had at least one transient failure for subscriptionId=${subscription.id}; BullMQ will retry`,
      );
    }
  }
}
