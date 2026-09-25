import { describe, expect, it, vi } from 'vitest';
import { RenewalReminderScheduler } from './renewal-reminder.scheduler';
import {
  RENEWAL_DISCOVERY_JOB,
  RENEWAL_DISCOVERY_SCHEDULER_ID,
} from './renewal-reminder.queue';

describe('RenewalReminderScheduler', () => {
  it('registers the discovery schedule with a stable schedulerId on module init', async () => {
    const queueMock = { upsertJobScheduler: vi.fn().mockResolvedValue({}) };
    const scheduler = new RenewalReminderScheduler(queueMock as any);

    await scheduler.onModuleInit();

    expect(queueMock.upsertJobScheduler).toHaveBeenCalledWith(
      RENEWAL_DISCOVERY_SCHEDULER_ID,
      { pattern: '0 0 * * *' },
      expect.objectContaining({ name: RENEWAL_DISCOVERY_JOB }),
    );
  });

  it('is idempotent: calling init twice does not create two logical schedules', async () => {
    const queueMock = { upsertJobScheduler: vi.fn().mockResolvedValue({}) };
    const scheduler = new RenewalReminderScheduler(queueMock as any);

    await scheduler.onModuleInit();
    await scheduler.onModuleInit();

    const schedulerIds = queueMock.upsertJobScheduler.mock.calls.map(
      (call: any[]) => call[0],
    );
    expect(new Set(schedulerIds).size).toBe(1);
  });
});
