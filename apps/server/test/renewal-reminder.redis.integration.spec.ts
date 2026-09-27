import { Queue, Worker, Job } from 'bullmq';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import {
  RENEWAL_DISCOVERY_JOB,
  RENEWAL_SEND_JOB,
} from '../src/worker/queue/renewal-reminder.queue';

// Opt-in, same shape as the BE-401/BE-403 PostgreSQL integration tests.
// Uses a queue name/prefix unique to this test run so it never touches a
// real Worker's production queue, and cleans up only what it created
// (queue.obliterate on its own queue) -- never FLUSHALL/FLUSHDB.
//
// This test's processors never resolve a meaningful job result (they either
// throw or implicitly return undefined), so ResultType is pinned to `void`
// here rather than left to inference -- a processor that only ever throws
// would otherwise infer ResultType as `never`, which is not assignable into
// a `Worker<any, any, string>[]` collection.
type RenewalReminderWorker = Worker<any, void, string>;

const runRealRedisIntegration = process.env.RUN_REDIS_INTEGRATION === '1';
const describeRealRedis = runRealRedisIntegration ? describe : describe.skip;

function assertSafeTestRedisUrl(redisUrl: string): void {
  if (process.env.NODE_ENV === 'production') {
    throw new Error(
      'Refusing to run BE-403 Redis integration tests with NODE_ENV=production',
    );
  }

  let parsed: URL;
  try {
    parsed = new URL(redisUrl);
  } catch {
    throw new Error('BE403_REAL_REDIS_URL is not a valid Redis URL');
  }

  if (parsed.protocol !== 'redis:' && parsed.protocol !== 'rediss:') {
    throw new Error('BE403_REAL_REDIS_URL must use redis:// or rediss://');
  }

  if (!['localhost', '127.0.0.1'].includes(parsed.hostname)) {
    throw new Error(
      'Refusing to run BE-403 Redis integration tests against a non-local host',
    );
  }
}

describeRealRedis('BE-403 renewal reminder against real Redis/BullMQ', () => {
  const redisUrl = process.env.BE403_REAL_REDIS_URL;
  const testPrefix = `be403-test-${process.pid}`;
  const queueName = `${testPrefix}-renewal-reminder`;
  let connection: { host: string; port: number };
  let queue: Queue;
  const workers: RenewalReminderWorker[] = [];

  beforeAll(() => {
    if (!redisUrl) {
      throw new Error(
        'BE403_REAL_REDIS_URL is required when RUN_REDIS_INTEGRATION=1',
      );
    }
    assertSafeTestRedisUrl(redisUrl);

    const parsed = new URL(redisUrl);
    connection = {
      host: parsed.hostname,
      port: parsed.port ? Number(parsed.port) : 6379,
    };

    queue = new Queue(queueName, { connection });
  });

  afterAll(async () => {
    await Promise.all(workers.map((worker) => worker.close()));
    if (queue) {
      await queue.obliterate({ force: true });
      await queue.close();
    }
  });

  it('connects to the queue and reports empty counts initially', async () => {
    const counts = await queue.getJobCounts();
    expect(counts).toBeTruthy();
  });

  it('adding a reminder job makes it visible to a Worker on the same queue', async () => {
    const job = await queue.add(RENEWAL_SEND_JOB, {
      subscriptionId: 'sub-visible',
      renewalDate: '2026-10-08',
    });

    const fetched = await Job.fromId(queue, job.id as string);
    expect(fetched?.name).toBe(RENEWAL_SEND_JOB);
    expect(fetched?.data).toEqual({
      subscriptionId: 'sub-visible',
      renewalDate: '2026-10-08',
    });
  });

  it('does not create a second active job for the same jobId', async () => {
    const jobId = 'remind-sub-dup-2026-10-08';
    await queue.add(
      RENEWAL_SEND_JOB,
      { subscriptionId: 'sub-dup', renewalDate: '2026-10-08' },
      { jobId },
    );
    await queue.add(
      RENEWAL_SEND_JOB,
      { subscriptionId: 'sub-dup', renewalDate: '2026-10-08' },
      { jobId },
    );

    const waiting = await queue.getWaiting();
    const matching = waiting.filter((waitingJob) => waitingJob.id === jobId);
    expect(matching).toHaveLength(1);
  });

  it('upserting the same JobScheduler id twice keeps exactly one logical schedule', async () => {
    const schedulerId = `${testPrefix}-discovery-scheduler`;

    await queue.upsertJobScheduler(
      schedulerId,
      { pattern: '0 0 * * *' },
      { name: RENEWAL_DISCOVERY_JOB, data: {} },
    );
    await queue.upsertJobScheduler(
      schedulerId,
      { pattern: '0 0 * * *' },
      { name: RENEWAL_DISCOVERY_JOB, data: {} },
    );

    const schedulers = await queue.getJobSchedulers();
    const matching = schedulers.filter((s) => s.key === schedulerId);
    expect(matching).toHaveLength(1);

    await queue.removeJobScheduler(schedulerId);
  });

  it('retries a job that throws, up to the configured attempts, then reports failure', async () => {
    let attempts = 0;
    const worker: RenewalReminderWorker = new Worker<any, void, string>(
      queueName,
      async () => {
        attempts += 1;
        throw new Error('simulated transient failure');
      },
      { connection },
    );
    workers.push(worker);
    await worker.waitUntilReady();

    const failed = new Promise<void>((resolve) => {
      worker.on('failed', (job) => {
        if (job?.name === RENEWAL_SEND_JOB && job.attemptsMade >= 2) {
          resolve();
        }
      });
    });

    await queue.add(
      RENEWAL_SEND_JOB,
      { subscriptionId: 'sub-retry', renewalDate: '2026-10-08' },
      { attempts: 2, backoff: { type: 'fixed', delay: 10 } },
    );

    await failed;
    expect(attempts).toBeGreaterThanOrEqual(2);
  }, 15000);
});
