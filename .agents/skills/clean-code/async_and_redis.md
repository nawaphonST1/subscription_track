# ⚡ Asynchronous Processing & Redis Rules (BullMQ & Cache)

This reference document defines standards for caching, distributed coordination, and background worker queues in `subscription_track`.

---

## 1. Redis Architectural Responsibilities

Redis provides high-performance, in-memory operations. **Redis MUST NEVER become an accidental second source of truth for durable business records.** All permanent data lives in PostgreSQL.

```text
Redis Allowed Responsibilities:
├── 1. Cache (Cache-Aside pattern for read-heavy entities)
├── 2. BullMQ Backing Store (Queues, delayed jobs, retries)
├── 3. Distributed Coordination & Locks (Cross-instance concurrency control)
├── 4. Atomic Rate Limiting & Counters (API throttling)
└── 5. Ephemeral Pub/Sub (Transient notifications)
```

### Redis Clean Code Principles:
1. **Key Namespaces:**
   - Format: `<environment>:<module>:<entity>:<id>` (e.g. `prod:subscriptions:summary:usr_12345`).
   - Group related keys cleanly; never use un-namespaced keys.
2. **Mandatory TTL Policy:**
   - Every cached entry MUST have an explicit Time-To-Live (TTL).
   - Never cache indefinitely without a documented cache invalidation policy.
3. **Cache-Aside Pattern:**
   - Read flow: Check cache → on miss, read PostgreSQL → populate cache with TTL.
   - Write flow: **Write/commit to PostgreSQL first**, then invalidate or update the Redis key.
4. **Graceful Fallback:**
   - If Redis connection drops or timeouts occur, API endpoints should log a warning and fall back directly to PostgreSQL without crashing the user request.
5. **No Blocking Commands in Production:**
   - NEVER execute `KEYS *` or blocking Lua scripts in production. Use `SCAN` or precise key lookups.
6. **Distributed Locks:**
   - Use atomic lock acquisition with TTL (`SET lock:<resource> <token> NX PX 30000`).
   - Release locks safely via Lua script verifying ownership token.
   - Do NOT introduce locks unless coordination spans across separate OS processes or container instances.

---

## 2. BullMQ Worker Queues & Background Processing

Background jobs are dedicated to slow, retryable, external, or non-request-critical tasks:
- Sending FCM push notifications or email billing reminders.
- Processing bulk billing cycle rollovers.
- Third-party webhook processing.
- Long-running analytics recalculation.

```text
[NestJS API Instance] ──(Enqueue Job)──> [Redis / BullMQ Queue] ──(Poll & Execute)──> [Worker Process]
```

### Worker Clean Code Rules:
1. **Modular Monolith Execution:**
   - Workers may execute in a separate container/process, but they are compiled from the **same monolithic codebase** and share domain entities and services. Do not treat worker processes as distinct microservices.
2. **Payload DTO Contracts:**
   - Job payloads must be typed DTOs containing minimal references (e.g. `{ subscriptionId: string, alertType: '7_DAYS' }`) rather than full entity snapshots.
3. **Strict Idempotency:**
   - Background jobs WILL be retried upon network or worker failure.
   - The worker MUST check current state before performing side-effects (e.g., check `hasReminderSent(job.data.subscriptionId, today)` before firing FCM push).
4. **Retry & Backoff Configuration:**
   - Configure retry attempts and exponential backoff:
     ```typescript
     {
       attempts: 5,
       backoff: { type: 'exponential', delay: 3000 },
       removeOnComplete: true,
       removeOnFail: false,
     }
     ```
5. **Transient vs. Permanent Failure Handling:**
   - Transient failures (network timeout, rate limit) → throw to trigger BullMQ retry.
   - Permanent failures (malformed payload, entity deleted) → catch, log structured error, and complete without useless retries.
6. **No Duplicated Business Rules:**
   - Business calculations must reside in shared services or domain models, not copied into worker handlers.

---

## 3. Async Review Checklist

When reviewing background jobs or Redis usage:
- [ ] Is Redis storing durable data without a PostgreSQL backing record?
- [ ] Do all cached keys have an explicit TTL?
- [ ] Does cache invalidation happen *after* successful database transactions?
- [ ] Is the worker job handler guaranteed to be idempotent?
- [ ] Are failed jobs observable with structured error logs and job IDs?
