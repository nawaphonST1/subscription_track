# Subscription Track — API Standards v1

> **Phase:** 0.3 — API Standards
>
> **Status:** Canonical REST behavior baseline สำหรับ API Contract / OpenAPI v1
>
> **ปรับปรุงล่าสุด:** 14 กันยายน 2026
>
> **ขอบเขต:** วิธีที่ทุก public/operational HTTP API สื่อสาร ไม่ใช่รายการ endpoint

## 1. Purpose & Scope

เอกสารนี้กำหนด convention ร่วมของ Subscription Track REST API ได้แก่ URL, HTTP semantics, JSON shape, status/error, validation, authentication/authorization, pagination, Money/time, idempotency, async boundary, request ID และ OpenAPI rules

```text
Backend Architecture v1             ✅
        ↓
Domain Model v1                     ✅
        ↓
Physical / Relational ERD v1        ✅
        ↓
API Standards                       ← เอกสารนี้
        ↓
API Contract / OpenAPI v1
```

เอกสารนี้ตอบว่า **“ทุก endpoint ต้องทำงานและสื่อสารอย่างไร”** Phase 0.4 จึงค่อยตอบว่า endpoint ใดมีอยู่ รับ/คืน field ใด และเกิด feature-specific error ใดบ้าง ปัจจุบัน Backend ยังไม่ได้ scaffold

## 2. Sources & Locked Decisions

Authority order:

1. `doc/backend/backend_architecture_v1.md`
2. `doc/backend/domain_model_v1.md`
3. `doc/backend/database/erd_v1.md`
4. current product behavior/backlog
5. Flutter implementationในฐานะ presentation/read-model evidence
6. legacy PRD เฉพาะ requirement ที่ไม่ถูก supersede

Standards นี้รักษา:

- NestJS Modular Monolith; `main.ts` เป็น public HTTP runtime และ `worker.ts` ไม่มี public business HTTP API
- Nginx เป็น edge; API statelessและไม่ต้อง session affinity
- PostgreSQLเป็น durable Source of Truth; Redis/cacheโปร่งใสต่อ contract; BullMQเป็น internal execution state
- public namespace `/api/v1`
- User ownershipมาจาก authenticated CurrentUser ไม่มาจาก request body
- Subscription snapshotไม่ถูกแทนด้วย latest PackageVersion; catalog originเป็น contextผ่าน PackageVersion
- BillingScheduleแยก stable recurrence intentจาก server-calculated next occurrence
- Notificationเป็น durable application state; provider delivery auditไม่ได้รับประกันใน v1
- PIN/refresh verifier/push tokenและ ORM internalsไม่รั่วผ่าน DTO/error/log

MongoDB/Firebase-centric persistence, microservices, GCP assumptions, WebSocket-first และ real banking integrationไม่ใช่ฐานของ API v1

## 3. API Design Principles

- REST-first, resource-oriented และใช้ standard HTTP semantics
- resource URL ใช้ nouns; HTTP method บอก operation
- ใช้ explicit business actionเมื่อ CRUD/status mutationสื่อ intentไม่พอ
- response/error shapeสม่ำเสมอเพื่อให้ Flutter parsingตรงไปตรงมา
- authenticationและ ownershipบังคับที่ serverทุกครั้ง; hidden UIไม่ใช่ authorization
- write DTO allow-listเฉพาะ client-writable fields ป้องกัน mass assignment
- decimal/date/time semanticsต้องไม่เสียความหมายระหว่าง PostgreSQL, TypeScript และ Dart
- dangerous retryable writeต้องมี naturalหรือ explicit idempotency
- asynchronous infrastructureไม่รั่วเป็น public queue contract
- ไม่เพิ่ม GraphQL, gRPC, JSON:API, HAL/HATEOAS, CQRS API หรือ generic filter languageใน v1
- SSE/WebSocketเป็น future optionเมื่อ realtime requirementชัด ไม่ใช่ default

## 4. Base URL & Versioning

Public business API ใช้ path versioning:

```text
/api/v1
```

ตัวอย่างเชิงรูปแบบ:

```text
GET /api/v1/<resources>
```

ไม่กำหนด host/domainในเอกสารนี้ Path versioningถูกตั้งก่อน implementationเพื่อให้ mobile/backend contractคงที่, รองรับ controlled breaking changesและ deprecationได้ชัด Header/media-type versioningไม่ใช้ใน v1

Operational health routesเป็น exceptionและแนะนำให้อยู่นอก business namespaceตาม section 26

## 5. Resource, Path and Query Naming

### 5.1 Resource Paths

- plural lowercase nouns
- ใช้ kebab-caseเมื่อหลายคำหลีกเลี่ยงไม่ได้
- ใช้ domain terminology ไม่ใช่ database tableหรือ controller name

```text
/subscriptions
/packages
/notifications
/device-registrations
```

ห้ามใช้:

```text
/getSubscriptions
/createSubscription
/subscriptionList
/get_subscription
```

### 5.2 Path Parameters

ใช้ domain-specific camelCase namesในเอกสาร/route template:

```text
/<resources>/:resourceId
/subscriptions/:subscriptionId
```

ID เป็น opaque UUID string Clientห้าม inferเวลา, orderingหรือ business meaningจาก ID

### 5.3 Query Parameters

ใช้ camelCaseเหมือน JSON:

```text
?limit=20
?cursor=<opaque>
?status=ACTIVE
?sort=-createdAt
```

Database `next_billing_date` mapเป็น public `nextBillingDate`; ORM snake_caseห้ามรั่วผ่าน serialization

### 5.4 Nested Resources

ใช้ nestingเฉพาะ child identityผูกกับ parentอย่างมีความหมายและไม่ลึกเกินหนึ่งระดับโดยทั่วไป Ordinary self-service routeไม่ใส่ `users/:userId` เพราะ ownerมาจาก CurrentUser หลีกเลี่ยง pathลึกแบบ:

```text
/users/:userId/subscriptions/:subscriptionId/notifications/:notificationId
```

## 6. HTTP Method Semantics

| Method | v1 semantics |
| --- | --- |
| `GET` | Safe/read-only; ห้าม mutate durable stateหรือ trigger business side effectที่ clientสังเกตได้ |
| `POST` | Create resource, explicit non-CRUD business command หรือ initiate async work |
| `PATCH` | Partial update; missing fieldไม่เปลี่ยน, explicit `null` clearเฉพาะ fieldที่ contractอนุญาต |
| `PUT` | ไม่ใช้โดย default; ใช้เมื่อ full replacementมี semanticsจริงและ Phase 0.4ระบุ |
| `DELETE` | ใช้เฉพาะ true removal/deletion semantics ไม่ใช้แทน lifecycle transition |

GET อาจ update non-business operational metrics/cacheโดยไม่เปลี่ยน resource semantics แต่ห้าม mark read, create reminderหรือแก้ durable user stateโดยแอบแฝง

## 7. Business Actions and Cancellation

เมื่อ CRUDไม่สื่อ domain intent ให้ Phase 0.4พิจารณา explicit actionหรือ sub-resource เช่น:

```text
POST /resources/:resourceId/<action>
```

เหมาะกับ concept เช่น schedule/revoke cancellation, rotate session หรือ mark notification read แต่ไม่ใช้ action suffixกับ CRUDปกติ:

```text
POST /subscriptions/create   # rejected pattern
POST /subscriptions          # creation semanticsครบแล้ว
```

สำคัญ:

```text
Cancel Subscription != DELETE Subscription
```

Cancellationคือ validated transitionระหว่าง `ACTIVE`, `CANCELLATION_SCHEDULED`, `CANCELLED` หรือ direct cancellationที่ contractรองรับ Physical removal/archiveยังเป็น separate open product/API decision

## 8. Request and Response JSON Conventions

- Media typeปกติ: `application/json`
- Encoding: UTF-8 รองรับภาษาไทย/Unicodeโดยธรรมชาติ
- Public JSON field: camelCase
- Enum: uppercase string
- Boolean: JSON `true`/`false` เท่านั้น ไม่รับ `"true"`, `"false"`, `1`, `0`
- Ordinary integer: JSON number เช่น `{ "daysBefore": 3 }`
- Precision-sensitive Money decimal: JSON stringตาม section 18
- Empty stringไม่แปลเป็น `null`อัตโนมัติ
- XMLไม่รองรับ; `multipart/form-data`เพิ่มเฉพาะ endpoint uploadที่มี requirementจริง
- Response DTOกำหนด public representation; ห้าม serialize TypeORM Entityตรง

## 9. Standard Success Responses

### 9.1 Chosen Envelope

ใช้ lightweight envelopeสำหรับ responseที่มี representation:

```json
{
  "data": {
    "id": "6d685b52-31af-4f70-a24a-22882af80e71",
    "status": "ACTIVE"
  }
}
```

เหตุผล: single/collection/read-modelใช้ top-level patternเดียวกันและ collectionเพิ่ม paginationได้โดยไม่เปลี่ยนชนิด `data` ไม่เพิ่ม `meta`ที่ว่างหรือ nested `result.payload`โดยไม่มีความหมาย

### 9.2 Creation and Update

- synchronous creation: `201 Created` + `{ "data": <created representation> }`
- addressable resource **SHOULD**ส่ง `Location` headerเป็น canonical versioned path
- PATCH default: `200 OK` + updated representation เพราะ mobileต้องใช้ canonical server-calculated fields
- ใช้ `204 No Content`เฉพาะ successful action/deletionที่ representationไม่เพิ่มคุณค่า และห้ามมี response body

### 9.3 Collection and Empty Collection

```json
{
  "data": [],
  "pagination": {
    "nextCursor": null,
    "hasMore": false
  }
}
```

Empty collectionคืน `200 OK` ไม่ใช่ 404 `total`ไม่รวมโดย defaultเพราะอาจเพิ่ม count query; endpointที่ UIต้องใช้จริงค่อยระบุ optional `total`ใน Phase 0.4

### 9.4 Request ID

Success responseส่ง request IDเฉพาะ `X-Request-ID` header ไม่ซ้ำใน JSON Error envelopeรวม identifierเดียวกันเพื่อให้ diagnosticsยังอยู่เมื่อ headerถูก client abstractionซ่อน

## 10. Error Model

ทุก error responseที่ APIควบคุมได้ใช้ envelope:

```json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "Resource not found",
    "details": null,
    "requestId": "01K50M7M9H3JQ6A2E8B4C1D0FG"
  }
}
```

| Field | Contract |
| --- | --- |
| `code` | Stable machine-readable uppercase snake-case; client branchingใช้ fieldนี้ |
| `message` | Human-readable summary; wordingเปลี่ยนได้และไม่ใช่ programmatic contract |
| `details` | `null`, object หรือ arrayตาม error category; ไม่มี raw exception |
| `requestId` | Canonical resolved request IDตรงกับ response header |

ห้าม expose stack trace, SQL/query, constraint/index name, filesystem path, provider secret, raw exceptionหรือ internal dependency topology

### 10.1 Error Code Families

Generic categories:

```text
VALIDATION_ERROR
MALFORMED_REQUEST
AUTHENTICATION_REQUIRED
TOKEN_INVALID
TOKEN_EXPIRED
RESOURCE_NOT_FOUND
FORBIDDEN
CONFLICT
RATE_LIMITED
SERVICE_UNAVAILABLE
INTERNAL_ERROR
```

Feature codeใช้ `<DOMAIN>_<CONDITION>` เช่น `SUBSCRIPTION_NOT_FOUND`, `INVALID_SUBSCRIPTION_STATE`, `PIN_VERIFICATION_FAILED` Phase 0.4กำหนดรายการจริงต่อ endpoint

### 10.2 Validation Details

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Request validation failed",
    "details": [
      {
        "field": "price.amount",
        "code": "MIN_VALUE",
        "message": "amount must be greater than or equal to 0"
      }
    ],
    "requestId": "01K50M7M9H3JQ6A2E8B4C1D0FG"
  }
}
```

Field pathใช้ dot notation; array indexใช้รูป `items[0].field` Error adapterต้อง map class-validator/domain errorsเป็น public codesและห้ามส่ง decorator names/internal constraint objectsตรง

### 10.3 Domain Conflict

Valid requestที่ขัดกับ current stateใช้ 409:

```json
{
  "error": {
    "code": "INVALID_SUBSCRIPTION_STATE",
    "message": "Subscription cannot transition from its current state",
    "details": {
      "currentStatus": "CANCELLED"
    },
    "requestId": "01K50M7M9H3JQ6A2E8B4C1D0FG"
  }
}
```

Detailsเผยเฉพาะข้อมูลที่ safe/usefulและไม่ทำให้ ownership concealmentเสีย

## 11. HTTP Status Code Standard

| Status | Use |
| ---: | --- |
| `200 OK` | Successful read, PATCHพร้อม representation หรือ completed actionพร้อม result |
| `201 Created` | Synchronously created resource |
| `202 Accepted` | Work acceptedแต่ primary requested outcomeยังไม่ completeและจะทำ async |
| `204 No Content` | Completed operationไม่มี useful representation; bodyต้องว่าง |
| `400 Bad Request` | Malformed JSON, invalid URL/query syntax/protocol-level request |
| `401 Unauthorized` | Missing, invalid, expired access token หรือ authentication/sessionไม่ valid |
| `403 Forbidden` | Authenticatedและresource existence intentionally visible แต่ policy/roleห้าม operation |
| `404 Not Found` | Resourceไม่มี หรือ user-owned resourceอยู่นอก CurrentUser scopeเพื่อป้องกัน enumeration |
| `409 Conflict` | Current-state, uniqueness, concurrency หรือ idempotency-key/payload conflict |
| `422 Unprocessable Content` | JSON/parameters parseได้แต่ field/semantic validationไม่ผ่าน |
| `429 Too Many Requests` | Rate/attempt limit;ส่ง `Retry-After`เมื่อมี meaningful retry time |
| `500 Internal Server Error` | Unexpected application failure |
| `502 Bad Gateway` | API/edgeได้รับ invalid/unusable responseจาก upstreamใน synchronous proxy/provider use case |
| `503 Service Unavailable` | Required dependency/capabilityชั่วคราวไม่พร้อม เช่น PostgreSQLหรือ queue-required operation |

อย่า map database constraintทุกตัวเป็น 409อัตโนมัติ Adapterต้องแปล expected constraintเป็น domain code; unexpected constraintเป็น sanitized 500และ log internal context

## 12. Validation Standard

### 12.1 Chosen Status

```text
valid JSON/query shape + invalid field/domain input → 422
malformed JSON/protocol/query syntax              → 400
valid command + conflict with current state       → 409
```

แม้ NestJS default validationมักคืน 400 โครงการเลือก 422เพื่อแยก transport parsingจาก field/semantic validationอย่างสม่ำเสมอ Future global ValidationPipe/exception mappingต้องบังคับ conventionเดียวทุก module

### 12.2 Strict Input Rules

- allow-list DTO properties
- reject unknown/non-whitelisted properties; valid JSONที่มี unsupported fieldคืน 422
- ไม่ map arbitrary bodyเข้า TypeORM update
- ปิด surprising implicit coercion; bodyต้องใช้ JSON typeที่ contractระบุ
- query parameterเริ่มเป็น stringที่ HTTP boundaryและต้อง parse/validateอย่าง explicit
- unknown enum, invalid UUID/date/timezone/cursor/sort/filterคืน structured 422
- normalization เช่น trim/lowercaseเกิดเฉพาะเมื่อ endpoint contractประกาศ ไม่ใช้ `""`แทน nullเงียบ ๆ

## 13. Authentication

### 13.1 Transport and Boundary

Authenticated business APIsใช้:

```http
Authorization: Bearer <access-token>
```

ห้ามส่ง access/refresh/provider tokenใน URLหรือ query string Conceptual flow:

```text
provider authentication
        ↓
backend authentication/session boundary
        ↓
application access token
        ↓
NestJS Auth Guard → CurrentUser
```

OAuth exchangeยัง openระหว่าง Firebase-mediatedกับ direct provider flow Standardsนี้ไม่ถือ provider tokenเป็น business API credentialโดยอัตโนมัติ

### 13.2 Access Token vs Refresh Session

```text
Access Token    = short-lived stateless credentialสำหรับ API requests
Refresh Session = durable/revocable server-side sessionสำหรับ refresh rotation
```

Exact lifetime, token format, cookie-vs-bodyของ refresh endpointและ rotation protocolเป็น Auth design/API Contract decision Raw refresh tokenไม่ถูก persist/log

### 13.3 Authentication Errors

- missing token → 401 `AUTHENTICATION_REQUIRED`
- malformed/invalid token → 401 `TOKEN_INVALID`
- expired token → 401 `TOKEN_EXPIRED`
- refresh session revoked/expiredใน refresh context → 401 ด้วย specific auth codeที่ Phase 0.4กำหนด
- 403ใช้หลัง authenticationสำเร็จแล้วเท่านั้น

Responseควรมี `WWW-Authenticate: Bearer`เมื่อเหมาะกับ HTTP Bearer semantics โดยไม่ใส่ secret/error detailที่อ่อนไหว

## 14. Authorization and Ownership

```text
Authentication = Who are you?
Authorization  = Can you perform this operation on this resource?
```

CurrentUserได้จาก verified access tokenและส่งเข้า application use case Public self-service requestsไม่รับ `userId`เพื่อเลือก owner

```text
access token
    ↓ Auth Guard
CurrentUser.id
    ↓ owner-scoped use case/query
resource.user_id = CurrentUser.id
```

Standards:

- create user-owned resource: backendกำหนด ownerจาก CurrentUser
- read/update/action: queryด้วย resource ID + owner ID ไม่ loadแล้วเชื่อ client
- Flutter hidden button/route guardไม่ใช่ authorization
- clientห้ามเปลี่ยน `userId`, credential stateหรือ internal dispatch/dedupe stateผ่าน generic PATCH
- physical FKไม่แทน authorization

### 14.1 404 Concealment vs 403

User-owned resourceที่ไม่มีหรือเป็นของ Userอื่นคืน 404แบบเดียวกันเพื่อลด enumeration ห้ามเผยต่างกันด้วย error message/timingโดยตั้งใจ

403ใช้เมื่อ resource existenceเปิดเผยโดย contractอย่างจงใจแต่ authenticated principalไม่มี permission เช่น future admin/publishing policy Phase 0.4ต้องระบุ exceptionชัด

## 15. PIN-Protected Operations

บาง sensitive actionอาจต้อง step-upด้วย PINนอกเหนือจาก access token:

- serverเป็นผู้ verify PIN/step-up proof
- clientห้ามส่ง `pinVerified: true`เพื่อ assertผลเอง
- PINไม่อยู่ URL/query, response, logหรือ error details
- repeated failuresต้องใช้ server-side attempt limit/lockout
- exact protected endpoints, PIN transportและ whether short-lived proof/re-authใช้ซ้ำได้ยังเป็น Auth/Security decisionของ Phase 0.4/ก่อน implementation
- current UI 6 digitsไม่ทำให้ API/domain schema hardcodeความยาวถาวร

## 16. Endpoint Access Classes

Phase 0.4ต้องจัดทุก endpointลงหนึ่ง class:

| Class | Meaning |
| --- | --- |
| Public | ไม่ต้อง access token; จำกัดเฉพาะ use caseที่จำเป็น |
| Authenticated | ต้อง CurrentUserแต่ไม่อ้าง user-owned resourceเฉพาะ |
| Authenticated + ownership | ต้อง owner-scoped lookup/action |
| Authenticated + PIN/elevated check | sensitive actionที่ policyกำหนด |
| Operational/internal | health/administration; exposureกำหนดที่ edge/deployment |

Internal/admin routeไม่เปิด publicโดย default

## 17. Cursor Pagination

### 17.1 Chosen Standard

Growing collectionsที่ต้อง paginateใช้ opaque cursor ไม่ใช้ offset/pageเป็น default:

```http
GET /api/v1/<resources>?limit=20&cursor=<opaque>
```

```json
{
  "data": [
    {
      "id": "6d685b52-31af-4f70-a24a-22882af80e71"
    }
  ],
  "pagination": {
    "nextCursor": "eyJ2IjoxLC4uLn0",
    "hasMore": true
  }
}
```

- default `limit = 20`
- maximum `limit = 100`
- integerนอกช่วงหรือ formatผิด → 422
- response pageสุดท้ายใช้ `nextCursor: null`, `hasMore: false`
- exact `total`ไม่คืนโดย default

### 17.2 Cursor Semantics

Cursorเป็น opaque, versionedและควร tamper-evident Clientเก็บ/ส่งต่อเท่านั้น ห้าม parseหรือสร้างเอง ภายในอาจ encode stable ordering tupleเช่น `createdAt + id` แต่ formatไม่ใช่ public contract

```text
cursor != row offset
```

Cursorผูกกับ endpoint, authenticated scope, filtersและsortที่ใช้สร้าง cursor หาก reuseกับ query contextต่างกันให้คืน 422 `INVALID_CURSOR` ไม่ silently reinterpret

Endpointที่เป็น bounded/static catalogและไม่ต้อง paginationอาจคืน collectionตรงตาม Phase 0.4 แต่ห้ามสร้าง page/offset conventionที่สองโดยไม่มีเหตุผล

## 18. Filtering, Sorting and Search

### 18.1 Filtering

ใช้ named query parametersจาก endpoint allow-list:

```text
?status=ACTIVE
?status=ACTIVE&status=CANCELLED
```

Multi-valueใช้ repeated query parameterตาม OpenAPI `style=form, explode=true` ไม่ใช้ SQL-like expression Unknown filter/valueคืน 422; ไม่ตีความ unknown parameterเป็น dynamic column

### 18.2 Sorting

ใช้หนึ่ง `sort` parameter:

```text
?sort=createdAt     # ascending
?sort=-createdAt    # descending
```

แต่ละ endpointประกาศ allow-listของ public fieldsและ deterministic tie-breaker (ปกติ `id`) ห้ามส่งชื่อ database column/SQL fragmentตรงเข้า ORM Unknown sortคืน 422 Default sortกำหนดใน Phase 0.4ต่อ collection

### 18.3 Search

Free-text searchถ้ามีใช้ `q`:

```text
?q=netflix
```

Phase 0.4ระบุ fields, normalizationและcase behaviorต่อ endpoint ไม่มี generic full-text search infrastructureหรือ arbitrary expressionใน v1

## 19. Money Representation

### 19.1 Chosen Shape

Inputและoutputใช้ nested Money objectแบบเดียว:

```json
{
  "price": {
    "amount": "199.0000",
    "currency": "THB"
  }
}
```

- `amount`เป็น canonical base-10 decimal string ไม่ใช่ JSON number
- `currency`เป็น uppercase ISO 4217-style 3-letter string
- ห้ามใช้ formatted `"฿199"`, `"199 THB"`หรือ locale separatorsเป็น machine value
- serverรับ representationเดียว ไม่รับทั้ง stringและnumberเพื่อ convenience
- Phase 0.4กำหนด scale/rangeจาก ERD `NUMERIC(19,4)`; responseควร serialize scaleอย่างสม่ำเสมอ 4 decimal placesใน v1
- TypeORM NUMERIC stringต้องผ่าน decimal-safe validation/arithmetic; Flutter parseด้วย decimal-safe strategyก่อน formatting

เลือก objectแทน flattened `priceAmount`/`currencyCode`เพื่อรักษา Money semanticsและ reuseใน response/read models โดยไม่ทำให้ database column namesเป็น public contract

## 20. Date, Instant and Timezone

### 20.1 Calendar Date

PostgreSQL `DATE` serializeเป็น RFC 3339 full-date:

```json
{
  "nextBillingDate": "2026-09-30"
}
```

ห้ามเติม `Z`, offsetหรือ time-of-day เพราะ calendar dateไม่ใช่ instant

### 20.2 Instant

`TIMESTAMPTZ` serializeเป็น RFC 3339 normalized UTC:

```json
{
  "createdAt": "2026-09-14T05:30:00.000Z"
}
```

Instant inputต้องมี `Z`หรือ explicit numeric offset Timezone-less datetimeคืน 422

### 20.3 Timezone

ใช้ validated IANA identifier:

```json
{
  "billingTimezone": "Asia/Bangkok"
}
```

ห้ามใช้ `UTC+7`, `GMT+7`หรือ offset-onlyเป็น durable billing timezone เพราะไม่รักษา regional/DST calendar rules

### 20.4 BillingSchedule Boundary

Public write modelไม่ mirror persistence columnsทั้งหมด Clientส่ง recurrence intentที่ use caseต้องใช้ ส่วน Backend validate stable anchorและคำนวณ/persist next occurrence

```text
client schedule intent
        ↓
Backend calendar rules + timezone
        ↓
server-calculated nextBillingDate
```

`nextBillingDate`เป็น server-owned/read-onlyโดย default Phase 0.4อาจอนุญาต clientเสนอ initial billing date/anchorใน create/update command แต่ห้าม generic PATCH persistence fieldโดยตรง Short-monthและ Feb 29 semanticsยังเป็น domain rule

## 21. Enum and Controlled Values

Public enumใช้ uppercase stringตรงกับ stable domain meaning:

```json
{
  "status": "ACTIVE",
  "billingIntervalUnit": "MONTH",
  "usageLevel": "MODERATE"
}
```

ห้าม numeric enum Unknown write valueคืน 422 OpenAPIต้อง enumerate current values การเพิ่ม response enum valueอาจทำให้ clientที่ parseแบบ exhaustiveพัง จึงต้องประสาน rolloutและ Flutterควรมี defensive fallbackเมื่อเหมาะสม

## 22. Null, Missing and PATCH Semantics

```text
field missing          → do not change
field present as null  → explicitly clear, only if contract marks nullable/clearable
field present as value → validate and replace/update
```

ตัวอย่าง `{}` ต่างจาก `{ "usageLevel": null }` DTO transformationต้องรักษา property presence Phase 0.4/OpenAPIต้องแยก:

- optional: requestไม่ต้องมี field
- nullable: fieldมีค่า `null`ได้
- read-only/write-only

Empty stringไม่แทน null Boolean `false`ไม่แทน missing/null โดยเฉพาะ reminder override contractต้อง represent `INHERIT`, `ENABLED`, `DISABLED`อย่างชัด ไม่ใช้ booleanเดียวที่ `false`แปลได้ทั้ง disableและ inherit

## 23. Idempotency

### 23.1 Operation Classification

Phase 0.4ต้องระบุ write operationแต่ละรายการเป็น:

| Class | `Idempotency-Key` policy |
| --- | --- |
| Safe `GET` | ไม่ใช้ |
| Naturally idempotent update/deleteตาม resource identity | ไม่บังคับ; invariants/transactionsยังต้องรักษา |
| POSTที่ retryแล้วอาจสร้าง business record/commandซ้ำ | Required เว้นแต่มี durable natural uniquenessที่ให้ outcomeเดียวกัน |
| Device registrationหรือ identity linkingที่ DB business uniquenessทำให้ retry converge | Headerอาจไม่จำเป็น; endpointต้อง idempotentโดย natural key |
| Async initiationที่ duplicate workมี side effect | Requiredหรือ durable operation identityตาม contract |

Headerรูปแบบ:

```http
Idempotency-Key: <opaque-client-generated-value>
```

### 23.2 Key Semantics

- validate bounded printable token; recommended 8–128 characters โดย exact grammarล็อกใน Phase 0.4/OpenAPI
- scopeด้วย authenticated User + HTTP method + canonical route/action
- same scope/key + same normalized request fingerprint → return same logical outcome/status/representation
- same scope/key + different payload → 409 `IDEMPOTENCY_KEY_REUSED`
- keyมี bounded retentionที่ยาวพอสำหรับ mobile retry window
- responseต้องไม่ expose internal storage key/Redis key

หาก duplicate business recordเป็นอันตราย ความถูกต้องต้องพึ่ง durable PostgreSQL record/operation-specific UNIQUE ไม่ใช้ Redisเพียงอย่างเดียว Current 9-table ERDยังไม่มี generic HTTP idempotency table ดังนั้น Phase 0.4ต้อง mark endpointที่ต้องใช้ header และ Backend Foundationต้องเลือก shared durable idempotency storeหรือ natural constraintก่อน implement endpointแรก Exact persistence/retentionเป็น **OPEN implementation decision** แต่ public header semanticsถูกล็อกแล้ว

### 23.3 HTTP vs Worker Idempotency

```text
HTTP Idempotency-Key != BullMQ job idempotency
```

HTTP mechanismกัน client/network retryซ้ำ Workerต้อง re-check durable stateและมี idempotencyของ side effectเอง เช่น reminder Notificationใช้ PostgreSQL unique logical `dedupeKey` BullMQ job IDไม่แทน public keyหรือ durable business guard

## 24. Synchronous and Asynchronous Responses

### 24.1 Completed Primary Operation

ถ้า durable primary operationสำเร็จแล้ว ให้คืน 200/201/204ตาม semantics แม้มี follow-up side effectเข้า queue:

```text
Package change committed
        + notification fan-out queued
→ package mutation itself is complete
→ normal success, not automatically 202
```

ต้องไม่กล่าวว่า external notificationส่งสำเร็จเพียงเพราะ enqueueสำเร็จ

### 24.2 Accepted Async Operation

ใช้ 202เมื่อ requested outcomeยังไม่ completeและระบบรับผิดชอบทำภายหลัง ถ้ามี public operation resourceจริงอาจคืน:

```json
{
  "data": {
    "operationId": "6d685b52-31af-4f70-a24a-22882af80e71",
    "status": "ACCEPTED"
  }
}
```

ห้าม invent operation resourceเพื่อ wrap BullMQ job ถ้าไม่มี public tracking model 202ที่ไม่มี meaningful receiptอาจคืน `{ "data": null }`ตาม endpoint contract แต่ห้าม expose queue name, Redis key, Worker hostnameหรือ BullMQ job IDเป็น long-term mobile contract

Queue-required operationที่ enqueueไม่ได้ไม่ควรคืน success/202แบบหลอก; mapเป็น availability/errorตาม durability semanticsของ use case

## 25. Correlation and Request ID

ใช้ `X-Request-ID` เป็น canonical correlation headerทุก HTTP response

```http
X-Request-ID: 01K50M7M9H3JQ6A2E8B4C1D0FG
```

Resolution policy:

1. Nginx/APIรับ incoming IDเฉพาะจาก trusted proxy pathหรือ client valueที่ผ่าน validation
2. valid formatใช้ bounded ASCII `[A-Za-z0-9._-]`, ความยาว 1–128
3. missing/invalid/untrusted value → generate server-side ID ไม่ echo arbitrary input
4. API/loggerใช้ resolved IDเดียวกันและ responseคืน headerนี้
5. error envelopeใช้ `requestId`เดียวกัน; success JSONไม่ซ้ำ ID
6. enqueue flowอาจ copy request IDเป็น trace metadata แต่ jobต้องมี identityของตนเองและ background scheduleที่ไม่มี HTTP requestสร้าง correlationใหม่ได้

Request IDไม่ใช่ authentication, idempotency keyหรือ business identifier ไม่เก็บเป็น domain Entity

## 26. Rate Limiting and Availability Errors

### 26.1 Rate Limiting

- limitเกิน → 429 `RATE_LIMITED`
- ส่ง `Retry-After`เมื่อ serverรู้เวลาที่ retryมีความหมาย
- PIN/auth/refresh endpointsอาจมี stricter limitและ lockout policy
- exact quotas/window/storageยัง openตาม Security/Operations design

### 26.2 Availability Boundary

| Failure | Public behavior principle |
| --- | --- |
| PostgreSQL unavailable | Core durable operationไม่ดำเนินต่อ; 503 sanitized availability error |
| Redis cache unavailable | Safe cache-enabled readอาจ fallback PostgreSQLโดย response contractไม่เปลี่ยน |
| Redis/BullMQ unavailable | Queue-required operationต้อง fail/surface 503ตาม endpoint semantics; ไม่มี cache-style fallback |
| External synchronous upstream invalid/unreachable | 502หรือ mapped domain availability errorตาม API role |
| Unexpected bug | 500 `INTERNAL_ERROR`; detailอยู่ structured internal log |

Clientไม่ควรรู้ dependencyชื่อ Redis/PostgreSQLจาก public messageโดย default

## 27. Health API Conventions

แนะนำ operational routesนอก versioned business namespace:

```text
/health/live
/health/ready
```

เหตุผล: health contractผูกกับ deployment/processไม่ใช่ mobile business API version

- liveness = processตอบสนอง; ห้าม failเพราะ optional downstreamชั่วคราว
- readiness = runtimeพร้อมให้ meaningful capability; APIอย่างน้อยพิจารณา PostgreSQLและ required Redis/queue capabilityตาม runtime policy
- responseเล็ก, machine-readable, ไม่เผย credentials, hostnames, connection stringsหรือ exception
- livenessอาจ edge-visibleตาม deployment need; readinessควรจำกัด internal/load-balancer accessเมื่อทำได้
- exact response schema/statusและ public exposureสรุปใน Phase 0.4/Operations design

## 28. DTO, Entity and Read-Model Boundaries

```text
Database Entity
!= Create DTO
!= Update DTO
!= Response DTO
!= Derived Read Model
```

ตัวอย่าง:

- `user_id`มาจาก CurrentUser ไม่รับใน self-service create DTO
- `created_at`/`updated_at` mapเป็น response `createdAt`/`updatedAt`และ server-owned
- `next_billing_date` mapเป็น `nextBillingDate`แต่ serverคำนวณโดย default
- preset flowอาจรับ `originatingPackageVersionId`; clientไม่ได้เขียน PackageVersion objectหรือ Package IDลง Subscriptionตรง
- `pinVerifier`, refresh verifier, internal `dedupeKey`, raw push tokenและ database-only stateไม่อยู่ generic responses
- Dashboard responseเป็น derived aggregation DTOได้แม้ไม่มี dashboard table

Controllerห้ามคืน TypeORM Entityตรงและห้าม spread arbitrary requestเข้า persistence Response serializerต้องควบคุม nullable, read-only, Money/dateและenum representationอย่าง explicit

## 29. Domain Representation Boundaries

### 29.1 Package vs Subscription

```text
Package / PackageVersion = catalog data and historical origin
Subscription             = user's authoritative tracked snapshot
```

Subscription responseห้ามแทน tracked price/nameด้วย latest PackageVersion ถ้าแสดง current catalog comparison ต้องใช้ field/objectชื่อชัดว่า origin/current catalog context ไม่สับสน `trackedPrice`กับ `currentCatalogPrice` Exact DTOชื่อเป็น Phase 0.4

### 29.2 Server-Calculated Fields

Fieldsเช่น `nextBillingDate`, effective reminder settings, annualized cost, status-derived flagsและ dashboard totalsอาจเป็น read-only/derived Clientห้าม assumeว่า response fieldทุกตัว PATCHได้ OpenAPIต้อง mark read-only/write-onlyต่อ field

### 29.3 Cache and Queue Transparency

- Redis hit/missไม่เปลี่ยน status, shape, freshness contractหรือ correctness
- ไม่ expose cache headers/debugข้อมูลโดย default
- BullMQ stateไม่อยู่ Notification API
- Notification read/dismissทำกับ durable Notification
- provider deliveryเป็น at-least-once/best-effort; per-device/channel delivery auditยัง deferred

### 29.4 Device Registration

DeviceRegistration ownerมาจาก CurrentUser Same User + same token retryต้อง convergeที่ active registrationเดียว Tokenย้าย Userต้อง resolve old ownershipใน backend transaction Clientห้ามกำหนด ownerและ generic User profileไม่ expose token list

## 30. Security and Sensitive Data

API baseline:

- productionใช้ HTTPSผ่าน Nginx
- Bearer tokenอยู่ Authorization header ไม่อยู่ URL
- server-side auth, ownershipและPIN verification
- strict DTO allow-list; unknown writable fieldถูก reject
- no mass assignmentหรือ direct Entity serialization
- rate limit sensitive operations
- Nginxไม่แทน application authorization
- CORSใช้ environment-configured allow-listเมื่อ deploy browser client; ห้าม `*`ร่วม credentialsใน production
- request/errorไม่เผย internal stack/schema/dependency

Log redaction/omissionอย่างน้อยครอบคลุม:

```text
Authorization
access/refresh/provider tokens
PIN and PIN verifier
refresh-token verifier
FCM token unless tightly scoped operational log requires a redacted fingerprint
full sensitive request bodies
```

Structured request logใช้ safe contextเช่น requestId, method, route template, statusCode, durationและ authenticated User IDเมื่อ policyอนุญาต ห้าม log raw URL queryหากอาจมี sensitive data

## 31. OpenAPI / Swagger Conventions

Phase 0.4ต้อง documentทุก public endpointด้วย:

- operation summaryและคำอธิบาย business intent
- tagsตาม public domain: `Auth`, `Users`, `Subscriptions`, `Packages`, `Dashboard`, `Notifications`, `Health`
- path/query/header/request DTO schema
- success responseและ standard error responsesที่ endpointเกิดได้จริง
- HTTP Bearer security schemeสำหรับ authenticated endpoints
- enum values, format, example, default, min/max
- required vs optional vs nullable และ readOnly/writeOnly
- pagination/filter/sort allow-list
- `Idempotency-Key` requirementต่อ operation
- synthetic examplesที่ไม่มี real credential/token/user/production URL
- deprecated operation/field markชัด

ห้ามสร้าง tags `Database`, `Redis`, `BullMQ`, `Infrastructure` เพราะไม่ใช่ public domains OpenAPI Bearer schemeหมายถึง application access token ไม่ได้ lockว่า OAuth provider tokenถูกใช้ตรง

Reusable schemasควรมีเฉพาะ conceptที่เหมือนกันจริง เช่น Money, pagination metadata, error envelopeและ validation detail ห้ามสร้าง generic `AnyDataResponse`จน type informationหาย

## 32. Compatibility and Version Evolution

### 32.1 Usually Additive Within v1

- เพิ่ม endpointใหม่
- เพิ่ม optional request fieldที่มี backward-compatible default
- เพิ่ม optional response fieldเมื่อ clientsถูกกำหนดให้ ignore unknown fields
- เพิ่ม error codeสำหรับ conditionใหม่โดย endpoint contract update

### 32.2 Potentially Breaking

- rename/remove field
- เปลี่ยน field type, Money shape, date/time semanticsหรือ nullability
- เปลี่ยน success/error envelope
- เปลี่ยน ownership/status/action semantics
- remove/rename enum value
- เพิ่ม enum valueสำหรับ clientที่ exhaustive parseโดยไม่มี fallback
- เปลี่ยน default sort/cursor interpretationกลาง pagination lifecycle

Breaking public contractต้องใช้ migration/deprecation strategyและอาจสร้าง `/api/v2` ไม่ mutate v1เงียบ ๆ Deprecationควร markใน OpenAPIและประกาศ timeline; headersเช่น `Deprecation`/`Sunset`พิจารณาเมื่อมี processจริง ไม่ lockใน v1ตอนนี้

## 33. Flutter Integration Expectations

Flutter integrationภายหลังต้องรองรับ:

```text
camelCase JSON
{ data: ... } success envelope
standard error.code + error.details + requestId
decimal Money string + currency
YYYY-MM-DD calendar date
RFC 3339 UTC instant
IANA timezone
uppercase enums with defensive fallback where appropriate
Bearer access token
opaque cursor pagination
PATCH missing vs explicit null
X-Request-ID diagnostics
```

งานนี้ไม่แก้ Flutter models/repositories และไม่ยืนยันว่า frontend classปัจจุบันคือ API DTO

## 34. NestJS Implementation Expectations

Standards mapกับ future NestJS conceptsได้ดังนี้โดยยังไม่ implement:

- global `/api` prefix + URI version `v1` หรือ equivalent explicit `/api/v1` routingหนึ่งวิธีที่ไม่ duplicate prefix
- strict global ValidationPipeพร้อม whitelist + forbidNonWhitelisted และ custom 422 mapping
- exception filterสำหรับ error envelope/constraint translation
- Auth Guard + CurrentUser decorator/context
- owner-scoped application services
- explicit Create/Update/Response DTOsและ serialization interceptor
- reusable cursor/Money/date validation componentsเฉพาะเมื่อ reuseจริง
- request-ID middleware/interceptorที่ทำงานกับ trusted proxy contract
- Swagger/OpenAPI setupพร้อม tags/security/common errors

ห้ามวาง business validation, TypeORM query, Redis keyหรือ BullMQ orchestrationใน Controller

## 35. API Standards Decision Matrix

| Topic | v1 Standard | Rationale |
| --- | --- | --- |
| API version | `/api/v1` path versioning | Explicit stable mobile contract |
| Resource paths | plural lowercase nouns; kebab-case if needed | Standard REST readability |
| Path/query/JSON fields | camelCase public names | ไม่ leak database snake_case; Flutter-friendly |
| Success shape | `{ "data": ... }`; collectionเพิ่ม `pagination` | Lightweight consistency |
| Error shape | `{ "error": { code, message, details, requestId } }` | Predictable machine handling |
| Validation status | 422 for parsed field/semantic errors; 400 malformed | Clear transport/domain-input boundary |
| Ownership concealment | 404 absentหรือout-of-scope; 403 intentionally visible denial | Reduce enumeration |
| Pagination | opaque cursor; default 20, max 100 | Stable growing mobile lists |
| Sorting | `sort=field`, `sort=-field`, endpoint allow-list | Compactและ injection-safe |
| Multi-value filters | repeated parameters (`explode=true`) | OpenAPI-native and explicit |
| Search | `q` when endpoint supports | No generic query language |
| Money | object + decimal string + uppercase currency | Preserve PostgreSQL NUMERIC precision |
| Calendar date | `YYYY-MM-DD` | DATE is not instant |
| Instant | RFC 3339 UTC output | Unambiguous TIMESTAMPTZ representation |
| Timezone | IANA string | Deterministic calendar recurrence |
| Enum | uppercase string | Readable/OpenAPI/Flutter mapping |
| PATCH | missing=no change; null=explicit clear if allowed | Prevent accidental clearing |
| Auth transport | `Authorization: Bearer` access token | Stateless API; no token in URL |
| User ownership | CurrentUser-derived | Server-side security |
| HTTP idempotency | Required for dangerous non-natural POSTs per contract | Safe mobile/network retry |
| Worker idempotency | Separate durable business guard | BullMQ retry differs from HTTP retry |
| Request ID | validated/resolved `X-Request-ID`; headerทุก response | Correlated diagnostics without JSON duplication |
| Async completion | 202 only when requested outcomeยัง pending | Queue side effect aloneไม่เปลี่ยน completed operationเป็น 202 |
| Unknown request fields | reject with 422 | Detect drift and prevent mass assignment |
| Health | non-versioned `/health/live`, `/health/ready` | Operational, not business API |

## 36. Remaining Open Decisions

| Decision | Why open | Resolve by |
| --- | --- | --- |
| OAuth/provider exchange flow | Firebase-mediated vs direct providerยังไม่เลือก | Auth design / Phase 0.4 before Phase 3 implementation |
| Refresh-token transport details | cookie/body, rotation responseและ exact lifetimeยังไม่ล็อก | Auth API Contract / Phase 0.4 |
| PIN step-up transport/proof scope | ยังไม่ทราบ endpointที่ protectedและ proof reuse policy | Security/API Contract before protected endpoints |
| Durable HTTP idempotency storage/retention | ERDไม่มี generic request table; natural vs shared storeขึ้นกับ endpoint | Phase 0.4 marks operations; resolve before first required implementation |
| REST polling vs SSE/WebSocket | ไม่มี realtime requirementชัด | Notification contract before Phase 7; REST remains default |
| CORS origins | ขึ้นกับ deployed Flutter web/domain | Deployment/API security config before browser production |
| Exact rate limits | ต้องอิง abuse riskและ load test | Security/Operations before production |
| Readiness public exposure/schema detail | ขึ้นกับ Nginx/load-balancer/monitoring topology | Operations + Phase 0.4 health contract |

Open itemsไม่เปลี่ยน global envelope, naming, Money/time, auth transport, ownershipหรือ pagination standards

## 37. API Standards vs API Contract

### API Standards — เอกสารนี้

```text
How all endpoints behave
```

### API Contract / OpenAPI v1 — Phase 0.4

```text
Which endpoints exist
What each endpoint accepts
What each endpoint returns
Which business errors each endpoint can produce
```

Generic examplesในเอกสารนี้ไม่ใช่ commitmentว่า feature routeนั้นมีอยู่

## 38. Architecture Consistency Review

| Concern | Classification | Result |
| --- | --- | --- |
| snake_case DB → camelCase JSON | API representation only | Consistent |
| NUMERIC → Money decimal string | API representation only | Preserves ERD precision |
| DATE/TIMESTAMPTZ/timezone serialization | API representation only | Preserves calendar/instant distinction |
| Billing intent vs `nextBillingDate` | Clarification | Write DTOไม่ mirror persistence; next occurrence server-owned by default |
| PackageVersion origin vs Subscription snapshot | Clarification | Response must label origin/current catalog separately |
| Notification dedupe | Clarification | Durable PostgreSQL occurrence remains internal correctness guard |
| NotificationDelivery deferral | Exact architecture boundary | No exact per-device audit promise |
| Device registration ownership | Clarification | CurrentUser-owned and naturally idempotent |
| RefreshSession/PIN | Clarification | Separate security flows; secrets absent from DTO/log |
| Redis/BullMQ | Exact architecture boundary | Cache transparent; queue identifiers internal |

ไม่พบ architecture contradiction Standardsนี้ไม่เพิ่ม endpoint, Entity, table, queueหรือ runtimeใหม่

## 39. Clean-Code Review Record

ตรวจด้วย repository-wide `$clean-code` แล้ว:

1. API conventionsไม่ expose database snake_case/constraint/Entity internals
2. Database Entity, write DTO, response DTOและ derived read modelแยกชัด
3. CurrentUserมาจาก verified token; user-owned lookup server-scopedและใช้ 404 concealment
4. Money stringรักษา NUMERIC precision; DATE, instantและIANA timezoneไม่ปะปน
5. Cursor opaqueและ bindกับ filter/sort scope; ไม่มี arbitrary SQL filter/order field
6. Validationใช้ 422อย่างสม่ำเสมอและ mapเป็น stable detailsแทน class-validator internals
7. 401/403/404/409 boundariesชัด; cancellationไม่ใช่ DELETE
8. Explicit business actionใช้เมื่อมี intentจริงโดยไม่เปลี่ยนทุก operationเป็น RPC
9. PATCHรักษา missing/null/false distinctionและ reject unknown fields
10. Mass assignmentป้องกันด้วย allow-listed DTOและ server-owned fields
11. HTTP idempotencyแยกจาก BullMQ idempotencyและไม่ใช้ Redis-onlyเมื่อ correctnessสำคัญ
12. 202ใช้เฉพาะ incomplete requested outcome; queued follow-upไม่บังคับ 202
13. Redis cacheโปร่งใสและ BullMQ identifiersไม่เป็น public contract
14. Notification delivery guaranteeไม่เกิน ERD: durable occurrence dedupeแต่ dispatch best-effort/at-least-once
15. X-Request-IDมี trust/validation/generation/propagation contractเดียว
16. Secret, raw requestและinternal exceptionถูกกันออกจาก error/log
17. OpenAPI conventionsระบุ optional/nullable/security/errors/idempotencyครบ
18. เอกสารหยุดก่อน endpoint enumerationและพร้อมให้ Phase 0.4ทำ contract

ประเด็นที่พบและแก้ระหว่าง review:

- เลือก 422แทนปล่อย NestJS default 400ปะปนระหว่าง malformedกับ validation
- ใช้ success envelopeเดียวแต่ไม่เพิ่ม empty metadata wrappers
- ผูก cursorกับ query contextเพื่อป้องกัน paginationผิดชุดข้อมูล
- แยก queued side effectจาก true 202 async outcome
- ไม่ใช้ coarse Notification delivery statusหรือ BullMQ job IDใน public response
- ระบุ durable storage gapของ `Idempotency-Key`อย่างตรงไปตรงมาแทนสมมติว่า Redisเพียงพอ
- ใช้ 404สำหรับ user-owned out-of-scope resourceเพื่อลด enumeration

## 40. Explicit Non-Goals

API Standards v1 ไม่สร้างหรือกำหนด:

- complete endpoint/feature route catalog
- feature-specific request/response DTO catalog
- Controllers, Services, Guards, decorators, filtersหรือ ValidationPipe code
- OpenAPI YAML/JSON, Swagger decoratorsหรือ Postman collection
- TypeORM Entities, migrationsหรือ SQL
- Redis keys, BullMQ jobs/payloadsหรือ Worker implementation
- Nginx/CORS/rate-limit config
- exact OAuth/JWT/PIN/FCM implementation
- CI/CDหรือ infrastructure deployment

## 41. Next Step and Contract Readiness

```text
READY FOR API CONTRACT V1
```

Global behaviorสำหรับ URL, JSON, success/error, status, validation, auth/ownership, pagination, Money/time, idempotency, asyncและ request IDถูกเลือกแล้ว Open decisionsที่เหลือมี resolution phaseชัดและ Phase 0.4สามารถระบุ endpoint-specific contractsได้โดยไม่ re-decide conventionsเหล่านี้

ขั้นถัดไปคือ **Phase 0.4 — API Contract / OpenAPI v1** เท่านั้น งานนี้ยังไม่เริ่ม endpoint catalog, OpenAPI artifactหรือ NestJS implementation
