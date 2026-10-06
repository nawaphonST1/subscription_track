# 🌐 System Overview: Subscription Track (Full-Stack Monorepo)

> **Document Purpose:** เอกสารสรุปภาพรวมทางเทคนิคระดับสถาปัตยกรรม (Architecture & System Overview) สำหรับนักพัฒนาและ AI Agent เพื่อให้เข้าใจบริบท โครงสร้างทั้ง 3 ส่วน (Frontend, Backend, Deploy & Infra), เครื่องมือ, ไลบรารี และสถานะปัจจุบันของระบบได้ทันที

---

## 📌 1. ภาพรวมระบบและความสามารถหลัก (Core Capabilities)

**Subscription Track** คือระบบตรวจจับ วิเคราะห์ และบริหารจัดการค่าบริการสมาชิกรายเดือน/รายปี (Subscription Tracker & Analytics System) มุ่งเน้นการแก้ปัญหา "Subscription Creep" (การมีค่าบริการรายเดือนงอกเงยจนกระทบความมั่นคงทางการเงิน)

### ✨ ความสามารถหลักของระบบ (Current Features)
1. **Dashboard สรุปภาพรวมการเงินและรอบบิล:**
   - รวมยอดค่าบริการสมาชิกทั้งหมด แปลงคำนวณเป็นยอดต่อเดือน (Monthly Expense) และยอดประมาณการรายปี (Annual Projection) แบบเรียลไทม์
   - แสดงไทม์ไลน์รอบบิลถัดไป (Upcoming Renewals) พร้อมการแจ้งเตือนรายการใกล้ถึงกำหนดชำระ
2. **คำนวณ Subscription Creep Score:**
   - อัลกอริทึมชี้วัดสัดส่วนค่าบริการเทียบกับรายได้สุทธิของผู้ใช้ (`(totalMonthlyExpenses / monthlyIncome) * 100`)
   - จัดหมวดหมู่ความเสี่ยง 3 ระดับ: **Safe (ปลอดภัย < 10%)**, **Moderate (ปานกลาง 10-20%)**, และ **High Risk (เสี่ยงสูง > 20%)**
3. **ระบบจำลองการประหยัด (Savings Simulation):**
   - ผู้ใช้สามารถเลือกติ๊กตัดบริการที่ไม่จำเป็นหรือไม่ได้ใช้งาน (Unused / Occasional)
   - คำนวณยอดเงินสดที่จะประหยัดได้คืนมาทันทีทั้งรายเดือนและยอดสะสมรายปี
   - บันทึกประวัติการขอยกเลิก (Cancellation Log) พร้อมเหตุผล
4. **คลัง Preset Packages ยอดนิยม:**
   - ฐานข้อมูลบริการยอดนิยมในไทย (Netflix, Spotify, YouTube Premium, Disney+ Hotstar, iCloud+, Apple One, ChatGPT Plus, GitHub Copilot ฯลฯ) พร้อมราคา สีประจำแบรนด์ และรอบบิล
5. **ระบบจัดการบัตรและการผูกบัญชี (Linked Cards & Auto-import):**
   - จำลองการผูกบัตรเครดิต/เดบิต (Mock Bank Cards: KBank, SCB, TTb, KTC)
   - นำเข้า (Auto-import) บริการที่ผูกกับบัตรอัตโนมัติ และตรวจจับยอดเรียกเก็บ
6. **ระบบความปลอดภัยและการยืนยันตัวตน:**
   - ระบบ **Security PIN 6 หลัก** ยืนยันสิทธิ์ก่อนแก้ไข ลบ หรือยกเลิกบริการ
   - ระบบ **JWT Authentication & Password Hashing** (ฝั่ง Backend)
7. **Responsive & Adaptive Shell:**
   - ปรับการแสดงผลอัตโนมัติตามขนาดหน้าจอ: โทรศัพท์มือถือ (Bottom Navigation Bar) และ แท็บเล็ต/เดสก์ท็อป (Navigation Rail ด้านข้าง)
8. **ระบบ In-App Version Checker & Force Update (Direct APK Sideloading):**
   - ตรวจจับเวอร์ชันของแอปพลิเคชันแบบไดนามิกผ่าน Manifest JSON (`version.json`) บน Azure Blob Storage
   - รองรับทั้ง **Optional Update** (แสดงความเปลี่ยนแปลง What's New พร้อมตัวเลือกอัปเดตภายหลัง) และ **Force Update** (ล็อกหน้าจอ ไม่อนุญาตให้ข้าม สำหรับอัปเดตด้านความปลอดภัยหรือ Breaking API)
   - ดาวน์โหลดและเตรียมติดตั้ง APK แทนที่ของเดิมได้ทันทีโดยคงสถานะและข้อมูลเดิมของผู้ใช้ไว้ครบถ้วน

---

## 🏛️ 2. โครงสร้าง Monorepo และความรับผิดชอบทั้ง 3 ส่วน

```text
subscription_track/
├── apps/
│   ├── mobile/         📱 ส่วนที่ 1: Frontend Mobile & Web Client (Flutter)
│   └── server/         🖥️ ส่วนที่ 2: Backend REST API & Workers (NestJS)
├── infra/              🐳 ส่วนที่ 3: Infrastructure Configurations (Nginx, Postgres, Redis, Monitoring)
├── scripts/            ⚙️ สคริปต์อัตโนมัติระดับ Monorepo
├── docker-compose.yml  🚀 ตัวจัดการ Container รันเครื่องแม่ข่ายและฐานข้อมูล
├── agent.md            📋 กฎระเบียบและแนวทางการทำงานร่วมกับ AI Agent
└── SYSTEM_OVERVIEW.md  📄 เอกสารภาพรวมระบบฉบับนี้ (Living Architecture & System Source of Truth)
```

---

## 📱 ส่วนที่ 1: Frontend (`apps/mobile/`)

- **เทคโนโลยีหลัก:** Flutter (Stable Channel), Dart 3.x
- **สถาปัตยกรรม:** **Feature-First Clean Architecture**
  - แบ่งโครงสร้างโค้ดตามฟีเจอร์ (`lib/features/<feature_name>/`)
  - แต่ละฟีเจอร์แยก Layer เคร่งครัด: `domain` -> `data` -> `application` -> `presentation`
- **รูปแบบการทำงานและความปลอดภัย (Connectivity & Security Model):** **Online-Only & Server-Authoritative**
  - บังคับเชื่อมต่ออินเทอร์เน็ตในการเรียกดูและทำธุรกรรมทุกรายการ **ไม่ใช้ระบบ Offline-First (Local Sync)** เพื่อป้องกันความเสี่ยงด้านความปลอดภัยจากการดัดแปลงข้อมูลในเครื่อง (Anti-Data Tampering) และป้องกันความคลาดเคลื่อนของรอบบิล/ยอดเงิน
  - ระบบยึดถือเซิร์ฟเวอร์กลาง (NestJS + PostgreSQL) เป็น **Single Source of Truth** ข้อมูลและผลการคำนวณ Creep Score จะถูก Validate ซ้ำที่ Server เสมอ
  - จัดเก็บเฉพาะ Authentication Token ใน Encrypted Storage (Keystore/Keychain) สำหรับระบุตัวตนผู้ใช้
- **การจัดการสถานะ (State Management):** **Riverpod (Riverpod 3 / Riverpod Annotation)** ทำงานร่วมกับ Code Generation (`build_runner`)
- **การจัดเส้นทาง (Navigation):** **GoRouter** แบบ Declarative Routing
- **สถานะปัจจุบัน:**
  - UI ครบทุก Flow ทั้ง 5 แท็บหลัก พร้อมโมดูล In-App Version Checker & Force Update
  - ใช้ `InMemorySubscriptionRepository` เป็น Data Source ชั่วคราวสำหรับการพัฒนา Client Standalone
  - มีชุดทดสอบ Unit Tests และ Widget Tests ผ่านครบ **61/61 tests passing**

### แผนผังหน้าจอและแท็บหลัก (Screens & Tabs)
| แท็บ / หน้าจอ | ที่ตั้งโค้ด | หน้าที่และความสามารถ |
|---|---|---|
| **Dashboard** | `lib/features/dashboard/presentation/dashboard_tab.dart` | กราฟสรุปยอดรวม, การ์ด Creep Score, ลิสต์รายการรอบบิลเร็วๆ นี้ |
| **Subscriptions** | `lib/features/subscriptions/presentation/subscriptions_tab.dart` | รายการสมาชิกทั้งหมด, ระบบค้นหา/ฟิลเตอร์, ปุ่มเพิ่ม/แก้ไขบริการ |
| **Savings** | `lib/features/savings/presentation/savings_tab.dart` | เครื่องมือจำลองการตัดลดค่าใช้จ่าย และตารางบันทึกเงินที่ประหยัดได้ |
| **Settings** | `lib/features/settings/presentation/settings_tab.dart` | ตั้งค่าความปลอดภัย, เปลี่ยน PIN 6 หลัก, สลับภาษา/การแจ้งเตือน |
| **Profile** | `lib/features/profile/presentation/profile_tab.dart` | โปรไฟล์ผู้ใช้, กำหนดรายได้ต่อเดือน (Monthly Income) เพื่อคำนวณ Creep Score |
| **Flow เสริม** | `splash/`, `onboarding/`, `auth/` | Splash screen, แนะนำฟีเจอร์แรกเริ่ม, และระบบ Login/PIN Prompt |

---

## 🖥️ ส่วนที่ 2: Backend (`apps/server/`)

- **เทคโนโลยีหลัก:** Node.js (v24 LTS), TypeScript, NestJS 12
- **สถาปัตยกรรม:** **Modular Monolith** (`src/main.ts` สำหรับ HTTP API และ `src/worker.ts` สำหรับ Background Worker)
- **ฐานข้อมูลและ ORM:** PostgreSQL 16/17 ร่วมกับ **Prisma ORM (^6.4.1)**
- **การรักษาความปลอดภัย:** Passport.js + JWT Strategy, Password Hashing (`bcrypt`), PIN Hashing, Global Auth Guard พร้อม Decorator `@Public()`
- **เอกสาร API:** **Swagger UI** ในตัว เข้าถึงได้ผ่าน `/docs` และ OpenAPI JSON ผ่าน `/docs-json`
- **สถานะปัจจุบัน:** โครงสร้างโมดูลครบถ้วน มี Data Models พร้อมสคริปต์ Seeding ข้อมูล Presets และ Mock Cards ครอบคลุม Unit Tests ด้วย **Vitest**

### โมดูลในระบบ Backend (Backend Modules)
| โมดูล | ที่ตั้งโค้ด (`apps/server/src/`) | หน้าที่หลัก |
|---|---|---|
| **AuthModule** | `auth/` | สมัครสมาชิก, เข้าสู่ระบบ, ออก JWT Access Token, ตรวจสอบความถูกต้องของ PIN |
| **UsersModule** | `users/` | จัดการข้อมูลส่วนตัว, ดึงโปรไฟล์, อัปเดตรายได้สุทธิต่อเดือน (`monthly_income`) |
| **SubscriptionsModule** | `subscriptions/` | จัดการ CRUD บริการสมาชิก, กำหนด Usage Status, คำนวณวันต่ออายุรอบถัดไป |
| **PaymentCardsModule** | `payment-cards/` | ผูกบัตรเครดิต/เดบิต, จำลองการดึง Mock Bank Cards เพื่อทำ Auto-import |
| **CreepScoreModule** | `creep-score/` | คำนวณดัชนี Subscription Creep Score พร้อมระดับความเสี่ยง (Safe, Moderate, High) |
| **SavingsModule** | `savings/` | เครื่องมือคำนวณการตัดลดค่าบริการ และบันทึกประวัติการยกเลิก (`SavingsCancellationLog`) |
| **NotificationsModule** | `notifications/` | แจ้งเตือนรอบบิลใกล้ถึงกำหนด, แจ้งเตือนบริการที่ไม่ได้ใช้งาน (Unused Subscriptions) |
| **AdminPackagesModule** | `admin/packages/` | จัดการแคตตาล็อกเทมเพลตบริการส่วนกลาง (Subscription Presets) สำหรับผู้ดูแลระบบ |
| **CacheModule** | `cache/` | จัดการ Caching ทั่วทั้งระบบด้วย Redis (ioredis) พร้อม In-Memory Fallback สำหรับ Auth, Analytics, และ Packages |
| **PrismaModule** | `prisma/` | Singleton Client สำหรับเชื่อมต่อและทำ Transaction ฐานข้อมูล PostgreSQL |

### ⚡ สถาปัตยกรรมระบบแคช (Multi-Tier Caching Architecture)
ระบบใช้กลยุทธ์ **Cache-Aside Pattern** และ **Event-Driven Cache Invalidation** ผ่าน `CacheService` เชื่อมต่อ Redis 7 (พร้อม In-Memory Fallback อัตโนมัติเมื่อรันแบบ Isolated/Unit Test):
1. **Security Auth Cache (`auth:user:{userId}`):**
   - แคช Minimal Safe User Payload (`{ id, email, name }`) ใน `JwtStrategy` (ไม่เก็บ Password หรือ PIN Hash)
   - **TTL:** 180 วินาที (3 นาที) ช่วยลด DB Roundtrip จาก 5-15ms เหลือ 0.2ms ต่อทุก Authenticated Request
   - **Invalidation:** ลบแคชทันทีเมื่อมีการเปลี่ยน PIN (`UsersService.changePin`) หรืออัปเดตโปรไฟล์
   - **Security Guarantee:** การตรวจ Security PIN 6 หลัก (`verifyPin`) ตรวจสอบกับฐานข้อมูลสดเสมอโดยไม่ผ่านแคช
2. **Creep Score & Analytics Cache (`cache:user:{userId}:creep-score`):**
   - แคชผลลัพธ์การคำนวณและสัดส่วนค่าใช้จ่ายต่อเดือนใน `CreepScoreService`
   - **TTL:** 900 วินาที (15 นาที) เร่งความเร็วการเปิดหน้าแรกและ Dashboard แบบ Instant
   - **Invalidation:** ลบแคชทันทีเมื่อเพิ่ม/แก้/ลบ Subscription, อัปเดตรายได้ (`monthly_income`), จัดการบัตร, หรือทำ Batch Cancel
3. **Preset Packages Catalog Cache (`cache:packages:*` & `cache:subscriptions:presets`):**
   - แคชรายการแพ็กเกจบริการสำเร็จรูปส่วนกลาง (Netflix, Spotify, iCloud ฯลฯ)
   - **TTL:** 86,400 วินาที (24 ชั่วโมง)

4. **Kubernetes Shared Cache & Worker Queue Protection (`volatile-lru` & Zero-Cost):**
   - ภายในคลัสเตอร์ Kubernetes (AKS / Zero-Cost Self-Hosted) อินสแตนซ์ Redis ให้บริการแบบ Centralized Cache ให้กับทุก Pod Replicas ของ `subtracker-api` และทำหน้าที่เป็น Message Broker ให้กับ BullMQ (`subtracker-worker`)
   - **Eviction Policy Tuning (`volatile-lru`):** กำหนดผ่าน `k8s/redis-configmap.yaml` (`maxmemory 256mb`) เพื่อการันตีความปลอดภัยของคิวงาน Background Workers (คีย์ที่ไม่มีการตั้ง TTL จะไม่ถูกลบเด็ดขาด) และยินยอมให้ลบเฉพาะแคชที่มี TTL เมื่อหน่วยความจำแตะขีดจำกัด
   - **Zero-Trust Ingress Security:** ปรับแต่ง `k8s/network-policy.yaml` ให้เปิดรับเฉพาะพ็อด `subtracker-api` และ `subtracker-worker` สู่ Redis (TCP 6379) ป้องกันการเชื่อมต่อที่ไม่ได้รับอนุญาตภายใต้โหมด Default Deny
   - **Zero-Cost Mandate Compliance (Rule 9):** อาศัย Containerized Redis ภายในคลัสเตอร์โดยไม่มีค่าใช้จ่ายคลาวด์รายเดือนจาก PaaS (เช่น Azure Cache for Redis) คงต้นทุน $0 Out-of-pocket

### โครงสร้างโมเดลฐานข้อมูล (Prisma Schema Entities)
- `User`: บัญชีผู้ใช้งาน, รหัสผ่านแฮช, PIN แฮช, รายได้รายเดือน
- `PaymentCard`: บัตรการชำระเงินที่ผู้ใช้ผูกไว้ (Debit / Credit, Balance, ยี่ห้อบัตร)
- `SubscriptionPreset`: แคตตาล็อกบริการสำเร็จรูป (Netflix, Spotify ฯลฯ)
- `MockBankCard` & `MockBankCardSubscription`: ข้อมูลจำลองสำหรับทดสอบระบบ Auto-import จากธนาคาร
- `UserSubscription`: ข้อมูลบริการที่ผู้ใช้สมัครใช้งานจริง (ราคา, รอบบิล, วันต่ออายุ, สถานะการใช้งาน)
- `SavingsCancellationLog`: บันทึกประวัติการยกเลิกบริการและยอดเงินที่ประหยัดได้
- `Notification`: ข้อมูลการแจ้งเตือนต่างๆ ของผู้ใช้

---

## 🐳 ส่วนที่ 3: Deploy, Infrastructure & DevOps Lifecycle

ระบบใช้แนวคิด **Continuous Delivery & End-to-End DevSecOps** ครอบคลุมวงจรชีวิตการส่งมอบซอฟต์แวร์ 8 ขั้นตอนต่อเนื่อง (8 Sequential Phases):
$$\text{1. Plan} \rightarrow \text{2. Code} \rightarrow \text{3. Build} \rightarrow \text{4. Test} \rightarrow \text{5. Release} \rightarrow \text{6. Deploy} \rightarrow \text{7. Operate} \rightarrow \text{8. Monitor}$$

### 🧭 ผังวงจรชีวิต DevOps & DevSecOps Architecture (8 Phases & Layered Toolchain)

```mermaid
flowchart LR
    %% Class Definitions
    classDef phase fill:#eceff1,stroke:#455a64,stroke-width:2px,color:#263238,font-weight:bold;
    classDef cicd fill:#e8eaf6,stroke:#3f51b5,stroke-width:2px,color:#1a237e,font-weight:bold;
    classDef mobile fill:#e1f5fe,stroke:#0288d1,stroke-width:2px,color:#01579b;
    classDef cloud fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px,color:#1b5e20;
    classDef sec fill:#ffebee,stroke:#c62828,stroke-width:2px,color:#b71c1c,font-weight:bold;

    %% 8 Sequential Phases
    subgraph Phases["⏱️ 8 SEQUENTIAL DEVOPS PHASES"]
        P1["1. Plan"]:::phase --> P2["2. Code"]:::phase --> P3["3. Build"]:::phase --> P4["4. Test"]:::phase --> P5["5. Release"]:::phase --> P6["6. Deploy"]:::phase --> P7["7. Operate"]:::phase --> P8["8. Monitor"]:::phase
    end

    %% CI/CD Orchestration Layer
    subgraph CI_CD["⚙️ CI/CD ORCHESTRATION LAYER"]
        Jenkins["🛠️ Jenkins CI/CD Automation Engine<br/>(Continuous coverage across: Build ➔ Test ➔ Release ➔ Deploy)"]:::cicd
    end

    %% Mobile Delivery Track
    subgraph MobileTrack["📱 MOBILE DELIVERY TRACK"]
        direction LR
        MobBuildTest["Flutter SDK & Native Test<br/>[Build & Test]"]:::mobile
        Fastlane["Fastlane Pipeline<br/>[Release & Deploy]"]:::mobile
        AppStores["🏪 Apple App Store & Google Play Store<br/>[Production Distribution]"]:::mobile
        MobBuildTest --> Fastlane --> AppStores
    end

    %% Cloud Deployment & Runtime Layer
    subgraph CloudLayer["☁️ CLOUD DEPLOYMENT & RUNTIME LAYER"]
        direction LR
        TestCloud["Vitest, Playwright & Docker Compose<br/>[Test]"]:::cloud
        GHCR["GHCR (GitHub Container Registry)<br/>[Release]"]:::cloud
        ArgoCD["ArgoCD GitOps Sync<br/>[Deploy]"]:::cloud
        K8s["Kubernetes Clusters, Traefik Ingress & Terraform<br/>[Operate]"]:::cloud
        Monitoring["Prometheus, Grafana, Loki & Sentry<br/>[Monitor]"]:::cloud
        TestCloud --> GHCR --> ArgoCD --> K8s --> Monitoring
    end

    %% Cross-Cutting Security Layer
    subgraph SecurityLayer["🛡️ CROSS-CUTTING DEVSECOPS SECURITY LAYER"]
        direction LR
        SecPlan["🛡️ OWASP Threat Dragon<br/>(Threat Modeling) [Plan]"]:::sec
        SecCode["🛡️ Gitleaks (Secret Detection) [Code]"]:::sec
        SecSemgrep["🛡️ Semgrep SAST<br/>(Continuous: Code & Build)"]:::sec
        SecAudit["🛡️ pnpm audit<br/>(Dependency Check) [Build]"]:::sec
        SecTest["🛡️ OWASP ZAP (DAST) & MobSF (Mobile SAST/DAST) [Test]"]:::sec
        SecRelease["🛡️ Syft SBOM (Software Bill of Materials) [Release]"]:::sec
        SecBuildDeploy["🛡️ Trivy (Container & IaC Scan) & Ansible Vault [Build & Deploy]"]:::sec
        SecWazuh["🛡️ Wazuh Unified SIEM Platform<br/>(Host/K8s Security & Log Analysis: Operate & Monitor)"]:::sec
    end

    %% Linkages
    P3 -.-> Jenkins
    Jenkins -.-> MobBuildTest
    Jenkins -.-> TestCloud
    ArgoCD -.-> K8s
```

### 📋 สรุปความรับผิดชอบของแต่ละ Layer และเครื่องมือ
1. **CI/CD Orchestration Layer:**
   - **`Jenkins`**: รับหน้าที่เป็นแกนกลางออร์เคสเตรชันอัตโนมัติต่อเนื่องยาว 4 เฟส ตั้งแต่ **Build ➔ Test ➔ Release ➔ Deploy**
2. **Mobile Delivery Track:**
   - **`Flutter SDK & Test`**: คอมไพล์และทดสอบ Unit/Widget Test ในเฟส **Build & Test**
   - **`Fastlane`**: จัดการเรื่อง Code Signing, Version Bump, Build Artifacts ครอบคลุม **Release & Deploy**
   - **`App Stores`**: ส่งมอบไฟล์ `.ipa` และ `.aab` เข้าสู่ **Apple App Store & Google Play Store** โดยตรง
3. **Cloud Deployment & Runtime Layer:**
   - **`Vitest, Playwright & Docker Compose`** *(Test)*: ทดสอบ Backend Unit/Integration Tests และ E2E Web Tests บนสภาพแวดล้อม Compose
   - **`GHCR (GitHub Container Registry)`** *(Release)*: จัดเก็บและกำหนดเวอร์ชัน Docker Image แท็ก Production
   - **`ArgoCD`** *(Deploy)*: ทำ Declarative GitOps ดึง Manifest จาก Git เพื่อ Deploy สู่ Production แบบ Automated Sync
   - **`Kubernetes Clusters, Traefik & Terraform`** *(Operate)*: คลัสเตอร์รันแอปพลิเคชัน, Traefik ทำหน้าที่เป็น Modern Ingress Controller/Reverse Proxy และจัดการ Cloud Infrastructure ด้วย Terraform
   - **`Prometheus, Grafana, Loki & Sentry`** *(Monitor)*: สังเกตการณ์ระบบแบบ Full Observability (Metrics: Prometheus/Grafana, Logs: Loki, Application Error Tracking: Sentry)
4. **Cross-Cutting Security Layer (DevSecOps):**
   - **`OWASP Threat Dragon`** *(Plan)*: ออกแบบและวิเคราะห์โมเดลภัยคุกคามตั้งแต่ขั้นวางแผน
   - **`Gitleaks`** *(Code)*: ตรวจจับและป้องกัน Secret/Token/Private Key หลุดเข้า Git Repository
   - **`Semgrep`** *(Code & Build)*: ทำ Static Application Security Testing (SAST) วิเคราะห์ช่องโหว่ซอร์สโค้ดแบบครอบคลุมต่อเนื่อง
   - **`pnpm audit`** *(Build)*: สแกนช่องโหว่ของ Dependencies (CVE Audit) ฝั่ง Node.js/Backend
   - **`OWASP ZAP & MobSF`** *(Test)*: ทำ DAST สแกน Web API Security (ZAP) และตรวจจับความปลอดภัยของ Mobile App Binary (MobSF)
   - **`Syft SBOM`** *(Release)*: สร้าง Software Bill of Materials (SBOM) ตรวจสอบความโปร่งใสของแพ็กเกจก่อนเผยแพร่
   - **`Trivy & Ansible Vault`** *(Build & Deploy)*: สแกน Container Image & IaC Misconfigurations (Trivy) ร่วมกับการเข้ารหัสลับค่าคอนฟิก (Ansible Vault)
   - **`Wazuh`** *(Operate & Monitor)*: แพลตฟอร์มความมั่นคงปลอดภัยแบบรวมศูนย์ (XDR & SIEM) ตรวจจับการบุกรุกของ Host/Container ใน Operate และวิเคราะห์ Log Security ใน Monitor

---

## 🛠️ 4. สรุปเครื่องมือและไลบรารีทั้งหมด (Tooling & Library Matrix)

### 📱 ฝั่ง Mobile (Flutter / Dart)
| กลุ่ม | เครื่องมือ / ไลบรารี | ประโยชน์และความสำคัญ |
|---|---|---|
| **Runtime & SDK** | Flutter 3.x (Stable), Dart 3.x | เฟรมเวิร์กสร้าง Cross-platform Client |
| **Version Manager** | **FVM (Flutter Version Management)** | ล็อกเวอร์ชัน Flutter SDK ให้ตรงกันทั้งทีมผ่านไฟล์ `.fvmrc` |
| **State Management** | `flutter_riverpod` (^3.3.2), `riverpod_annotation` (^4.0.3) | จัดการ Application State และ Dependency Injection |
| **Routing** | `go_router` (^14.2.0) | ระบบนำทางแบบ Declarative URL-based Routing |
| **Data & Code Gen** | `freezed`, `freezed_annotation`, `json_serializable`, `build_runner` | สร้าง Data Class แบบ Immutable และแปลง JSON อัตโนมัติ |
| **Functional Tools** | `fpdart` (^1.1.1) | การจัดการผลลัพธ์และข้อผิดพลาดสไตล์ Functional (`Either`, `Option`) |
| **UI & Assets** | `flutter_launcher_icons`, `flutter_native_splash` | จัดการ Splash Screen และ App Icons ตามมาตรฐานระบบปฏิบัติการ |
| **In-App Update** | `AppUpdateController`, `AppUpdateDialog` | ตรวจสอบเวอร์ชันผ่าน Remote Manifest บน Azure Blob รองรับทั้ง Optional และ Force Update |
| **Testing & Quality** | `flutter_test`, `flutter_lints` (^5.0.0), `logger` (^2.5.0) | ทดสอบ Widget/Unit tests และตรวจจับโค้ดตามมาตรฐาน Linter |

### 🖥️ ฝั่ง Backend (NestJS / TypeScript)
| กลุ่ม | เครื่องมือ / ไลบรารี | ประโยชน์และความสำคัญ |
|---|---|---|
| **Core Framework** | NestJS 12, `@nestjs/common`, `@nestjs/core`, `@nestjs/platform-express` | โครงสร้างสถาปัตยกรรมระดับองค์กร (Modular Monolith) |
| **Runtime & Language** | Node.js (22-24 LTS), TypeScript (~6.0) | ภาษาและสภาพแวดล้อมรันเซิร์ฟเวอร์ความเร็วสูง |
| **Package Manager** | **pnpm** (10.2.1) + Corepack | ตัวจัดการแพ็กเกจที่รวดเร็วและประหยัดเนื้อที่ Disk |
| **Database & ORM** | **Prisma ORM** (^6.4.1), `@prisma/client` | การเชื่อมต่อฐานข้อมูล Type-safe Data Access และ Migration |
| **Caching Engine** | **ioredis** (^5.9.1), Redis 7 | ไคลเอนต์และตัวจัดการ Distributed Caching ประสิทธิภาพสูง รองรับ TTL และ Invalidation |
| **Authentication** | `@nestjs/jwt`, `@nestjs/passport`, `passport`, `passport-jwt`, `bcrypt`, `bcryptjs` | ระบบยืนยันตัวตนด้วย Access Token, การเข้ารหัส Password & PIN |
| **Validation** | `class-validator`, `class-transformer`, `zod` | ตรวจสอบ Data Transfer Object (DTO) และ Environment Variables |
| **API Docs** | `@nestjs/swagger` (^12.0.1) | สร้าง Swagger UI และ OpenAPI 3.0 Documentation อัตโนมัติ |
| **Testing & Quality** | **Vitest** (5.0.1), `@vitest/coverage-v8`, ESLint, Prettier | รัน Unit Tests ความเร็วสูง และตรวจสอบ Format มาตรฐานโค้ด |

### 🐳 ฝั่ง Deploy, Infrastructure & DevSecOps
| กลุ่ม / เลเยอร์ | เครื่องมือ / ไลบรารี | เฟสที่ใช้งาน | ประโยชน์และความสำคัญ |
|---|---|---|---|
| **CI/CD Orchestration** | **Jenkins** | Build, Test, Release, Deploy | เครื่องมือ Pipeline Orchestrator ควบคุมการสร้าง ทดสอบ และส่งมอบระบบอัตโนมัติ |
| **Mobile Runner** | **Flutter & Android SDK Container** | Build, Test | Docker Agent (`cirruslabs/flutter:stable`) รัน Flutter/Android Build พร้อมแคช |
| **Mobile Delivery** | **Flutter SDK & Test** | Build, Test | คอมไพล์และทดสอบโค้ดแอปพลิเคชันมือถือ (`flutter test --coverage`) |
| **Mobile Delivery** | **Fastlane & Azure Blob** | Release, Deploy | คอมไพล์ Signed Release APK, ตรวจสอบลายเซ็น และส่งมอบผ่าน Azure Blob Storage |
| **Testing & Verification** | **Vitest, Playwright, Docker Compose, k6** | Test | ชุดทดสอบ Unit/Integration API, E2E UI, และ Performance/Load Testing ด้วย k6 จำลองพฤติกรรมผู้ใช้และทดสอบเพดานระบบ |
| **Container Registry** | **GHCR** (GitHub Container Registry) | Release | คลังจัดเก็บ Production Docker Images อย่างปลอดภัย |
| **GitOps Delivery** | **ArgoCD** | Deploy | ตรวจจับการเปลี่ยนแปลงของ Manifest และ Sync ขึ้น K8s อัตโนมัติ |
| **Cloud Runtime & IaC** | **Kubernetes, Traefik, Terraform** | Operate | คลัสเตอร์จัดการ Container, Ingress Routing และเครื่องมือจัดการ Cloud Infra แบบโค้ด |
| **Database Engine** | **PostgreSQL 16 Alpine** | Operate | ฐานข้อมูลหลักของระบบ พร้อมระบบสำรองและ Persistent Volume |
| **Monitoring & Observability** | **Prometheus, Grafana, Loki, Sentry** | Monitor | ระบบมอนิเตอร์ระดับองค์กร (Metrics, Dashboards, Log Aggregation, Error Tracking) |
| **Threat Modeling** | **OWASP Threat Dragon** | Plan | ออกแบบและประเมินความเสี่ยงภัยคุกคามสถาปัตยกรรมระบบ |
| **Secret Detection** | **Gitleaks** | Code | สแกนป้องกัน Secret, Token, และ Private Key หลุดสู่ซอร์สโค้ด |
| **SAST** | **Semgrep** | Code, Build | สแกนช่องโหว่ความปลอดภัยระดับ Source Code เชิงลึกแบบต่อเนื่อง |
| **Dependency Audit** | **pnpm audit** | Build | ตรวจสอบช่องโหว่ Known Vulnerabilities ของไลบรารีภายนอก |
| **DAST & Mobile Sec** | **OWASP ZAP & MobSF** | Test | ทดสอบเจาะระบบ Web API แบบ Dynamic และสแกนช่องโหว่ไฟล์ Mobile App |
| **Software Supply Chain** | **Syft SBOM** | Release | สร้างเอกสารแสดงรายการส่วนประกอบซอฟต์แวร์ทั้งหมด (Software Bill of Materials) |
| **Image/IaC Scan & Secrets** | **Trivy & Ansible Vault** | Build, Deploy | สแกนช่องโหว่ Docker Image & IaC Code ร่วมกับการเข้ารหัส Sensitive Config |
| **XDR / SIEM Platform** | **Wazuh** | Operate, Monitor | แพลตฟอร์มตรวจจับและตอบสนองภัยคุกคามระดับ Host/Container และวิเคราะห์ Log |

---

## 🚀 5. คำสั่งการทำงานสำหรับนักพัฒนาและ AI Agent (Cheat Sheet)

### การรัน Backend + Database (Docker Compose)
```bash
# 1. คัดลอก Environment file สำหรับ Server
cp apps/server/.env.example apps/server/.env

# 2. เริ่มต้น Container สำหรับ API และ PostgreSQL
docker compose --env-file apps/server/.env up --build

# Swagger UI จะพร้อมใช้งานที่: http://localhost:8080/docs
# PostgreSQL Database พร้อมเชื่อมต่อที่: localhost:5432
```

### การตรวจสอบคุณภาพ Backend (Verification)
```bash
cd apps/server
pnpm install
pnpm verify      # ตรวจสอบ Build, Vitest Tests, ESLint, Prettier, และ Security Audit
```

### การรัน Frontend (Flutter Mobile / Web)
> **หมายเหตุ:** แนะนำเปิด Terminal แยกจาก Docker เพื่อความสะดวกในการใช้ Interactive Hot-reload
```bash
cd apps/mobile

# 1. ตั้งค่าและดึง Dependencies ด้วย FVM
fvm use stable --force
fvm flutter pub get

# 2. ตรวจสอบคุณภาพโค้ดและชุดทดสอบ
fvm dart analyze
fvm flutter test

# 3. สั่งรันบน Web Browser หรือ Device
fvm flutter run -d chrome
# หรือรันผ่าน Web Server:
fvm flutter run -d web-server --web-port 8080
```

---

## 📝 6. บันทึกประวัติและการเปลี่ยนแปลงสถาปัตยกรรม (Architecture & System Changelog)

| วันที่ | ขอบเขตการเปลี่ยนแปลง | รายละเอียด |
|---|---|---|
| **2026-10-02** | **Project Documentation & Agent Rules Cleanup** | ลบโฟลเดอร์ `/doc` ภายในโปรเจกต์ และยุบขอบเขต Agent ให้คงเหลือเพียง `agent.md` เป็นกฎหลัก พร้อมเพิ่มลงใน `.gitignore` โดยรวมศูนย์เอกสารภาพรวมระบบทั้งหมดมาไว้ที่ `SYSTEM_OVERVIEW.md` ฉบับนี้เพียงจุดเดียว ซึ่ง AI Agent จะต้องเข้ามาอัปเดตและอธิบายรายละเอียดทุกครั้งหลังปฏิบัติงานเสร็จสิ้นตาม Rule 6 |
| **2026-10-03** | **EPICDP 0, 1 & 4 Implementation & Verification** | ผสานรวมระบบ EPICDP 0, 1, 4 บน Branch `EPICDP-0,1-and-4`: เพิ่ม Docker Compose 5-service stack, Kubernetes StatefulSets/CronJob, Ansible Vault templates, และ Jenkins DevSecOps ครบทั้ง SAST (Semgrep/Gitleaks), SCA (pnpm audit), Test Orchestration (tmpfs postgres), Multi-arch Buildx, Trivy, Syft SBOM, DAST (OWASP ZAP) และ ArgoCD GitOps พร้อมแก้ไขปัญหา Local verification: ปรับ `start_period: 60s`, ติดตั้งและเปิดใช้งาน Gitleaks pre-commit บนเครื่อง, และติดตั้ง host dependencies ผ่านการทดสอบ Vitest 187/187 tests |
| **2026-10-03** | **Cloud Provider Migration to Microsoft Azure (Rule 8 Mandate)** | ปรับเปลี่ยนระบบคลาวด์และโครงสร้างพื้นฐานทั้งหมดจาก AWS สู่ Microsoft Azure: ย้ายฐานสำรองข้อมูลและ DR (DP-103) จาก AWS S3 มาเป็น Azure Blob Storage ด้วย AzCopy/Azure CLI, ปรับโครงสร้างความลับ Ansible Vault & Template (DP-102) เป็น `backup-azure-secret`, กำหนด StorageClass สำหรับ StatefulSet บน AKS เป็น `managed-csi`, และอัปเดต Terraform Provider เป็น `hashicorp/azurerm` |
| **2026-10-04** | **Distributed Caching Layer & Cross-Service Eviction Suite** | ติดตั้ง `CacheModule` / `CacheService` ด้วย Redis 7 + `ioredis` พร้อม In-Memory Graceful Fallback รองรับ 3 จุดสำคัญ: 1) Auth User Identity (`auth:user:{id}`, TTL 180s) 2) Creep Score Analytics (`cache:user:{id}:creep-score`, TTL 900s) 3) Catalog Presets (`cache:packages:*`, TTL 24h) พร้อมเพิ่ม Unit Test Assertion ยืนยันการทำ Event-driven Cross-Service Eviction บน `SubscriptionsService` และ `UsersService` ผ่านการทดสอบ Vitest ครบ 276/276 tests |
| **2026-10-04** | **k6 Realistic & Ceiling Stress Load Testing Suite** | พัฒนาชุดทดสอบโหลด `scripts/k6/load-test.js` และ `scripts/k6/run-k6.ps1` จำลองพฤติกรรมผู้ใช้จริง (Browse Catalog, Batch Dashboard 5-endpoint fetch, Savings Optimizer, และ Subscription Mutation triggering Eviction) พร้อมโหมด Ceiling Stress ไต่ระดับ 0 ➔ 500 VUs แบบลด Think Time เพื่อค้นหาคอขวด Event Loop, DB Connection Pool, และวัดประสิทธิภาพการบรรเทาภาระของ Redis Cache |
| **2026-10-06** | **Kubernetes Zero-Cost Caching & Worker Architecture ($0 Mandate - Rule 9)** | ออกแบบและปรับปรุงคอนฟิก Kubernetes สำหรับระบบ Caching และ Background Worker ให้ปลอดภัย เชื่อถือได้ และไร้ต้นทุน ($0 Out-of-pocket): 1) ปรับ Redis Eviction Policy ใน `k8s/redis-configmap.yaml` เป็น `volatile-lru` ป้องกันไม่ให้ BullMQ Queue Keys (Renewal Reminder Discovery) ถูก Evict ทิ้ง 2) อัปเดต `k8s/network-policy.yaml` ให้ Whitelist พ็อด `subtracker-worker` เข้าถึง Redis พอร์ต 6379 3) สร้าง Kubernetes Deployment & Service Manifests (`k8s/api-deployment.yaml`) รองรับ HPA Auto-scaling ร่วมกับ StatefulSet Redis 4) ทดสอบตรวจสอบ YAML Syntax และรัน Vitest Suite ผ่านครบถ้วน 276/276 tests |
| **2026-10-06** | **EPICDP 6: Mobile Integration & Direct APK Sideloading Delivery Suite (DP-600 to DP-605)** | ปรับเปลี่ยนยุทธศาสตร์การส่งมอบแอปพลิเคชันมือถือจาก App Store สู่การติดตั้งโดยตรง (Direct APK Sideloading) พร้อมระบบ In-App Update: 1) **DP-600**: ออกแบบ Jenkins Mobile Runner (`Jenkinsfile.mobile`) บน Container `ghcr.io/cirruslabs/flutter:stable` พร้อม Docker volumes สำหรับ `.pub-cache` และ `.gradle` 2) **DP-601**: สร้าง Quality Gate อัตโนมัติ (`flutter analyze` และ `flutter test --coverage`) ผ่านการทดสอบ 61/61 tests 3) **DP-602**: บูรณาการเครื่องมือ Static Security Testing สำหรับ Mobile Binary ด้วย MobSF API (`scripts/cicd/mobsf-scan.sh`) 4) **DP-603**: กำหนด Schema จัดเก็บ Keystore และ Signing Credentials ด้วย Ansible Vault (`vault.example.yml`) ร่วมกับ Gradle Signing Config 5) **DP-604**: พัฒนาระบบ In-App Version Checker & Force Update บน Flutter Client (`AppUpdateController`, `AppUpdateDialog`) ตรวจสอบเวอร์ชันผ่าน Remote Manifest 6) **DP-605**: คอนฟิก Fastlane Lane (`Fastfile`) สำหรับการคอมไพล์ Signed Release APK, ตรวจสอบลายเซ็นใบรับรอง และส่งมอบขึ้น Microsoft Azure Blob Storage พร้อม Manifest `version.json` |
| **2026-10-06** | **Backend Dependency Resolution, Security Overrides & Pipeline Verification** | แก้ไขปัญหา Dependency ใน `apps/server`: ติดตั้งแพ็กเกจ `google-auth-library` ในเครื่อง, กำหนด pnpm overrides สำหรับ `proxy-addr` (>=2.0.8), `source-map-js` (>=1.2.2), และ `fast-uri` (>=3.1.8) เพื่อปิดช่องโหว่ความปลอดภัยระดับ Critical/High, ปรับ `check:security` ให้ใช้นโยบาย `--audit-level=high` สอดคล้องกับ `Jenkinsfile` (DP-402), จัดฟอร์แมต Prettier และทดสอบผ่าน `pnpm verify` สำเร็จ 100% (307/307 Vitest tests passing) |



