# Sentry (DP-503)

Error tracking for the API and the worker. **Off unless `SENTRY_DSN` is set**,
and the SDK is an *optional* dependency that is deliberately not in
`package.json`.

| | |
| --- | --- |
| Code | `src/observability/sentry.ts`, `sentry.scrub.ts`, `sentry-error.interceptor.ts`, `observability.module.ts` |
| Enabled by | `SENTRY_DSN` (non-empty, trimmed) |
| Package | `@sentry/nestjs` — **not installed**; see "Turning it on" |
| Processes | `api` (bootstrap + HTTP interceptor), `worker` (bootstrap only) |

## Why the SDK is loaded dynamically

`@sentry/nestjs` pulls in OpenTelemetry instrumentation for every library it
supports — around a hundred packages. Sentry is also the one item of this epic
the team agreed could be dropped if time ran out. Making every teammate's
install, every CI run and every container image carry that weight for a feature
that is off in development and off in CI was not a trade worth making.

So `sentry.ts` imports the SDK through a variable module specifier, inside a
`try`. With no DSN the import never happens at all.

**The cost, stated plainly:** setting `SENTRY_DSN` without installing the
package logs

```
WARN [Sentry] SENTRY_DSN is set but @sentry/nestjs is not installed — error tracking is off.
```

and the process keeps running with tracking disabled. Nothing crashes, and
nothing is silently pretended to work.

## Turning it on

```bash
# 1. once, in the repo
pnpm --filter server add @sentry/nestjs

# 2. on the production host, in apps/server/.env.production
SENTRY_DSN=https://<key>@o<org>.ingest.sentry.io/<project>
SENTRY_TRACES_SAMPLE_RATE=0          # traces cost quota; Prometheus already has latency
# SENTRY_RELEASE=$(git rev-parse --short HEAD)

# 3. restart
docker compose -f docker-compose-prosuction.yml up -d api worker
docker compose -f docker-compose-prosuction.yml logs api | grep -i sentry
#   expected: "Sentry enabled for the api process"
```

The DSN is a write-only ingestion key — it cannot read events — but it is still
a credential and belongs in `.env.production`, which is git-ignored.

## What is stripped before an event leaves the process

`beforeSend` and `beforeSendTransaction` both run `scrubEvent`
(`sentry.scrub.ts`), which makes three independent passes. Any one of them
alone would leak.

**By key** — the value is replaced with `[redacted]` wherever the property name
matches, at any depth: `password`, `pin`, `token` (and `refreshToken`,
`accessToken`, …), `authorization`, `cookie`/`set-cookie`, `session`,
`api_key`/`apiKey`, `jwt`, `credential`, `cardNumber`, `cvv`, `cvc`, `otp`,
`webhook`, `dsn`.

Deliberately *not* a bare `auth`, which would also match `author`. There is a
test for that.

**By shape** — redacted wherever they appear, including mid-sentence in an
exception message where no key name exists to match on:

| Shape | Becomes |
| --- | --- |
| JWT (`eyJ….….…`) | `[redacted-jwt]` |
| `Bearer …` / `Basic …` | `Bearer [redacted]` |
| 13–19 digits **that pass Luhn** | `[redacted-card]` |
| e-mail address | `[redacted-email]` |

The Luhn check is what keeps ordinary long numbers — ids, timestamps — intact.

**By field** — `request.headers`, `request.cookies` and `request.query_string`
are deleted outright and the URL is cut at the `?`. `user` is reduced to
`{ id }` and nothing else: no e-mail, no username, no IP. `sendDefaultPii` is
`false`, so Sentry's own collection of those is off as well; the scrubber is
the second line of defence, not the first.

Walking is depth-limited (8) and cycle-guarded, because an Express request
object reachable from `extra` is self-referential and would otherwise hang the
process inside `beforeSend`.

## What gets reported

- **API:** `SentryErrorInterceptor` reports any 5xx or non-`HttpException`
  thrown inside the request pipeline, then rethrows it unchanged so the
  existing `HttpExceptionFilter` still produces exactly the same response body.
  4xx is not reported — a scanner would otherwise burn the whole free-tier
  quota on 404s.
- **Worker:** no HTTP pipeline, so no interceptor. What Sentry adds there is
  the SDK's own uncaught-exception and unhandled-rejection handlers, which is
  how a BullMQ processor actually dies.

**Known gap:** Nest guards run *before* interceptors, so an exception thrown by
`JwtAuthGuard` never reaches the interceptor. In practice that is 401s on
expired tokens — ordinary traffic.

## RUNBOOK — fire a test error

`NOT-EXECUTED-LOCALLY`: needs a real DSN and a running production stack.

```bash
# On the Azure production VM, after the steps in "Turning it on".
# /__sentry-test does not exist, so this is a 404 and NOT reported — that is
# the point of the first command: it proves 4xx is filtered.
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1/__sentry-test

# A real 500 has to come from the app. The simplest honest trigger is to stop
# the database and hit an endpoint that needs it:
docker compose -f docker-compose-prosuction.yml stop postgres
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1/subscriptions   # expect 500
docker compose -f docker-compose-prosuction.yml start postgres

# Then, in Sentry: Issues -> the event should carry tags service=api,
# environment=production, and NO user e-mail, NO Authorization header,
# NO query string.
```

Verify the scrubbing on the event itself, not on trust: open the event's JSON
and confirm `request.headers` is absent and `user` has only `id`.
