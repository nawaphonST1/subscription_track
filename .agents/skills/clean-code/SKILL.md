---
name: clean-code
description: Review, refactor, or clean up code and architecture across the full-stack repository (Flutter mobile frontend, NestJS backend, PostgreSQL/TypeORM, Redis, BullMQ workers, Docker, Nginx, CI/CD). Use for clean-code reviews, feature/module decomposition, Riverpod state cleanup, NestJS modular monolith boundaries, async job idempotency, dead-code removal, technical debt reduction, and maintainability improvements without altering observable behavior.
---

# 🧹 Repository-Wide Clean Code & Architecture Review

Improve code structure without trading correctness for aesthetics. Refactoring must preserve observable behavior unless the user explicitly requests behavioral changes.

---

## 1. Core Philosophy & Request Classification

Every interaction MUST strictly distinguish between two modes:

### Mode A: Review-Only Requests
- **Actions:** Inspect, identify concrete code evidence, explain architectural tradeoffs, and provide actionable recommendations.
- **Rule:** **DO NOT edit or modify files.**

### Mode B: Refactoring / Modification Requests
- **Actions:** Apply the smallest safe structural change that resolves the identified problem while preserving public behavior and contracts.
- **Rule:** Validate changes thoroughly and report exactly what was altered and why.

---

## 2. Step 1: Detect Scope & Classification

Before taking action, identify the specific domain being reviewed. **NEVER apply platform-specific rules to the wrong stack** (e.g., do not apply Riverpod rules to NestJS, or NestJS rules to Flutter).

| Scope Area | Target Technologies | Applicable Architecture Guidelines |
|---|---|---|
| **Frontend** | Flutter, Dart, Riverpod, GoRouter | [📱 Frontend Architecture](./frontend_architecture.md) |
| **Backend** | NestJS, TypeScript, PostgreSQL, TypeORM | [🖥️ Backend Architecture](./backend_architecture.md) |
| **Worker / Async** | BullMQ, Redis Queues, Background Tasks | [⚡ Async & Redis Rules](./async_and_redis.md) |
| **Infrastructure / DevOps** | Docker, Docker Compose, Nginx, CI/CD | [🏗️ Infrastructure Architecture](./infrastructure_architecture.md) |
| **Shared / Cross-Cutting** | API Contracts, DTOs, Security, Logging | Universal Principles below |
| **Repository-Wide** | Monolith boundaries, dead code, repo tree | Universal Principles & Domain Guides |

---

## 3. Universal 15-Point Responsibility Review Checklist

Evaluate any file, module, or component against this repository-wide checklist:

1. **Cohesive Reason to Change:** Does this file/module have a single, well-defined reason to change (SRP)?
2. **Domain-Revealing Naming:** Does the name describe domain intent rather than generic mechanics?
3. **Single Authoritative State:** Is state owned in exactly one authoritative place (Postgres for durable data, Riverpod/controller for UI)?
4. **Intentional Dependency Direction:** Do dependencies point inward toward contracts rather than concrete details?
5. **Isolated Testability:** Can core business logic be tested without spinning up heavy UI, network, or external infrastructure?
6. **Genuine vs. Coincidental Duplication:** Is repeated code truly the same business concept, or merely similar-looking code that evolves independently?
7. **Context-Preserving Error Handling:** Does error handling preserve context and provide an actionable recovery path?
8. **Informative Comments:** Do comments explain "why" (constraints and design decisions) rather than narrating syntax?
9. **No Dead Code:** Are dead code, obsolete configuration, or speculative abstractions eliminated?
10. **Stateless & Scalable:** Does the design remain correct when multiple backend API instances run concurrently?
11. **Durable Source of Truth:** Is durable business state stored in PostgreSQL rather than temporary caches like Redis?
12. **Idempotent Background Jobs:** Are async worker jobs safe to retry multiple times without causing duplicate side-effects?
13. **Server-Side Security Enforcement:** Are authentication, user ownership, and authorization strictly enforced on the server?
14. **Observable Failure Modes:** Are system failures, job errors, and unhandled exceptions observable via structured logs and health probes?
15. **Justified Abstraction (YAGNI):** Is every abstraction justified by current requirements rather than speculative future use?

---

## 4. The ~200-Line Review Signal & Naming Standards

- **200 lines is a review signal, NOT an automatic failure.**
  - **DO NOT** split a cohesive file merely to hit an arbitrary line count target.
  - **DO split** when a file mixes independent responsibilities, couples layout with network state, or impedes unit testing.
- **Eliminate Generic Junk Drawers:**
  - Reject vague names like `utils.ts`, `helpers.ts`, `common_service.ts`, `manager.dart`.
  - Name modules after the specific business responsibility they own (e.g., `SubscriptionBillingCalculator`, `PaymentCardLinkingController`).

---

## 5. Architectural Restraint (Anti-Overengineering Policy)

The clean-code skill actively defends the repository against unnecessary complexity:

- **NO Premature Microservices:** The backend is an intentional **Modular Monolith**. Do not break modules into microservices without an explicit deployment or scaling boundary.
- **NO Generic Repository Wrappers:** Do not wrap TypeORM or Riverpod with meaningless passthrough layers that provide zero abstraction value.
- **NO Event Buses for Direct Calls:** Do not use event emitters or message queues for immediate synchronous operations where normal method calls are clearer.
- **NO Redis as Primary Storage:** Do not use Redis where PostgreSQL with proper indexing is completely sufficient.
- **NO Speculative Patterns:** Require a concrete, demonstrable problem before introducing design patterns (Factory, Strategy, CQRS).

---

## 6. Execution Workflow (Safe Refactoring Protocol)

```text
1. Detect Scope (Frontend, Backend, Worker, Infrastructure)
   ↓
2. Read Applicable Architecture Reference File
   ↓
3. Establish Baseline Behavior (Inspect tests, routes, consumers)
   ↓
4. Identify Responsibility & Boundary Violations
   ↓
5. Confirm That Refactoring Is Truly Justified
   ↓
6. Apply the Smallest Safe Structural Change
   ↓
7. Run Scope-Appropriate Validation Suite
   ↓
8. Report Findings:
   - What structural changes were made
   - Why they were made (tradeoffs resolved)
   - Validation performed & remaining risks
```

---

## 7. Scope-Appropriate Validation Matrix

Run the smallest relevant validation suite first, broadening only when changes affect cross-cutting behavior:

| Scope | Validation Commands |
|---|---|
| **Frontend (Flutter)** | `dart format <file>` → `dart analyze` → `flutter test <path>` → `flutter test` |
| **Backend (NestJS)** | `npm run lint` → `npm run build` (`tsc --noEmit`) → `npm test` → `npm run test:e2e` |
| **Worker (BullMQ)** | TypeScript compilation → Worker unit/idempotency tests → Redis connection test |
| **Infrastructure (Docker/Nginx)** | `docker compose config` → `nginx -t` → Docker build verification → Health endpoint check |
| **Cross-Cutting** | Run both frontend analysis and backend test suites; inspect git diff for accidental changes |

Do not claim clean code solely because analysis passes. Always report the ownership decisions made, responsibilities separated, and verification steps performed.
