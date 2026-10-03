import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';

import { MetricsCoreModule } from '../../metrics/metrics-core.module';
import { RENEWAL_REMINDER_QUEUE } from '../queue/renewal-reminder.queue';
import { QueueMetricsCollector } from './queue.metrics';
import { WorkerJobMetrics } from './worker-job.metrics';

/**
 * Worker-side metrics. Imports MetricsCoreModule — never MetricsModule,
 * which registers Express middleware the worker's application context
 * cannot and must not load.
 */
@Module({
  imports: [
    MetricsCoreModule,
    BullModule.registerQueue({ name: RENEWAL_REMINDER_QUEUE }),
  ],
  providers: [QueueMetricsCollector, WorkerJobMetrics],
  exports: [WorkerJobMetrics, QueueMetricsCollector],
})
export class WorkerMetricsModule {}
