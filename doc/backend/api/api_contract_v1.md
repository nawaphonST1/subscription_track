# Subscription Track — API Contract / OpenAPI v1

> **Phase:** 0.4 — API Contract / OpenAPI v1
> **Status:** Public API contract baseline
> **ปรับปรุงล่าสุด:** 15 กันยายน 2026
> **Machine-readable contract:** `doc/backend/api/openapi_v1.yaml`

## 1. Purpose & Scope

เอกสารนี้กำหนด endpoint, request/response model, authentication, ownership และ business errors ของ public API v1 โดยแปลงมาตรฐานจาก `api_standards.md` เป็น contract ที่ Flutter และ NestJS implementation ใช้ร่วมกัน

```text
API Standards
    ↓
API Contract / OpenAPI v1  ← เอกสารนี้ + openapi_v1.yaml
    ↓
Backlog Alignment
    ↓
Backend Implementation
```

เอกสารนี้ไม่ใช่ Controller/DTO/TypeORM implementation และไม่รับรองว่า Backend ถูก scaffold แล้ว Markdown เป็นคำอธิบายเจตนา ส่วน YAML เป็น machine-readable contract; หากแก้ contract ต้องแก้ทั้งสองไฟล์ใน change เดียวกัน

## 2. Inputs & Authority

ใช้ลำดับ authority:

1. `doc/backend/api/api_standards.md`
2. `doc/backend/backend_architecture_v1.md`
3. `doc/backend/domain_model_v1.md`
4. `doc/backend/database/erd_v1.md`
5. current backlog/product requirements
6. Flutter behavior ในฐานะ UI evidence
7. legacy PRD เฉพาะ requirement ที่ไม่ถูก supersede

Contract นี้รักษา Modular Monolith, CurrentUser ownership, PostgreSQL durable truth, Subscription snapshot, PackageVersion origin, BillingSchedule stable anchor, durable Notification dedupe และ NotificationDelivery limitation ไม่มี Redis/BullMQ/database endpoint และไม่รับ legacy MongoDB, Firebase-centric, microservice, WebSocket-first หรือ real banking assumptions กลับมา

## 3. Contract Decisions

- Public business base path: `/api/v1`
- Operational health paths: `/health/live`, `/health/ready`
- OAuth v1: explicit Google/Apple identity-token exchange endpoints; Firebase ไม่ถูกบังคับ
- Business requestsใช้ application Bearer access token ไม่ใช้ provider tokenตรง
- Refresh tokenส่งใน JSON bodyเฉพาะ refresh/logout และถูก rotateเมื่อ refreshสำเร็จ
- Successใช้ `{ "data": ... }`; collectionเพิ่ม `pagination`
- User-owned resourceที่ไม่มีหรือไม่ใช่ของ CurrentUserคืน 404
- Moneyใช้ decimal string + currency; dates/timesตาม API Standards
- PIN step-up v1ใช้ short-lived opaque verification tokenจาก `/auth/pin-verifications` ส่งต่อด้วย `X-PIN-Verification` เมื่อ operation policyกำหนด
- Subscription writeรับ recurrence intent; Backendคำนวณ `nextBillingDate`
- ไม่มี direct Package referenceบน Subscription; public originคือ `originatingPackageVersionId`
- Notification APIไม่ expose dedupe key, BullMQ stateหรือ exact delivery status

## 4. Endpoint Inventory

เฉพาะ `REQUIRED` อยู่ใน `openapi_v1.yaml`

| Domain | Method | Path | Auth | Purpose | Status |
| --- | --- | --- | --- | --- | --- |
| Auth | POST | `/api/v1/auth/google` | Public | Exchange verified Google identity token | REQUIRED |
| Auth | POST | `/api/v1/auth/apple` | Public | Exchange verified Apple identity token | REQUIRED |
| Auth | POST | `/api/v1/auth/refresh` | Refresh token | Rotate session and tokens | REQUIRED |
| Auth | POST | `/api/v1/auth/logout` | Refresh token | Revoke one refresh session | REQUIRED |
| Auth/PIN | POST | `/api/v1/auth/pin-verifications` | Bearer | Create short-lived PIN step-up proof | REQUIRED |
| Users | GET | `/api/v1/users/me` | Bearer | Read CurrentUser profile/preferences | REQUIRED |
| Users | PATCH | `/api/v1/users/me` | Bearer | Update writable profile/preferences | REQUIRED |
| Users/PIN | PUT | `/api/v1/users/me/pin` | Bearer | Configure or change PIN | REQUIRED |
| Subscriptions | GET | `/api/v1/subscriptions` | Bearer | Cursor-paginated owned list | REQUIRED |
| Subscriptions | POST | `/api/v1/subscriptions` | Bearer + conditional PIN | Create custom/preset-origin tracker | REQUIRED |
| Subscriptions | GET | `/api/v1/subscriptions/{subscriptionId}` | Bearer | Read owned tracker | REQUIRED |
| Subscriptions | PATCH | `/api/v1/subscriptions/{subscriptionId}` | Bearer + conditional PIN | Update writable snapshot/schedule/settings | REQUIRED |
| Subscriptions | POST | `/api/v1/subscriptions/{subscriptionId}/cancellation` | Bearer + conditional PIN | Cancel now or schedule cancellation | REQUIRED |
| Subscriptions | DELETE | `/api/v1/subscriptions/{subscriptionId}/cancellation` | Bearer + conditional PIN | Revoke pending cancellation | REQUIRED |
| Packages | GET | `/api/v1/packages` | Bearer | Browse active preset catalog | REQUIRED |
| Packages | GET | `/api/v1/packages/{packageId}` | Bearer | Read catalog package/current version | REQUIRED |
| Dashboard | GET | `/api/v1/dashboard/summary` | Bearer | Read authoritative derived summary | REQUIRED |
| Notifications | GET | `/api/v1/notifications` | Bearer | Cursor-paginated inbox | REQUIRED |
| Notifications | POST | `/api/v1/notifications/{notificationId}/read` | Bearer | Mark one read idempotently | REQUIRED |
| Notifications | DELETE | `/api/v1/notifications/{notificationId}/read` | Bearer | Mark one unread idempotently | REQUIRED |
| Notifications | POST | `/api/v1/notifications/{notificationId}/dismiss` | Bearer | Dismiss one notification | REQUIRED |
| Notifications | POST | `/api/v1/notifications/read-all` | Bearer | Mark visible inbox notifications read | REQUIRED |
| Notifications | POST | `/api/v1/notifications/dismiss-all` | Bearer | Dismiss visible inbox notifications | REQUIRED |
| Devices | POST | `/api/v1/device-registrations` | Bearer | Idempotently register/transfer push token | REQUIRED |
| Devices | DELETE | `/api/v1/device-registrations/{deviceRegistrationId}` | Bearer | Revoke owned registration | REQUIRED |
| Health | GET | `/health/live` | Operational | Process liveness | REQUIRED |
| Health | GET | `/health/ready` | Operational | Dependency readiness | REQUIRED |
| Subscriptions | DELETE | `/api/v1/subscriptions/{subscriptionId}` | Bearer | Remove/archive tracker | DEFERRED — retention semantics unresolved |
| Savings | POST | `/api/v1/savings/simulations` | Bearer | Server-side simulation | DEFERRED — current client calculation is sufficient |
| Packages | POST/PATCH/DELETE | `/api/v1/packages...` | Admin | Catalog publishing | DEFERRED — admin role/workflow undefined |
| Auth | GET/DELETE | `/api/v1/auth/sessions...` | Bearer | Session management UI | DEFERRED — no current UI need |
| Notifications | POST | `/api/v1/notifications/test` | Internal | Test provider delivery | REJECTED from public v1 |
| Cards | Any | `/api/v1/cards...` | — | Real banking/card integration | DEFERRED / out of v1 |

## 5. Shared HTTP Contract

### 5.1 Headers

ทุก responseมี `X-Request-ID` Authenticated endpointsใช้ `Authorization: Bearer <access-token>` Operationsที่รองรับ network retryอาจกำหนด `Idempotency-Key`; v1กำหนดให้ `POST /subscriptions` ต้องใช้ headerนี้

`X-PIN-Verification` เป็น conditional header: เมื่อ Userมี PIN credentialและ policyของ operationต้อง step-up หากไม่มี/หมดอายุคืน 403 `PIN_VERIFICATION_REQUIRED` Tokenนี้เป็น opaque, user-bound, short-lived, operation-scope-bound และห้าม log

### 5.2 Common Errors

ทุก endpointอาจคืน:

- `400 MALFORMED_REQUEST`
- `422 VALIDATION_ERROR`
- `429 RATE_LIMITED`
- `500 INTERNAL_ERROR`
- `503 SERVICE_UNAVAILABLE`

Authenticated endpointsเพิ่ม `401 AUTHENTICATION_REQUIRED`, `TOKEN_INVALID` หรือ `TOKEN_EXPIRED` User-owned resource endpointsใช้ 404 concealment

### 5.3 Pagination

Collectionที่ paginateรับ `limit` (default 20, max 100), opaque `cursor` และ endpoint-specific filters/sort Response:

```json
{
  "data": [],
  "pagination": {
    "nextCursor": null,
    "hasMore": false
  }
}
```

## 6. Auth API

### 6.1 Provider Exchange

เลือก provider-specific endpoints แทน dynamic `/auth/{provider}` เพื่อให้ route allow-list, DTO, validation และ provider-specific evolutionชัด

Request ทั้ง Google/Apple:

```json
{
  "identityToken": "provider-issued-token",
  "clientLabel": "Nok's iPhone"
}
```

Backend verify tokenกับ provider, resolve `(provider, subject)`, create User/AuthIdentityเมื่อ first sign-in และสร้าง RefreshSession Response `200` สำหรับ returning user หรือ `201` สำหรับ first account creation:

```json
{
  "data": {
    "accessToken": "application-access-token",
    "refreshToken": "application-refresh-token",
    "tokenType": "Bearer",
    "accessTokenExpiresAt": "2026-09-15T08:30:00.000Z",
    "refreshTokenExpiresAt": "2026-10-15T08:15:00.000Z",
    "user": {}
  }
}
```

Provider tokensไม่ถูก persistเป็น business credential Errors: 401 `PROVIDER_ASSERTION_INVALID`; 409 `IDENTITY_LINK_CONFLICT`; 502 `IDENTITY_PROVIDER_UNAVAILABLE`

### 6.2 Refresh

`POST /auth/refresh` รับ `{ "refreshToken": "..." }`, rotate verifierใน sessionเดิมและคืน `AuthSessionResponse` ใหม่ Old tokenใช้ซ้ำไม่ได้ Suspected replay revoke sessionและคืน 401 `REFRESH_TOKEN_REUSED`

### 6.3 Logout

`POST /auth/logout` รับ refresh tokenและ revoke sessionเดียว คืน 204 การเรียกซ้ำด้วย tokenของ sessionที่ revokeแล้วถือว่าสำเร็จแบบ idempotentและคืน 204 เพื่อให้ client logout converge โดยไม่เปิดเผย session state

### 6.4 PIN Verification

`POST /auth/pin-verifications` รับ `{ "pin": "******", "purpose": "SUBSCRIPTION_WRITE" }` และคืน:

```json
{
  "data": {
    "verificationToken": "opaque-step-up-token",
    "expiresAt": "2026-09-15T08:20:00.000Z"
  }
}
```

Purposes v1: `SUBSCRIPTION_WRITE`, `SUBSCRIPTION_CANCEL`, `PIN_CHANGE` Proofใช้ได้เฉพาะ CurrentUser/purpose, อายุสั้น และการใช้ซ้ำ/ครั้งเดียวเป็น implementation security policyก่อน coding Errors: 403 `PIN_NOT_CONFIGURED`, `PIN_VERIFICATION_FAILED`, `PIN_LOCKED`

## 7. Users API

### 7.1 User Response

```json
{
  "id": "6d685b52-31af-4f70-a24a-22882af80e71",
  "displayName": "Nok",
  "email": "nok@example.com",
  "monthlyReference": { "amount": "35000.0000", "currency": "THB" },
  "defaultCurrency": "THB",
  "defaultTimezone": "Asia/Bangkok",
  "locale": "th-TH",
  "reminderDefaults": { "enabled": true, "daysBefore": 3 },
  "pinConfigured": true,
  "accountStatus": "ACTIVE",
  "createdAt": "2026-09-15T08:00:00.000Z",
  "updatedAt": "2026-09-15T08:00:00.000Z"
}
```

`pinConfigured` เป็น derived boolean; ไม่มี verifier `PATCH /users/me` รับเฉพาะ `displayName`, nullable `email`, nullable `monthlyReference`, `defaultCurrency`, `defaultTimezone`, `locale`, `reminderDefaults` อย่างน้อยหนึ่ง fieldต้องมี Missing = unchanged, nullใช้ clearเฉพาะ nullable fields

ชื่อ `monthlyReference` ตั้งใจ neutral เพราะ productยังไม่สรุป income vs budget

### 7.2 PIN Configuration

`PUT /users/me/pin` รับ `newPin` และ optional `currentPin`:

- ยังไม่มี credential: `currentPin` ต้องไม่จำเป็น
- มี credential: ต้องส่ง current PIN หรือ valid `X-PIN-Verification` purpose `PIN_CHANGE`
- PIN policy/lengthเป็น server configuration ไม่ hardcode 6 digitsใน schema; OpenAPIอธิบาย secret stringโดยไม่ expose pattern
- Success 204; errors 403 `PIN_VERIFICATION_FAILED`, `PIN_LOCKED`; 409 `CURRENT_PIN_REQUIRED`

## 8. Subscriptions API

### 8.1 Subscription Response

```json
{
  "id": "7cfdd495-87c0-4ed3-8a44-e19f217a7a76",
  "originatingPackageVersionId": null,
  "serviceName": "My Gym",
  "price": { "amount": "599.0000", "currency": "THB" },
  "categoryCode": "FITNESS",
  "iconKey": "fitness",
  "displayColorHex": "#16A34A",
  "billingSchedule": {
    "intervalCount": 1,
    "intervalUnit": "MONTH",
    "anchorMonth": 1,
    "anchorDay": 31,
    "timezone": "Asia/Bangkok",
    "nextBillingDate": "2026-09-30"
  },
  "reminder": {
    "mode": "INHERIT",
    "daysBefore": null,
    "effectiveEnabled": true,
    "effectiveDaysBefore": 3
  },
  "status": "ACTIVE",
  "cancellation": null,
  "usageLevel": "MODERATE",
  "createdAt": "2026-09-15T08:00:00.000Z",
  "updatedAt": "2026-09-15T08:00:00.000Z"
}
```

Snapshot fieldsเป็น authoritative tracked values PackageVersionเป็น origin contextเท่านั้น Responseไม่มี `packageId`; clientที่ต้องรู้ catalogอ่านผ่าน package resource/contextใน Phaseต่อไปโดยไม่เปลี่ยน snapshot

### 8.2 Create

`POST /subscriptions` ต้องมี `Idempotency-Key` และ body:

```json
{
  "originatingPackageVersionId": null,
  "serviceName": "My Gym",
  "price": { "amount": "599.0000", "currency": "THB" },
  "categoryCode": "FITNESS",
  "billingSchedule": {
    "intervalCount": 1,
    "intervalUnit": "MONTH",
    "anchorDay": 31,
    "initialBillingDate": "2026-09-30",
    "timezone": "Asia/Bangkok"
  },
  "reminder": { "mode": "INHERIT" },
  "usageLevel": "MODERATE"
}
```

Backend derives `anchorMonth` from `initialBillingDate`, validates optional explicit `anchorDay`, applies month-end policyและ persists next occurrence Snapshot requiredแม้มี origin Custom subscriptionใช้ origin `null` Errors: 404 `PACKAGE_VERSION_NOT_FOUND`; 409 `IDEMPOTENCY_KEY_REUSED`, `PACKAGE_VERSION_INACTIVE`; 403 PIN errorsตาม policy

### 8.3 List and Detail

List supports:

- `status` repeated values: `ACTIVE`, `CANCELLATION_SCHEDULED`, `CANCELLED`
- `usageLevel` repeated values: `FREQUENT`, `MODERATE`, `UNUSED`
- `q` service-name search
- `sort=createdAt`, `-createdAt`, `nextBillingDate`, `-nextBillingDate`, `serviceName`, `-serviceName`
- cursor/limit

Default sort `-createdAt` with `id` tie-breaker Empty list = 200 Details enforce CurrentUser and 404 concealment

### 8.4 Update

`PATCH /subscriptions/{subscriptionId}` accepts at least one of writable snapshot fields, nullable presentation/grouping fields, full `billingSchedule` replacement, reminder configuration or nullable `usageLevel`

`originatingPackageVersionId`, status, cancellation, timestamps, nextBillingDate และ effective reminder fieldsไม่ writableผ่าน generic PATCH Billing schedule write uses `initialBillingDate`; response returns server-owned `nextBillingDate`

### 8.5 Reminder Configuration

Write model is an unambiguous union:

```json
{ "mode": "INHERIT" }
{ "mode": "DISABLED" }
{ "mode": "ENABLED", "daysBefore": 3 }
```

`daysBefore` forbidden for INHERIT/DISABLED and required nonnegative for ENABLED

### 8.6 Cancellation

`POST /subscriptions/{subscriptionId}/cancellation` body:

```json
{ "mode": "SCHEDULED", "effectiveAt": "2026-10-01T00:00:00.000Z" }
```

or `{ "mode": "IMMEDIATE" }` Returns updated Subscription 200 `DELETE .../cancellation` revokes only pending scheduleและ returns updated Subscription 200 ไม่มี endpointใด hard-delete row Errors: 409 `INVALID_SUBSCRIPTION_STATE`, `CANCELLATION_TIME_INVALID`

## 9. Packages API

Catalogเป็น authenticated read-onlyใน v1 เพื่อคง public surfaceเล็กและสอดคล้อง app flow Package response:

```json
{
  "id": "f10e2dbc-7668-4b6c-ad02-1b83314bb2ac",
  "canonicalCode": "NETFLIX_BASIC",
  "isActive": true,
  "iconKey": "netflix",
  "defaultColorHex": "#E50914",
  "currentVersion": {
    "id": "fc72a897-f339-4b10-b514-c7464322b4db",
    "versionNumber": 3,
    "displayName": "Netflix Basic",
    "price": { "amount": "199.0000", "currency": "THB" },
    "billingInterval": { "count": 1, "unit": "MONTH" },
    "categoryCode": "ENTERTAINMENT",
    "effectiveFrom": "2026-06-01T00:00:00.000Z"
  }
}
```

List supports cursor/limit, `q`, `sort=canonicalCode|-canonicalCode` และคืน active/current effective catalogเท่านั้น Detailอาจคืน inactive packageเพื่อให้ existing origin/contextยังอธิบายได้ แต่ไม่ expose admin publishing operations

## 10. Dashboard API

`GET /dashboard/summary` คืน derived read model ไม่ใช่ table:

```json
{
  "data": {
    "monthlyTotals": [{ "amount": "1298.0000", "currency": "THB" }],
    "annualizedTotals": [{ "amount": "15576.0000", "currency": "THB" }],
    "activeSubscriptionCount": 4,
    "unusedSubscriptionCount": 1,
    "unusedMonthlySavingsTotals": [{ "amount": "199.0000", "currency": "THB" }],
    "creepScore": 3.71,
    "upcomingRenewals": []
  }
}
```

ยอดรวมเป็น arrayแยกตาม currency เพื่อไม่รวม THB/USDโดยไม่มี FX model; initial Thai-only dataจึงมีหนึ่งรายการ `creepScore` nullableเมื่อ monthlyReferenceไม่มี หรือไม่มี totalสกุลเดียวกันที่เปรียบเทียบได้ Upcoming renewalใช้ subscription snapshotและ calendar date Redis Cache-Asideไม่เปลี่ยน contract

## 11. Notifications API

Notification responseมี `id`, `type`, `title`, `body`, nullable context IDs, `readAt`, `dismissedAt`, `createdAt` ไม่มี dedupe key, job ID, provider receipt, attempt countหรือ aggregate dispatch status

List supports `state=ALL|UNREAD|READ`, repeated `type`, cursor/limit และ fixed sort `-createdAt` Dismissed itemsถูก excludeโดย default; `includeDismissed=true` ใช้เมื่อ contractต้องแสดง history

Read/unread/dismiss actionsเป็น idempotentและคืน updated Notification 200 Bulk actionsรับ optional current filtersและคืน:

```json
{ "data": { "updatedCount": 4 } }
```

Durable Notification occurrence/dedupeรองรับ แต่ provider/device dispatchยัง at-least-once/best-effort ไม่มี durable per-device/per-channel delivery audit

## 12. Device Registration API

`POST /device-registrations` รับ:

```json
{ "pushToken": "provider-token", "platform": "IOS" }
```

Same User + same active tokenคืน existing resource `200`; new/transferสำเร็จคืน `201` Ownership transfer revoke active ownerเก่าและ activate CurrentUserอย่าง transactionally protected Responseไม่คืน raw push token:

```json
{
  "data": {
    "id": "ab3c7faa-36db-4700-ab6f-b37833f95b43",
    "platform": "IOS",
    "status": "ACTIVE",
    "createdAt": "2026-09-15T08:00:00.000Z",
    "updatedAt": "2026-09-15T08:00:00.000Z"
  }
}
```

`DELETE /device-registrations/{id}` revoke owned registrationและคืน 204; unknown/not-ownedคืน 404 Raw tokenเป็น write-only sensitive operational valueและต้อง redactจาก logs

## 13. Health API

- `GET /health/live`: 200 `{ "data": { "status": "UP" } }` เมื่อ processตอบสนอง
- `GET /health/ready`: 200 `READY`; 503 `NOT_READY` เมื่อ required dependenciesไม่พร้อม

Schemaไม่เผย dependency names, hostsหรือ errors Exposureของ readinessถูกจำกัดที่ Nginx/network policyภายหลัง OpenAPIบันทึก contractแต่ไม่ทำให้ routeต้อง public Internet

## 14. Public Models and Field Ownership

| Model/field | Write | Read | Notes |
| --- | ---: | ---: | --- |
| User `id`, status, timestamps, `pinConfigured` | No | Yes | Server-owned/derived |
| User profile/preferences | PATCH allow-list | Yes | No provider subject |
| PIN / refresh/provider assertions | Write-only | No | Never logged/returned |
| Subscription `originatingPackageVersionId` | Create only | Yes | Immutable precise origin |
| Subscription snapshot | Create/PATCH | Yes | Authoritative tracked meaning |
| Billing input `initialBillingDate` | Create/PATCH | No | Command intent |
| Billing `anchorMonth`, `nextBillingDate` | No | Yes | Server-calculated/persisted |
| Subscription status/cancellation | Action endpoints | Yes | Not arbitrary PATCH |
| Notification content/context | No public write | Yes | Worker/application-owned |
| Notification read/dismiss state | Action endpoints | Yes | Durable user state |
| Notification dedupe/provider state | No | No | Internal |
| Device `pushToken` | Registration write-only | No | Sensitive destination |

## 15. Error Catalog

| Code | Status | Applies to |
| --- | ---: | --- |
| `MALFORMED_REQUEST` | 400 | Invalid JSON/protocol |
| `AUTHENTICATION_REQUIRED`, `TOKEN_INVALID`, `TOKEN_EXPIRED` | 401 | Bearer auth |
| `PROVIDER_ASSERTION_INVALID`, `REFRESH_TOKEN_INVALID`, `REFRESH_TOKEN_REUSED` | 401 | Auth flows |
| `FORBIDDEN`, `PIN_VERIFICATION_REQUIRED`, `PIN_VERIFICATION_FAILED`, `PIN_LOCKED` | 403 | Policy/PIN |
| `<RESOURCE>_NOT_FOUND` | 404 | Missing/concealed owned resource |
| `INVALID_SUBSCRIPTION_STATE`, `CANCELLATION_TIME_INVALID`, `IDENTITY_LINK_CONFLICT`, `CURRENT_PIN_REQUIRED`, `IDEMPOTENCY_KEY_REUSED` | 409 | Current-state conflict |
| `VALIDATION_ERROR`, `INVALID_CURSOR` | 422 | Parsed input invalid |
| `RATE_LIMITED` | 429 | Rate/attempt limit |
| `IDENTITY_PROVIDER_UNAVAILABLE` | 502 | Synchronous provider failure |
| `SERVICE_UNAVAILABLE` | 503 | Required capability unavailable |
| `INTERNAL_ERROR` | 500 | Unexpected failure |

Exact endpoint response mappingsอยู่ใน OpenAPI Operation ที่เกี่ยวข้อง Error messageไม่ใช่ branching contract

## 16. Idempotency and Async Boundary

- `POST /subscriptions` requires `Idempotency-Key` เพราะ network retryอาจสร้าง durable duplicate
- device registration convergeด้วย active-token uniqueness จึงไม่ require header
- read/unread/dismiss/bulk action และ logoutถูกนิยามให้ idempotentโดย desired state
- cancellation same requested stateอาจคืน current representation; conflicting different stateคืน 409
- HTTP key scope = CurrentUser + method + route + key; same key/different payload = 409
- Exact durable HTTP-key storage/retentionยังเป็น implementation decisionก่อนสร้าง endpoint
- BullMQ retryใช้ durable Notification dedupeแยกจาก HTTP key
- ไม่มี endpointคืน BullMQ job ID และไม่มี operation resourceใน v1

Primary mutationsใน contractนี้จบ synchronously จึงใช้ 200/201/204 Follow-up notification enqueueไม่เปลี่ยน responseเป็น 202 และ responseไม่กล่าวว่า providerส่งสำเร็จแล้ว

## 17. OpenAPI Consistency Rules

`openapi_v1.yaml` ต้อง:

- มี operationId unique และ tags `Auth`, `Users`, `Subscriptions`, `Packages`, `Dashboard`, `Notifications`, `Device Registrations`, `Health`
- ระบุ Bearer securityทุก protected operationและ override `security: []` สำหรับ auth exchange/refresh/logout/health
- ใช้ reusable Money, error, pagination และ response schemasเฉพาะเมื่อความหมายเหมือนกันจริง
- mark secret inputs `writeOnly`; server fields `readOnly`
- ระบุ required/nullableต่างกันชัด
- ไม่ expose database snake_case, internal dedupe, raw push token responseหรือ queue identifiers
- ใช้ synthetic examplesเท่านั้น

## 18. Deferred and Open Decisions

| Decision | v1 contract position | Resolve by |
| --- | --- | --- |
| Durable Guest mode | Not in API; guest remains local/demo | Auth product decision before persistent guest work |
| Subscription remove/archive | No DELETE tracker endpoint | Backlog alignment/domain migration before endpoint addition |
| Provider implementation internals | Identity-token exchange contract fixed; verification library/provider SDK open | Phase 3 implementation |
| Refresh transport | JSON body selected for native Flutter v1; browser cookie strategy may require additive/new flow | Auth implementation/web deployment |
| PIN proof storage/single-use policy | Opaque purpose-bound contract fixed; storage/consumption open | Security design before protected endpoints |
| HTTP idempotency persistence/retention | Header semantics fixed | Backend foundation before subscription create |
| Notification retention | Dismiss retained; purge horizon absent | Before Phase 7 cleanup |
| NotificationDelivery | No target audit; best-effort/at-least-once | Before Phase 7 if stronger guarantee required |
| UsageLevel vocabulary | v1 three values; additions require coordinated contract change | Product/backlog alignment |
| Income vs budget naming | Neutral `monthlyReference` | Product decision before final UI copy |
| Realtime | REST polling/read remains v1 | Revisit only with measured realtime requirement |
| Admin package publishing | No public admin contract | Separate admin/security design |

## 19. Contract Scenario Review

| Scenario | Contract result |
| --- | --- |
| Google/Apple sign-in retry | Provider identity uniqueness resolves same User; new session resultตาม auth policy |
| Custom Subscription | `originatingPackageVersionId: null`; required snapshot/schedule |
| Preset origin price differs | origin retained; request snapshot remains authoritative |
| Package v4 published | existing Subscription responseไม่เปลี่ยนอัตโนมัติ |
| Anchor 31 / short month | input intent retained; server response occurrence may be Feb 28 then Mar 31 |
| Annual Feb 29 | anchor persists; non-leap occurrence Feb 28; leap year returns Feb 29 |
| Scheduler/job retry | one durable Notification occurrence; provider dispatch may duplicate |
| Two devices | two active registrations allowed |
| Same token changes User | transaction transfers active ownership; only one active owner |
| One session logout | supplied RefreshSession revoked; other sessions unaffected |
| Cancellation | lifecycle action; no physical DELETE |
| Cross-user ID | 404 concealment |

## 20. Clean-Code Review Record

ตรวจตาม `$clean-code` แล้ว:

1. Endpointทุกตัวมี current product/use-case owner; ไม่มี CRUDตาม tableโดยอัตโนมัติ
2. AuthIdentity, RefreshSession และ PinCredentialไม่ถูก exposeเป็น generic resources
3. CurrentUserกำหนด owner; requestไม่มี writable `userId`
4. Subscription snapshotและ PackageVersion originไม่ปะปน; ไม่มี direct Package origin field
5. BillingSchedule writeเป็น intentและ next occurrenceเป็น server-owned
6. Cancellationใช้ action endpoint ไม่ใช้ DELETE tracker
7. Dashboardเป็น read model; Savings selection/UI stateไม่กลายเป็น API entity
8. Notification stateแยกจาก BullMQ/provider deliveryและไม่ over-promise target audit
9. Device registration idempotencyอาศัย business uniqueness ไม่สร้าง public queue mechanism
10. Money/date/timezone/nullabilityสอดคล้อง API Standards/ERD
11. Sensitive valuesเป็น write-onlyและไม่มี raw credential/tokenใน ordinary response
12. Deferred routesไม่ถูกใส่ OpenAPI v1

ประเด็นที่แก้ระหว่าง review: ใช้ provider-specific auth routes, ไม่สร้าง session CRUD/savings/job endpoint/package admin API, ไม่เพิ่ม physical subscription deletionก่อน retention semanticsพร้อม และเปลี่ยน Dashboard totalsเป็นกลุ่มตาม currencyเพื่อไม่สร้าง implicit FX behavior

## 21. Non-Goals

เอกสารนี้ไม่ implement Controller, DTO class, Guard, TypeORM Entity, migration, SQL, OAuth/JWT/PIN cryptography, Redis key, BullMQ job, FCM, Nginx, Docker, Swagger decorator, CI/CD หรือ frontend integration และไม่กำหนด real banking/card API

## 22. Readiness and Next Step

```text
READY FOR BACKLOG ALIGNMENT
```

Markdown และ OpenAPIกำหนด endpoint surface, request/response, auth/ownership, field ownershipและ error behaviorครบพอสำหรับ **Phase 0.5 — Backlog Alignment** งานนี้ยังไม่เริ่ม NestJS implementation
