# Metrics reference

Prometheus instrumentation for the API (`src/main.ts`) and the worker
(`src/worker.ts`). Everything below was read off the source in this commit, not
from memory; `file:line` references point at the definition.

## Endpoint

| | |
| --- | --- |
| Path | `/metrics`, `GET` only — anything else returns 404 (`src/metrics/metrics-server.service.ts:81-85`) |
| Port | `METRICS_PORT`, default **9464** for both processes (`src/config/env.validation.ts:12`, `src/config/worker-env.validation.ts:13`) |
| Bind address | `0.0.0.0`, container-internal (`src/metrics/metrics-server.service.ts:26`) |
| Content type | `text/plain; version=0.0.4` from the registry |
| Auth | none — the endpoint is unreachable from outside the Docker network |

It runs on its own `node:http` server, deliberately not on the API port. That
keeps `/metrics` away from the global `JwtAuthGuard` and the global
`TransformInterceptor`, which would otherwise wrap the exposition format in the
JSON envelope (`src/metrics/metrics-server.service.ts:30-37`).

**Not reachable from the host.** `apps/server/Dockerfile:34,82` expose only
8080; neither production Compose file gives `api` or `worker` a `ports:`
mapping; `infra/nginx/nginx.conf:11-12` proxies `location /` to `api:8080` and
nothing to 9464. `GET /metrics` through the public listener therefore hits the
API, where it is not a route at all — asserted at
`test/metrics.integration.spec.ts:120`.

`METRICS_PORT=0` asks the OS for a free ephemeral port. That exists for tests,
and **both schemas reject it when `NODE_ENV=production`**
(`src/config/metrics-port.validation.ts`): the process would start cleanly and
then listen on a port that changes on every restart, so nothing could scrape
it. Leaving the variable unset still gives 9464 everywhere, production
included.

A failure to bind is logged and swallowed — the process keeps serving
(`src/metrics/metrics-server.service.ts:110-116`). Running the api and the
worker on one host *without* containers means both default to 9464 and the
second one silently has no metrics endpoint. Give one of them a different port.

## API series

Registered in the API process only.

| Series | Type | Labels (allowed values) | Help |
| --- | --- | --- | --- |
| `http_requests_total` | Counter | `method`, `route`, `status` | Total HTTP requests handled, by method, route pattern and status code |
| `http_request_duration_seconds` | Histogram | `method`, `route`, `status` | HTTP request duration in seconds |
| `auth_login_total` | Counter | `result`, `method` | Credential checks by outcome and credential type |
| `subscriptions_created_total` | Counter | none | Subscriptions created |
| `subscriptions_updated_total` | Counter | none | Subscriptions updated |
| `subscriptions_deleted_total` | Counter | none | Subscriptions deleted |
| `active_users` | Gauge | `window` | Distinct users seen on an authenticated request within the window |
| `active_users_tracker_dropped_total` | Counter | none | Users evicted because the tracker hit its entry cap |

Label value sets:

- `method` — `GET POST PUT PATCH DELETE HEAD OPTIONS`, or `OTHER` for anything
  else (`src/metrics/http.metrics.ts:17-25,33-36`).
- `route` — a route pattern registered by this app (e.g. `/subscriptions/:id`),
  or the constant `unmatched` for requests that matched no route
  (`src/metrics/http.metrics.ts:12`). `/health*` and `/metrics*` are excluded
  entirely (`src/metrics/http-metrics.middleware.ts:13`).
- `status` — the HTTP status code as a string, or the fixed string `aborted`
  (see below). `aborted` is not a number, so numeric matchers such as
  `status=~"5.."` can never match it and existing 5xx panels are unaffected.
- `result` — `success` | `failure`. `method` on `auth_login_total` —
  `password` (`POST /auth/login`) | `pin` (`POST /users/me/pin/verify`)
  (`src/metrics/business.metrics.ts:7-13`).

**The two `method` values do not count failures identically.** The password
path records `failure` both when the email is unknown and when the password is
wrong (`src/auth/auth.service.ts`). The PIN path throws `NotFoundException`
for an unknown user *before* reaching the counter
(`src/users/users.service.ts`), so such a call is counted as neither success
nor failure. The path is close to unreachable — `verifyPin` takes its `userId`
from an already-validated JWT, so the user existed moments earlier — but
`auth_login_total{method="pin"}` and `{method="password"}` are not directly
comparable as failure rates.

Neither value distinguishes "no such user" from "wrong credential", which is
deliberate: a metric that did would let anyone who can read `/metrics`
enumerate accounts.
- `window` — the configured window rendered as `"900s"`
  (`src/metrics/active-users.tracker.ts:56`).

`http_request_duration_seconds` buckets (seconds):
`0.005 0.01 0.025 0.05 0.1 0.25 0.5 1 2.5 5 10`
(`src/metrics/http.metrics.ts:29-31`).

## Aborted requests

The middleware records on both `finish` and `close`, through one closure
guarded by a flag, so every request is counted exactly once
(`src/metrics/http-metrics.middleware.ts`).

- `finish` is the normal path and carries the real status code.
- a `close` without a preceding `finish` means the client hung up before the
  response completed. The server still did the work, so the request is
  recorded with `status="aborted"` rather than dropped.

This matters for reading the dashboards. Before, aborts were invisible, so a
storm of client timeouts looked like a **drop in traffic** instead of a
problem, and because aborted requests are disproportionately the slow ones
their absence biased the `http_request_duration_seconds` p99 optimistically.

To watch for it:

```promql
rate(http_requests_total{status="aborted"}[5m])
```

Excluded routes stay excluded when aborted: the guard is set before the
exclusion check, so an aborted `/health` request is not re-examined by the
second event.

## Worker series

Registered in the worker process only. `queue` is always
`subscription-renewal-reminder`
(`src/notifications/renewal-reminder/renewal-reminder.constants.ts:7`).

| Series | Type | Labels (allowed values) | Help |
| --- | --- | --- | --- |
| `worker_jobs_processed_total` | Counter | `queue`, `result` (`success`\|`failure`) | Jobs processed by the worker, by queue and outcome |
| `worker_job_duration_seconds` | Histogram | `queue` | Job processing duration in seconds |
| `worker_scheduler_runs_total` | Counter | `result` (`success`\|`failure`) | Attempts to register the recurring discovery schedule on startup |
| `worker_queue_jobs` | Gauge | `queue`, `state` | Jobs in the queue by state, read at scrape time |
| `worker_queue_scrape_ok` | Gauge | `queue` | 1 when the last queue scrape succeeded, 0 when it failed or timed out |

`state` is a fixed list: `waiting active delayed failed completed paused`
(`src/worker/metrics/queue.metrics.ts:14-21`).

`worker_job_duration_seconds` buckets (seconds):
`0.01 0.05 0.1 0.25 0.5 1 2 5 10 30`
(`src/worker/metrics/worker-job.metrics.ts:12-14`).

## Default Node/process metrics

`collectDefaultMetrics()` registers **33** series in each process
(`src/metrics/metrics.registry.ts:18`) — verified by enumerating the registry
against `@prometheus-io/client` 0.16.1, not estimated. They cover event-loop
lag percentiles, heap and heap-space sizes, RSS, external memory, GC duration,
CPU seconds, active handles/requests/resources, open and max fds, process start
time and `nodejs_version_info`.

Two of those 33 are new relative to the deprecated `prom-client` the project
swapped away from:

- `nodejs_eventloop_utilization_histogram`
- `nodejs_eventloop_utilization_summary`

They are **part of** the 33, not in addition to it. They are gathered at scrape
time, so they register no background timer and cost nothing between scrapes.

## Cardinality rules

The hard rule: **no unbounded or user-controlled value is ever a label.** No
user id, email, IP address, token, query string, raw path, job id or
subscription name appears in any series above.

- The raw request path is attacker-controlled, so unmatched requests collapse
  onto the single `route="unmatched"` series. Scan traffic shows up as a spike
  on that one series instead of creating a series per probed URL
  (`src/metrics/http.metrics.ts:6-12`).
- Unknown HTTP verbs collapse onto `method="OTHER"`.
- `state` and `result` come from closed TypeScript union types.
- `active_users` keeps user ids only as keys of an in-process `Map`; the id
  never becomes a label and never leaves the process
  (`src/metrics/active-users.tracker.ts:17-26`).

Worst case is roughly `routes × methods × statuses` for the HTTP pair, which is
bounded by the route table.

## `active_users` is per process

The gauge counts distinct users seen on an authenticated request inside a
rolling window (`ACTIVE_USERS_WINDOW_SECONDS`, default 900).

- The window is pruned **at scrape time only** — there is no background timer
  (`src/metrics/active-users.tracker.ts:53-58,86-98`).
- The count is per process and resets on restart. **With more than one API
  replica the per-replica values overlap and must not be summed**; a user
  hitting two replicas is counted twice. Use `max` over replicas as a lower
  bound, and treat the number as indicative rather than exact.
- The tracker is capped at 10 000 entries
  (`src/metrics/active-users.tracker.ts:15`). On overflow the oldest entry is
  evicted and `active_users_tracker_dropped_total` increments, so the ceiling is
  visible instead of the gauge quietly under-reporting. Alert on
  `increase(active_users_tracker_dropped_total[1h]) > 0`.

## Queue gauges: retention caveat

`worker_queue_jobs{state="completed"}` and `{state="failed"}` are **not**
lifetime totals. BullMQ is configured with `removeOnComplete: { count: 500 }`
and `removeOnFail: { count: 500 }`
(`src/worker/queue/renewal-reminder.queue.ts:31-32`), so both gauges plateau at
500 once the queue has been busy and then stop moving. They measure *retained
job records*, not work done.

For rates and totals use the counters instead:

```promql
rate(worker_jobs_processed_total{result="failure"}[5m])
```

not

```promql
rate(worker_queue_jobs{state="failed"}[5m])
```

## Redis-down signal

`worker_queue_scrape_ok == 0` means the last queue read failed or timed out.

On failure the collector **drops** the `worker_queue_jobs` series rather than
holding the last values (`src/worker/metrics/queue.metrics.ts:126-131`): a stale
`0 waiting, 0 failed` reads exactly like a healthy idle queue and would hide an
outage. A gap in `worker_queue_jobs` plus `worker_queue_scrape_ok == 0` is the
real signal.

```promql
worker_queue_scrape_ok == 0
```

Redis errors are not logged with their detail, because a Redis client error can
carry the connection string including credentials
(`src/worker/metrics/queue.metrics.ts:143-148`). Consecutive failures are logged
on the 1st and then every 10th.

## Scrape guidance

- **Interval: 15 s.** It must stay well above the worker's 2 s queue-scrape
  timeout (`src/worker/metrics/queue.metrics.ts:28`), so a slow Redis cannot
  make scrapes overlap. Anything below ~5 s is wrong for this reason.
- Scrape timeout should exceed 2 s — leave Prometheus' default 10 s.
- The two gauges share one `collect` callback and de-duplicate it, so Redis is
  queried exactly once per scrape no matter how many series are being gathered
  (`src/worker/metrics/queue.metrics.ts:71-108`).
- Scrape the api and the worker as **separate targets**. They are separate
  processes with separate registries; only the worker has `worker_*` series,
  only the api has `http_*`, `auth_*`, `subscriptions_*` and `active_users`.

## Phase 3

Phase 3 will scrape both endpoints over the internal Docker network, by the
Compose service name and container port (`api:9464`, `worker:9464`). Nothing is
published to the host and nothing traverses the public listener, so the metrics
never leave the Docker network. The agent configuration itself is out of scope
for this document.
