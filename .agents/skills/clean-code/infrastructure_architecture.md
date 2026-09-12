# 🏗️ Infrastructure & DevOps Clean Architecture (Docker, Nginx & CI/CD)

This reference document defines standards for containerization, networking, proxying, continuous integration, and observability in `subscription_track`.

---

## 1. Dockerfile Clean Code Rules

Production Dockerfiles must be efficient, reproducible, and secure.

1. **Multi-Stage Builds:**
   - Separate build-time dependencies (compilers, devDependencies) from runtime:
     ```dockerfile
     # Stage 1: Build
     FROM node:20-alpine AS builder
     WORKDIR /app
     COPY package*.json ./
     RUN npm ci
     COPY . .
     RUN npm run build

     # Stage 2: Production Runtime
     FROM node:20-alpine AS runner
     WORKDIR /app
     COPY package*.json ./
     RUN npm ci --only=production
     COPY --from=builder /app/dist ./dist
     USER node
     CMD ["node", "dist/main.js"]
     ```
2. **Layer Caching:**
   - Copy dependency manifests (`package.json`, `package-lock.json`) before application code to leverage Docker layer cache.
3. **Least Privilege (Non-Root User):**
   - Run production containers under a non-root user (e.g., `USER node`).
4. **No Secrets in Images:**
   - NEVER bake `.env`, credentials, JWT secrets, or database passwords into Docker images or build arguments.
5. **Strict `.dockerignore`:**
   - Ensure `.dockerignore` excludes `node_modules`, `.git`, `.env*`, `dist`, `coverage`, and temporary log files.

---

## 2. Docker Compose Standards

Compose files orchestrate multi-container local and production stacks.

```text
[Internet / Client] ──> [Nginx (Ports 80/443)]
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
       [API Instance 1]               [API Instance 2]
              │                               │
              └───────────────┬───────────────┘
                              ▼
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
  [PostgreSQL]             [Redis]            [BullMQ Worker]
  (Volume: pg_data)   (Volume: redis_data)    (Shared Monolith)
```

### Compose Review Rules:
1. **Network Isolation & Minimal Port Exposure:**
   - Only expose Nginx ports (`80`, `443`) to the host machine.
   - Internal dependencies (`postgres`, `redis`, `api`) must communicate exclusively over internal Docker networks (e.g., `backend_net`) without exposing host ports.
2. **Persistent Volumes for Stateful Services:**
   - Named volumes MUST be declared for `postgres` (`postgres_data:/var/lib/postgresql/data`) and `redis` (`redis_data:/data`).
3. **Health Checks & Deep Dependency Readiness:**
   - Do NOT rely solely on `depends_on: [postgres]` (this only verifies container start, not DB readiness).
   - Use health checks with `service_healthy`:
     ```yaml
     postgres:
       image: postgres:16-alpine
       healthcheck:
         test: ["CMD-SHELL", "pg_isready -U $$POSTGRES_USER -d $$POSTGRES_DB"]
         interval: 5s
         timeout: 5s
         retries: 5

     api:
       depends_on:
         postgres:
           condition: service_healthy
         redis:
           condition: service_healthy
     ```

---

## 3. Nginx Reverse Proxy & Networking

Nginx acts as the single public gateway and reverse proxy.

1. **Upstream Load Balancing:**
   - Define upstream blocks to round-robin requests across stateless backend instances:
     ```nginx
     upstream backend_api {
         server api:3000 max_fails=3 fail_timeout=10s;
     }
     ```
2. **Client IP & Header Forwarding:**
   - Preserve client IP and protocols:
     ```nginx
     proxy_set_header Host $host;
     proxy_set_header X-Real-IP $remote_addr;
     proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
     proxy_set_header X-Forwarded-Proto $scheme;
     ```
3. **Request Correlation Tracking:**
   - Generate or forward `X-Request-ID` across Nginx and NestJS application logs for request tracing.
4. **Timeouts & Security:**
   - Explicit `proxy_connect_timeout` and `proxy_read_timeout`.
   - Terminate SSL/TLS at Nginx; internal communication stays inside Docker network.
   - Do NOT configure sticky sessions for stateless backend APIs.

---

## 4. Observability: Logging & Health Checks

### Structured Logging:
- Logs must be structured JSON in production:
  - Required fields: `timestamp`, `level`, `context`/`service`, `traceId`/`requestId`, `message`.
- **Absolute Sanitization:**
  - NEVER log authorization headers, passwords, PINs, card CVVs, or refresh tokens.

### Health Probes (Liveness vs. Readiness):
- **Liveness Probe (`GET /health/live`):**
  - Answers: *"Is the process responsive?"*
  - Fast, in-memory check. Fails only if the process is completely hung or deadlocked.
- **Readiness Probe (`GET /health/ready`):**
  - Answers: *"Can this instance safely handle customer requests?"*
  - Verifies database connectivity (PostgreSQL ping) and Redis ping. If PostgreSQL is down, returns 503 so traffic stops routing to this instance.

---

## 5. CI/CD Pipeline Protocol

CI validation must pass sequentially before artifacts are deployed:

```text
1. Install Dependencies (Deterministic: npm ci / pub get)
   ↓
2. Linter & Static Analysis (eslint / dart analyze)
   ↓
3. Type-Checking & Build (tsc --noEmit / flutter build bundle)
   ↓
4. Automated Unit & Widget Tests (jest / flutter test)
   ↓
5. Integration Tests with Test Containers (Postgres/Redis)
   ↓
6. Security / Dependency Audit (npm audit)
   ↓
7. Docker Build & Smoke Verification
   ↓
8. Deployment & Database Migration Execution
```

- **Secret Safety:** Pass secrets through environment variables / GitHub Actions Secrets. NEVER commit secrets into workflow `.yaml` files.
- **Migration Execution:** Run database migrations before starting new application containers to ensure schema readiness.
