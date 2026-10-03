import { Registry } from '@prometheus-io/client';
import { beforeEach, describe, expect, it } from 'vitest';

import { WorkerJobMetrics } from './worker-job.metrics';
import { RENEWAL_REMINDER_QUEUE as QUEUE_NAME } from '../queue/renewal-reminder.queue';

describe('Worker job metrics', () => {
  let registry: Registry;
  let metrics: WorkerJobMetrics;

  beforeEach(() => {
    registry = new Registry();
    metrics = new WorkerJobMetrics(registry);
  });

  it('1. counts outcomes and observes durations per queue', async () => {
    metrics.recordJob(QUEUE_NAME, 'success', 0.2);
    metrics.recordJob(QUEUE_NAME, 'success', 0.4);
    metrics.recordJob(QUEUE_NAME, 'failure', 1.5);

    const exposition = await registry.metrics();

    expect(exposition).toContain(
      'worker_jobs_processed_total{queue="subscription-renewal-reminder",result="success"} 2',
    );
    expect(exposition).toContain(
      'worker_jobs_processed_total{queue="subscription-renewal-reminder",result="failure"} 1',
    );
    expect(exposition).toContain(
      'worker_job_duration_seconds_count{queue="subscription-renewal-reminder"} 3',
    );
  });

  it('2. counts scheduler registrations by outcome', async () => {
    metrics.recordSchedulerRun('success');
    metrics.recordSchedulerRun('failure');

    const exposition = await registry.metrics();

    expect(exposition).toContain(
      'worker_scheduler_runs_total{result="success"} 1',
    );
    expect(exposition).toContain(
      'worker_scheduler_runs_total{result="failure"} 1',
    );
  });

  it('3. swallows a failing counter instead of breaking the job', () => {
    const internals = metrics as unknown as {
      processed: { inc: () => void };
    };
    internals.processed.inc = () => {
      throw new Error('SYNTHETIC_COUNTER_FAILURE');
    };

    expect(() => metrics.recordJob(QUEUE_NAME, 'success', 0.1)).not.toThrow();
  });
});
