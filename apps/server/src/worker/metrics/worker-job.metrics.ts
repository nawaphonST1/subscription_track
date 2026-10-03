import { Inject, Injectable } from '@nestjs/common';
import { Counter, Histogram, Registry } from '@prometheus-io/client';

import { METRICS_REGISTRY } from '../../metrics/metrics.registry';

export type JobResult = 'success' | 'failure';
export type SchedulerResult = 'success' | 'failure';

// Reminder jobs are a Postgres read plus a push call, so the interesting
// range is tens of milliseconds to a few seconds; the tail catches a stuck
// provider call.
export const JOB_DURATION_BUCKETS = [
  0.01, 0.05, 0.1, 0.25, 0.5, 1, 2, 5, 10, 30,
];

/**
 * Processing outcomes of the worker. Labels come from fixed sets only: no
 * job id, user id, subscription id or job payload ever becomes a label.
 *
 * Recording is wrapped here, so a metrics failure can never change what a
 * job does or which error BullMQ sees.
 */
@Injectable()
export class WorkerJobMetrics {
  private readonly processed: Counter<'queue' | 'result'>;
  private readonly duration: Histogram<'queue'>;
  private readonly schedulerRuns: Counter<'result'>;

  constructor(@Inject(METRICS_REGISTRY) registry: Registry) {
    this.processed = new Counter({
      name: 'worker_jobs_processed_total',
      help: 'Jobs processed by the worker, by queue and outcome',
      labelNames: ['queue', 'result'] as const,
      registers: [registry],
    });

    this.duration = new Histogram({
      name: 'worker_job_duration_seconds',
      help: 'Job processing duration in seconds, by queue',
      labelNames: ['queue'] as const,
      buckets: JOB_DURATION_BUCKETS,
      registers: [registry],
    });

    this.schedulerRuns = new Counter({
      name: 'worker_scheduler_runs_total',
      help: 'Attempts to register the recurring discovery schedule on startup',
      labelNames: ['result'] as const,
      registers: [registry],
    });
  }

  recordJob(queue: string, result: JobResult, durationSeconds: number): void {
    this.safely(() => {
      this.processed.inc({ queue, result });
      this.duration.observe({ queue }, durationSeconds);
    });
  }

  recordSchedulerRun(result: SchedulerResult): void {
    this.safely(() => this.schedulerRuns.inc({ result }));
  }

  private safely(record: () => void): void {
    try {
      record();
    } catch {
      // Observability must never change job semantics.
    }
  }
}
