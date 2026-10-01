# ⚙️ Environment Variables & Configuration Guideline

**Module**: Subscription Track Backend (`apps/server`)  
**Architecture**: NestJS Modular Monolith + BullMQ Worker  
**Last Updated**: October 2026  

---

## 1. Overview & Core Philosophy

This document outlines the canonical environment variable schema, security policies, and validation mechanics for the **Subscription Track** backend services.

### Guiding Principles:
1. **Zero Secrets in VCS (Shift-Left Security)**: Never commit real credentials, passwords, or cryptographic keys to Git. Use [`.env.example`](file:///c:/Users/Devasipason/Desktop/subject/moblie%20app/subscription_track/.env.example) solely for structure and safe defaults.
2. **Fail-Fast Startup Validation**: The application strictly validates its configuration using **Zod** during the bootstrapping phase before any HTTP listeners or database connections open. If any required variable is missing or malformed, the process halts immediately.
3. **No Credential Leaks in Error Traces**: Error messages highlight missing keys or formatting failures without printing actual secret values to standard error or logging buffers.

---

## 2. Canonical Environment Schema Reference

| Variable | Type | Default | Required? | Allowed Values / Constraints | Description |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`NODE_ENV`** | String | `development` | No | `development`, `test`, `production` | Defines runtime execution environment. |
| **`APP_HOST`** | String | `0.0.0.0` | No | Valid IPv4/IPv6 address or hostname | Network interface binding. |
| **`PORT`** | Integer | `8080` (3000 on host) | No | `1` to `65535` | HTTP port the NestJS API listens on. |
| **`DB_HOST`** | String | — | **Yes** | Hostname or IP (`localhost`, `postgres`) | Hostname of the PostgreSQL instance. |
| **`DB_PORT`** | Integer | `5432` | No | `1` to `65535` | Port for the PostgreSQL service. |
| **`DB_NAME`** | String | — | **Yes** | Non-empty string | Target PostgreSQL database name (`subtracker_db`). |
| **`DB_USER`** | String | — | **Yes** | Non-empty string | Database username. |
| **`DB_PASSWORD`**| String | — | **Yes** | Non-empty string | Database user password. |
| **`DATABASE_URL`**| String | Auto-derived | No | Valid PostgreSQL connection URI | Optional full connection string. |
| **`REDIS_HOST`**| String | `localhost` | No | Hostname or IP (`localhost`, `redis`) | Redis instance hostname for caching & BullMQ. |
| **`REDIS_PORT`**| Integer | `6379` | No | `1` to `65535` | Redis server port. |
| **`REDIS_PASSWORD`**| String | `""` | No | Optional string | Redis authentication password. |
| **`PUSH_PROVIDER`**| String | `stub` | No | `stub`, `fcm` | Notification push provider for background worker. |
| **`JWT_SECRET`** | String | — | **Yes** | $\ge 32$ characters, no whitespace | Cryptographic secret for signing JWT tokens. |
| **`AGENT_RULES_FILE`** | String | `agent.md` | No | File path | AI Agent governance rules file reference. |

---

## 3. Cryptographic Security & Secret Generation

### JWT Secret Entropy Floor
- The `JWT_SECRET` is validated to be at least 32 characters in length with no leading or trailing whitespace.
- Generate via:
```bash
openssl rand -base64 32
```
