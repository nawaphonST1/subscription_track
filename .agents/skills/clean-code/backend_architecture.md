# 🖥️ Backend Architecture Rules (NestJS, TypeScript & PostgreSQL)

This reference document defines Clean Code and Architecture standards for the backend services in `apps/api/`.

---

## 1. Modular Monolith Architecture

The backend is architected as a **Modular Monolith** using NestJS and TypeScript located in `apps/api/`. It is NOT an arbitrary set of microservices; all modules reside in a unified codebase with clear module boundaries.

```text
apps/api/src/
├── modules/
│   ├── auth/            # Authentication, JWT strategy, refresh token rotation
│   ├── users/           # User identity, profile, security settings
│   ├── subscriptions/   # Subscription tracking, billing cycle calculation, categories
│   ├── packages/        # Preset catalog and package comparisons
│   └── notifications/   # Reminder scheduling and push dispatching
├── common/              # Cross-cutting filters, guards, interceptors, pipes, decorators
├── infrastructure/      # Database (TypeORM), Cache (Redis), Queue (BullMQ) module configurations
└── main.ts              # Application bootstrap, validation pipes, global filters
```

---

## 2. Layer Responsibilities & Strict Boundaries

```text
[HTTP Request] ──> [Controller] ──(DTO)──> [Service / Use Case] ──> [Repository / TypeORM] ──> [PostgreSQL]
```

### Controllers (Thin HTTP Adapters)
- **Do:**
  - Define REST endpoints with standard HTTP verbs and status codes.
  - Bind and validate incoming request payloads using explicit DTOs.
  - Extract authenticated user context via custom decorators (e.g. `@CurrentUser()`).
  - Delegate execution immediately to service methods and return mapped responses.
- **Do NOT:**
  - Contain SQL queries or TypeORM `QueryBuilder` calls.
  - Contain Redis cache lookups or key formatting.
  - Orchestrate BullMQ queues directly.
  - Execute business calculations or domain validation.

### Services (Application & Domain Logic)
- Implement use cases, orchestration, and business invariants.
- Coordinate between repositories, cache managers, and event/queue producers.
- Define transaction boundaries for operations modifying multiple entities.
- Avoid "God Services": split services when a class mixes disparate concerns (e.g., separate `SubscriptionQueryService` from `SubscriptionBillingService` if complexity grows).

### DTOs & Validation
- Every incoming endpoint payload MUST have a dedicated Request DTO.
- Use `class-validator` decorators (`@IsString()`, `@IsNumber()`, `@IsEnum()`, `@IsOptional()`, etc.) and `class-transformer`.
- Global `ValidationPipe` MUST be enabled with `{ whitelist: true, forbidNonWhitelisted: true, transform: true }`.
- NEVER return TypeORM entity instances directly to the client; map them through Response DTOs or serializers to prevent leaking internal columns or password/PIN hashes.

---

## 3. Database & TypeORM Guidelines (PostgreSQL as Source of Truth)

PostgreSQL is the **durable, single source of truth** for all business data.

1. **Schema & Migrations:**
   - Production setting: `synchronize: false` MUST always be enforced.
   - All schema changes must be versioned, tested TypeORM migration files (`src/migrations/`).
2. **Database Constraints over App-Only Checks:**
   - Enforce business-critical invariants in the database schema:
     - `UNIQUE` constraints (e.g. `(userId, serviceKey)` to prevent duplicate subscriptions).
     - `FOREIGN KEY` constraints with explicit `ON DELETE` behaviors (`CASCADE`, `RESTRICT`, or `SET NULL`).
     - `CHECK` constraints (e.g. `price >= 0`).
   - Application-level validation is for user feedback; database constraints are for data integrity.
3. **Indexes:**
   - Add explicit indexes for foreign keys, user tenant lookups, and query filters (e.g. `[userId, nextBillingDate]`).
   - Avoid indexing low-cardinality boolean columns unless part of a compound index.
4. **Transactions & Concurrency:**
   - Wrap multi-table state mutations inside database transactions using `DataSource.transaction()` or `QueryRunner`.
   - For concurrency-sensitive workflows (e.g., billing deduction, duplicate import lock):
     - Use database atomic queries (e.g., `UPDATE ... SET balance = balance - :amount WHERE id = :id AND balance >= :amount`).
     - Use pessimistic locking (`SELECT ... FOR UPDATE`) within a transaction when reading before updating.
     - Do NOT introduce locks automatically without a concrete race condition or invariant to protect.

---

## 4. API Security, Authentication & Authorization

```text
Authentication:  "Who are you?"                         (JwtAuthGuard)
Authorization:   "Can you access THIS specific record?"  (Ownership Guard / Tenant Scope)
```

1. **Ownership Authorization:**
   - An authenticated token (`req.user`) gives access only to resources the user owns.
   - All user-specific database queries MUST filter by `userId`:
     ```typescript
     // Correct
     this.subRepo.findOne({ where: { id, userId: currentUser.id } });
     ```
   - NEVER accept `userId` from client request body/params for authorization without validating against `currentUser.id`.
2. **Credential Sanitization:**
   - Passwords, JWT secrets, refresh tokens, PIN hashes, and OAuth secrets MUST NEVER be logged or exposed in stack traces.
   - Exclude sensitive fields in TypeORM entities (`@Column({ select: false })`).

---

## 5. Statelessness & Horizontal Scaling

Backend API instances MUST remain completely stateless to allow horizontal scaling (multiple container replicas behind Nginx):

- **NO in-memory mutable state:** Do not store sessions, user tokens, or state in module-scoped JavaScript variables or process memory (`global`, static properties).
- **NO local filesystem storage for business data:** Use object storage (S3/GCP Cloud Storage) or database for user uploads.
- **Shared Coordination:** Use Redis for distributed caching, ephemeral coordination, or rate limiting across replicas.

---

## 6. Backend Validation Suite

Run validation in proportion to changes made:
1. Lint & Format: `npm run lint` / `prettier --check`
2. Type-checking & Build: `npm run build` (`tsc --noEmit`)
3. Unit tests: `npm test` (service logic, DTO validation)
4. Integration / E2E tests: `npm run test:e2e` (database interactions, controller endpoints)
