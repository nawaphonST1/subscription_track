import { Registry } from '@prometheus-io/client';
import { beforeEach, describe, expect, it, vi } from 'vitest';

import { RenewalReminderProcessor } from './renewal-reminder.processor';
import { WorkerJobMetrics } from '../metrics/worker-job.metrics';
import { RENEWAL_DISCOVERY_JOB } from '../queue/renewal-reminder.queue';

import type { Job } from 'bullmq';

// Separate from renewal-reminder.processor.spec.ts on purpose: that file
// covers job behaviour, this one only covers the measurement wrapper and
// that the wrapper leaves behaviour alone.
describe('RenewalReminderProcessor measurement', () => {
  let registry: Registry;
  let metrics: WorkerJobMetrics;
  let discoveryServiceMock: {
    findEligibleCandidates: ReturnType<typeof vi.fn>;
  };
  let processor: RenewalReminderProcessor;

  const job = (name: string): Job => ({ name, data: {} }) as unknown as Job;

  beforeEach(() => {
    registry = new Registry();
    metrics = new WorkerJobMetrics(registry);
    discoveryServiceMock = { findEligibleCandidates: vi.fn() };

    processor = new RenewalReminderProcessor(
      {} as never,
      {} as never,
      discoveryServiceMock as never,
      { add: vi.fn() } as never,
      { send: vi.fn() },
      metrics,
    );
  });

  it('1. counts a processed job as a success and observes its duration', async () => {
    discoveryServiceMock.findEligibleCandidates.mockResolvedValue([]);

    await processor.process(job(RENEWAL_DISCOVERY_JOB));

    const exposition = await registry.metrics();
    expect(exposition).toContain(
      'worker_jobs_processed_total{queue="subscription-renewal-reminder",result="success"} 1',
    );
    expect(exposition).toContain(
      'worker_job_duration_seconds_count{queue="subscription-renewal-reminder"} 1',
    );
  });

  it('2. rethrows the original error unchanged and counts a failure', async () => {
    const original = new Error('SYNTHETIC discovery failure');
    discoveryServiceMock.findEligibleCandidates.mockRejectedValue(original);

    await expect(processor.process(job(RENEWAL_DISCOVERY_JOB))).rejects.toBe(
      original,
    );

    const exposition = await registry.metrics();
    expect(exposition).toContain(
      'worker_jobs_processed_total{queue="subscription-renewal-reminder",result="failure"} 1',
    );
    expect(exposition).toContain(
      'worker_job_duration_seconds_count{queue="subscription-renewal-reminder"} 1',
    );
  });

  it('3. still rejects for an unsupported job name, exactly as before', async () => {
    await expect(processor.process(job('unknown-job'))).rejects.toThrow(
      'Unsupported renewal reminder job: unknown-job',
    );
  });

  it('4. leaves the job unaffected when recording throws', async () => {
    discoveryServiceMock.findEligibleCandidates.mockResolvedValue([]);
    vi.spyOn(metrics, 'recordJob').mockImplementation(() => {
      throw new Error('SYNTHETIC_METRICS_FAILURE');
    });

    await expect(
      processor.process(job(RENEWAL_DISCOVERY_JOB)),
    ).resolves.toBeUndefined();
  });

  it('5. still rethrows the job error when recording also throws', async () => {
    const original = new Error('SYNTHETIC discovery failure');
    discoveryServiceMock.findEligibleCandidates.mockRejectedValue(original);
    vi.spyOn(metrics, 'recordJob').mockImplementation(() => {
      throw new Error('SYNTHETIC_METRICS_FAILURE');
    });

    await expect(processor.process(job(RENEWAL_DISCOVERY_JOB))).rejects.toBe(
      original,
    );
  });
});
