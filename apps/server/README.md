<p align="center">
  <a href="http://nestjs.com/" target="blank"><img src="https://nestjs.com/img/logo-small.svg" width="120" alt="Nest Logo" /></a>
</p>

[circleci-image]: https://img.shields.io/circleci/build/github/nestjs/nest/master?token=abc123def456
[circleci-url]: https://circleci.com/gh/nestjs/nest

  <p align="center">A progressive <a href="http://nodejs.org" target="_blank">Node.js</a> framework for building efficient and scalable server-side applications.</p>
    <p align="center">
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/v/@nestjs/core.svg" alt="NPM Version" /></a>
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/l/@nestjs/core.svg" alt="Package License" /></a>
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/dm/@nestjs/common.svg" alt="NPM Downloads" /></a>
<a href="https://circleci.com/gh/nestjs/nest" target="_blank"><img src="https://img.shields.io/circleci/build/github/nestjs/nest/master" alt="CircleCI" /></a>
<a href="https://discord.gg/G7Qnnhy" target="_blank"><img src="https://img.shields.io/badge/discord-online-brightgreen.svg" alt="Discord"/></a>
<a href="https://opencollective.com/nest#backer" target="_blank"><img src="https://opencollective.com/nest/backers/badge.svg" alt="Backers on Open Collective" /></a>
<a href="https://opencollective.com/nest#sponsor" target="_blank"><img src="https://opencollective.com/nest/sponsors/badge.svg" alt="Sponsors on Open Collective" /></a>
  <a href="https://paypal.me/kamilmysliwiec" target="_blank"><img src="https://img.shields.io/badge/Donate-PayPal-ff3f59.svg" alt="Donate us"/></a>
    <a href="https://opencollective.com/nest#sponsor"  target="_blank"><img src="https://img.shields.io/badge/Support%20us-Open%20Collective-41B883.svg" alt="Support us"></a>
  <a href="https://twitter.com/nestframework" target="_blank"><img src="https://img.shields.io/twitter/follow/nestframework.svg?style=social&label=Follow" alt="Follow us on Twitter"></a>
</p>
  <!--[![Backers on Open Collective](https://opencollective.com/nest/backers/badge.svg)](https://opencollective.com/nest#backer)
  [![Sponsors on Open Collective](https://opencollective.com/nest/sponsors/badge.svg)](https://opencollective.com/nest#sponsor)-->

## Description

[Nest](https://github.com/nestjs/nest) framework TypeScript starter repository.

## Project setup

```bash
$ pnpm install
```

## Compile and run the project

```bash
# development
$ pnpm run start

# watch mode
$ pnpm run start:dev

# production mode
$ pnpm run start:prod
```

## Run tests

```bash
# unit tests
$ pnpm run test

# e2e tests
$ pnpm run test:e2e

# test coverage
$ pnpm run test:cov
```

## Deployment

The committed Prisma migrations are the schema source of truth. Apply them
before starting the application in a fresh or deployed environment:

```bash
DATABASE_URL="postgresql://user:password@host:5432/database" pnpm prisma:migrate:deploy
```

`pnpm prisma:push` is for local prototyping only. It must not be used for
deployment because it does not apply custom migration SQL, including the
partial unique index that protects active device-registration tokens.

For an existing database that already matches the pre-BE-401 schema, verify
that it matches the committed baseline first, then adopt the baseline without
recreating existing tables and deploy the BE-401 delta:

```bash
DATABASE_URL="postgresql://user:password@host:5432/database" \
  pnpm prisma migrate resolve --applied 20260921000000_baseline
DATABASE_URL="postgresql://user:password@host:5432/database" \
  pnpm prisma:migrate:deploy
```

Run the adoption command only after an operator has verified the database
schema. It updates Prisma's migration history and is not a substitute for
schema verification.

Real PostgreSQL BE-401 integration tests are opt-in and require a dedicated
test database whose name ends with `_test`:

```bash
RUN_DB_INTEGRATION=1 \
BE401_REAL_DATABASE_URL="postgresql://postgres:postgres@localhost:55432/subscription_track_be401_test" \
pnpm vitest run test/device-registrations.postgres.integration.spec.ts
```

Never point `BE401_REAL_DATABASE_URL` at a development, shared, staging, or
production database. The test refuses production mode and database names that
do not clearly identify a test database.

## Worker runtime (BE-403)

Renewal reminders run in a **separate Worker runtime** (`src/worker.ts`),
started via `NestFactory.createApplicationContext`. It shares the same
codebase and modules as the API but never binds an HTTP port and never loads
Swagger — it is not a microservice.

The Worker requires Redis (BullMQ's backing store):

```bash
# development, with live reload
$ pnpm run start:worker:dev

# production-style, from a built dist/
$ pnpm run start:worker
```

Worker-only environment variables (validated separately from the API's own
`env.validation.ts`; the API does not need any of these to start):

- `REDIS_HOST` (default `localhost`), `REDIS_PORT` (default `6379`)
- `PUSH_PROVIDER` — required, either `stub` or `fcm`, no default and no
  silent fallback
  - `stub`: for local development and automated tests only. Never contacts a
    real push service.
  - `fcm`: dispatches real push notifications via Firebase Cloud Messaging
    and requires `FCM_SERVICE_ACCOUNT_JSON` (the full service-account JSON as
    a single-line string). The Worker fails fast at startup if
    `PUSH_PROVIDER=fcm` is set without valid credentials.

Reminder policy (MVP, fixed for all users/subscriptions until a real
reminder-preference schema exists):

- Lead time: **3 days** before `next_renewal_date`
- All calculations use **UTC** calendar days; there is no per-user timezone
  subsystem
- The discovery schedule runs **daily at 00:00 UTC**
- **Catch-up**: a renewal stays eligible for a reminder from 3 days out
  through the renewal day itself, so a missed scheduler run can still send
  before the renewal happens. Renewals already in the past are not sent.

Real Redis/BullMQ BE-403 integration tests are opt-in and use a Redis
instance/queue-prefix unique to the test run (never `FLUSHALL`/`FLUSHDB`):

```bash
RUN_REDIS_INTEGRATION=1 \
BE403_REAL_REDIS_URL="redis://localhost:56381" \
pnpm vitest run test/renewal-reminder.redis.integration.spec.ts
```

Real PostgreSQL BE-403 integration tests follow the same opt-in convention as
BE-401's, against a dedicated test database whose name ends with `_test`:

```bash
RUN_DB_INTEGRATION=1 \
BE403_REAL_DATABASE_URL="postgresql://postgres:postgres@localhost:55432/subscription_track_be403_test" \
pnpm vitest run test/renewal-reminder.postgres.integration.spec.ts
```

When you're ready to deploy your NestJS application to production, there are some key steps you can take to ensure it runs as efficiently as possible. Check out the [deployment documentation](https://docs.nestjs.com/deployment) for more information.

If you are looking for a cloud-based platform to deploy your NestJS application, check out [Mau](https://mau.nestjs.com), our official platform for deploying NestJS applications on AWS. Mau makes deployment straightforward and fast, requiring just a few simple steps:

```bash
$ pnpm install -g @nestjs/mau
$ mau deploy
```

With Mau, you can deploy your application in just a few clicks, allowing you to focus on building features rather than managing infrastructure.

## Resources

Check out a few resources that may come in handy when working with NestJS:

- Visit the [NestJS Documentation](https://docs.nestjs.com) to learn more about the framework.
- For questions and support, please visit our [Discord channel](https://discord.gg/G7Qnnhy).
- To dive deeper and get more hands-on experience, check out our official video [courses](https://courses.nestjs.com/).
- Deploy your application to AWS with the help of [NestJS Mau](https://mau.nestjs.com) in just a few clicks.
- Visualize your application graph and interact with the NestJS application in real-time using [NestJS Devtools](https://devtools.nestjs.com).
- Need help with your project (part-time to full-time)? Check out our official [enterprise support](https://enterprise.nestjs.com).
- To stay in the loop and get updates, follow us on [X](https://x.com/nestframework) and [LinkedIn](https://linkedin.com/company/nestjs).
- Looking for a job, or have a job to offer? Check out our official [Jobs board](https://jobs.nestjs.com).

## Support

Nest is an MIT-licensed open source project. It can grow thanks to the sponsors and support by the amazing backers. If you'd like to join them, please [read more here](https://docs.nestjs.com/support).

## Stay in touch

- Author - [Kamil Myśliwiec](https://twitter.com/kammysliwiec)
- Website - [https://nestjs.com](https://nestjs.com/)
- Twitter - [@nestframework](https://twitter.com/nestframework)

## License

Nest is [MIT licensed](https://github.com/nestjs/nest/blob/master/LICENSE).
