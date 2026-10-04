# 📱 Subscription Track (Full-Stack Monorepo)

[![Flutter](https://img.shields.io/badge/Flutter-3.47.4_Stable-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13.3-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Riverpod](https://img.shields.io/badge/State_Management-Riverpod_3-black)](https://riverpod.dev)
[![FVM](https://img.shields.io/badge/Version_Management-FVM-4.3.1-58CDFA)](https://fvm.app)
![Architecture](https://img.shields.io/badge/Architecture-Feature--First_Clean_Arch-brightgreen)
[![Status](https://img.shields.io/badge/Frontend_MVP-43%2F43_Tests_Passing-success)](apps/mobile)

ระบบตรวจจับและประเมินค่าบริการสมาชิกรายเดือน/รายปี (Subscription Tracker & Analytics System) ที่มาพร้อมกับระบบคำนวณ **Subscription Creep Score** เพื่อประเมินความเสี่ยงทางการเงินจากการสมัครบริการซ้ำซ้อนหรือไม่ได้ใช้งาน พร้อมทั้งระบบจำลองการประหยัดค่าใช้จ่าย (Savings Simulation)

โครงสร้างโปรเจกต์จัดระเบียบในรูปแบบ **Apps & Infra Monorepo** ตามมาตรฐาน `$clean-code` เพื่อรองรับทั้ง Mobile Client, Backend API, และ Cloud Infrastructure อย่างเป็นสัดส่วน

---

## 🏛️ สถาปัตยกรรมโปรเจกต์ (Repository Architecture)

```text
subscription_track/
├── apps/
│   ├── mobile/          # แอปพลิเคชันมือถือ (Flutter 3.47.4, Riverpod, Feature-First Architecture)
│   └── server/          # ขอบเขตระบบ Backend (NestJS Modular Monolith)
│
├── infra/               # ขอบเขตการตั้งค่า Infrastructure & DevOps
│   ├── nginx/           # Nginx Reverse Proxy
│   ├── postgres/        # PostgreSQL Database
│   ├── redis/           # Redis Cache & BullMQ Queue
│   └── monitoring/      # Prometheus / Grafana
│
├── scripts/             # สคริปต์อัตโนมัติสำหรับการพัฒนาและทดสอบระดับ Monorepo
│
├── agent.md             # กฎและแนวทางการทำงานร่วมกับ AI Agent
├── SYSTEM_OVERVIEW.md   # ภาพรวมสถาปัตยกรรมและรายละเอียดทางเทคนิคของระบบ
├── .github/             # GitHub Actions CI/CD Workflows
└── .gitignore           # กฎการละเว้นไฟล์ระดับ Full-Stack Monorepo
```

---

## 📱 Mobile Application (`apps/mobile/`)

แอปพลิเคชันมือถือพัฒนาด้วย **Flutter (Stable)** พร้อมระบบจัดการสถานะ **Riverpod** โดยใช้สถาปัตยกรรม **Feature-First Clean Architecture** ที่แยกเลเยอร์ `domain`, `data`, `application`, และ `presentation` อย่างเคร่งครัด

### ✨ ฟีเจอร์หลักในระบบ (Features):
- 📊 **Dashboard สรุปยอดค่าใช้จ่าย:** สรุปยอดจ่ายออกทั้งหมดต่อเดือน/ต่อปีแบบเรียลไทม์ และไทม์ไลน์รอบบิลถัดไป
- ⚠️ **Subscription Creep Score:** อัลกอริทึมประเมินสัดส่วนค่าบริการเทียบกับรายได้ พร้อมระบุระดับความเสี่ยงทางการเงิน (Safe / Moderate / High Risk)
- 💰 **ระบบจำลองการประหยัด (Savings Simulation):** ติ๊กเลือกตัดบริการที่ไม่จำเป็น เพื่อคำนวณยอดเงินที่สามารถประหยัดคืนมาได้ต่อเดือนและต่อปี
- 📦 **Preset Packages:** คลังรวมแพ็กเกจพรีเซ็ตยอดนิยมในไทยกว่า 10 บริการ (Netflix, Spotify, YouTube Premium, Disney+, iCloud ฯลฯ)
- 💳 **Linked Accounts & Auto-Import:** จำลองการผูกบัตรเครดิต/เดบิต ตรวจจับบิลเรียกเก็บซ้ำซ้อน และซิงก์ยอดคงเหลือสะท้อนรายได้สุทธิ
- 🔐 **Security PIN:** ระบบรักษาความปลอดภัยด้วย PIN 6 หลัก พร้อมระบบยืนยันก่อนทำรายการแก้ไขหรือยกเลิกบริการ
- 🖥️ **Responsive & Adaptive Shell:** รองรับทั้งหน้าจอมือถือ (Bottom Navigation) และแท็บเล็ต/เดสก์ท็อป (Navigation Rail)

---

### 🚀 การติดตั้งและรัน Mobile Application ด้วย FVM (แนะนำ)

โปรเจกต์นี้ใช้ **[FVM (Flutter Version Management)](https://fvm.app)** ในการควบคุมเวอร์ชัน Flutter ให้อยู่ที่ **Stable Channel** (ระบุไว้ใน [`apps/mobile/.fvmrc`](apps/mobile/.fvmrc))

#### 1. ติดตั้ง FVM (หากยังไม่มีในเครื่อง):
```bash
# บน Linux/macOS
curl -sL https://github.com/leoafarias/fvm/releases/download/4.3.1/fvm-4.3.1-linux-x64.tar.gz -o /tmp/fvm.tar.gz
mkdir -p ~/.local/share && tar -xzf /tmp/fvm.tar.gz -C ~/.local/share
ln -sf ~/.local/share/fvm/fvm ~/.local/bin/fvm
rm /tmp/fvm.tar.gz
```

#### 2. ตั้งค่าเวอร์ชัน Flutter ให้โปรเจกต์:
```bash
cd apps/mobile
fvm use stable --force
```

#### 3. ดาวน์โหลด Dependencies:
```bash
fvm flutter pub get
```

#### 4. ตรวจสอบคุณภาพโค้ด (Static Analysis):
```bash
fvm dart analyze
# ผลลัพธ์: No issues found! (0 warnings, 0 errors)
```

#### 5. รัน Unit & Widget Tests:
```bash
fvm flutter test
# ผลลัพธ์: All 43 tests passed!
```

#### 6. สั่งรันแอปพลิเคชัน (Launch Web / Desktop / Device):

> [!TIP]
> **การพัฒนาแบบ Full-Stack (แยก Terminal):**
> Frontend (Flutter) ทำงานบนเครื่อง Host โดยตรงเพื่อให้เข้าถึงหน้าจอ, GPU, และรับคำสั่ง Interactive Hot Reload ได้ ส่วน Backend (`api`, `postgres`) ทำงานผ่าน Docker Compose **โปรดเปิดแยก Terminal เสมอ** (Terminal 1 สำหรับ Docker Compose, Terminal 2 สำหรับ Flutter)

**วิธีที่ 1: รันผ่านสคริปต์อัตโนมัติ (แนะนำบน Linux):**
```bash
bash ./.private/setup/run_web.sh
```

**วิธีที่ 2: รันผ่าน FVM CLI โดยตรง:**
```bash
cd apps/mobile
fvm flutter run -d web-server --web-port 8080
```
เปิดเบราว์เซอร์ไปที่: **[http://localhost:8080](http://localhost:8080)**

**หรือรันผ่าน Chrome โดยตรง:**
```bash
cd apps/mobile
fvm flutter run -d chrome
```

---

## 🖥️ Backend Server (`apps/server/`)

- **สถานะ:** Scaffold ตั้งต้น NestJS Modular Monolith เรียบร้อยแล้ว (พร้อมสำหรับ Phase 1 Foundation & Configuration)
- **สถาปัตยกรรม:** **NestJS Modular Monolith** (`src/main.ts` สำหรับ HTTP API และ `src/worker.ts` สำหรับ Worker boundary)
- **เทคโนโลยีหลัก:** TypeScript, NestJS 12, PostgreSQL 17, TypeORM, Redis, BullMQ

### คำสั่งสำหรับติดตั้งและทดสอบ (`apps/server/`):

ต้องใช้ Node.js 24.15 ขึ้นไป (แนะนำ 24.21 ตาม `apps/server/.nvmrc`) และ pnpm ที่ Corepack จัดการ

```bash
cd apps/server
corepack enable
cp .env.example .env
pnpm install
pnpm start:dev
```

เมื่อ Server ทำงานบนเครื่อง developer โดยตรง ให้ใช้ `DB_HOST=localhost` ตามค่าใน `.env.example`; BE-004 จะกำหนด service DNS เช่น `DB_HOST=postgres` เฉพาะเมื่อ Server และ PostgreSQL ทำงานใน Docker Compose network เดียวกัน

### ตรวจสอบคุณภาพ Backend

หลังติดตั้ง dependencies ให้ใช้คำสั่งเดียวต่อไปนี้จาก `apps/server/`:

```bash
pnpm verify
```

`pnpm verify` รันสองกลุ่มตามลำดับ:

- `pnpm check`: build, test, lint และ format check
- `pnpm check:security`: production และ full dependency audits

การแยก security audit ออกจาก quality checks ช่วยให้แยกปัญหา code ออกจากปัญหา registry/network หรือ vulnerability database ได้ชัดเจนขึ้น

### Docker development environment

Compose เปิดใช้เฉพาะ NestJS API และ PostgreSQL 17 ในระยะนี้ โดย Server ใช้ hot reload จาก source mount และเข้าถึง PostgreSQL ผ่าน service DNS `postgres`:

> [!NOTE]
> **Docker Compose ดูแลเฉพาะ Backend & Database เท่านั้น:**
> `docker-compose.yml` ไม่ได้รวม Flutter ไว้ด้วย เนื่องจาก Flutter ต้องการการเข้าถึง GPU, Window Manager หรือ Web Server บน Host โดยตรง
> ดังนั้น ในการพัฒนาให้เปิด **2 Terminals ควบคู่กัน**:
> - **Terminal 1:** รัน Docker Compose สำหรับ Backend & Database
> - **Terminal 2:** รัน Flutter สำหรับ Mobile / Web Client (ดูหัวข้อ [การติดตั้งและรัน Mobile Application](#-การติดตั้งและรัน-mobile-application-ด้วย-fvm-แนะนำ))

#### ตารางสรุปพอร์ตและบริการขณะรัน Development:

| บริการ (Service) | พอร์ต / URL | ประเภท | รันด้วยคำสั่ง |
|---|---|---|---|
| **Flutter Web** | [http://localhost:8080](http://localhost:8080) | Frontend Client | Host Terminal: `bash ./.private/setup/run_web.sh` |
| **NestJS API** | [http://localhost:3000](http://localhost:3000) | Backend HTTP | Docker Compose: `docker compose up` |
| **Swagger UI** | [http://localhost:3000/docs](http://localhost:3000/docs) | API Docs | รวมอยู่ใน API Container |
| **OpenAPI JSON** | [http://localhost:3000/docs-json](http://localhost:3000/docs-json) | OpenAPI Spec | รวมอยู่ใน API Container |
| **PostgreSQL 17** | `localhost:5432` | Database | Docker Compose: `postgres` service |

```bash
cp apps/server/.env.example apps/server/.env
docker compose --env-file apps/server/.env up --build
```

API รับการเชื่อมต่อที่ `http://localhost:3000` ส่วน PostgreSQL เปิดพอร์ต `5432` สำหรับเครื่องมือบน host; เนื่องจากยังไม่มี Controller การเรียก `/` แล้วได้ `404` ถือว่าปกติและยืนยันว่า API process รับเครือข่ายได้

สำหรับเอกสาร API Documentation (Swagger / OpenAPI):
- **Swagger UI:** [http://localhost:3000/docs](http://localhost:3000/docs)
- **OpenAPI JSON:** [http://localhost:3000/docs-json](http://localhost:3000/docs-json)
*(Swagger UI จะเปิดใช้งานเฉพาะในสภาพแวดล้อม `development` และ `test` โดยจะถูกปิดการทำงานเป็นค่าเริ่มต้นในโหมด `production`)*

หยุด services โดยเก็บข้อมูล PostgreSQL ใน named volume:

```bash
docker compose --env-file apps/server/.env down
```

ใช้ `docker compose --env-file apps/server/.env down -v` เฉพาะเมื่อต้องการลบ development database data โดยตั้งใจ Redis, Worker และ Nginx เปิดใช้งานแล้วใน `docker-compose.yml` (Nginx reverse proxy ฟัง `http://localhost:3000` → `api:8080`) ดูวิธี deploy ขึ้น production VM ได้ที่หัวข้อ [🏭 Production Deployment (VM)](#-production-deployment-vm) ด้านล่าง

---

## 🏗️ Infrastructure & Deployment (`infra/`)

- **สถานะ:** วางขอบเขตโครงสร้าง Infrastructure สำหรับรองรับ Phase 2
- **โฟลเดอร์หลัก:**
  - `infra/nginx/`: การตั้งค่า Nginx Reverse Proxy และ SSL termination
  - `infra/postgres/`: สคริปต์ Schema initialization และ Volume persistence
  - `infra/redis/`: การตั้งค่า Redis Cache และ Queue storage
  - `infra/monitoring/`: การตั้งค่า Prometheus, Grafana และ Health probe endpoints

---

## 🤖 ภาพรวมระบบและคู่มือการทำงาน (System & Agent Reference)
## 🏭 Production Deployment (VM)

สำหรับทดสอบ deploy ขึ้นเครื่อง VM จริง (ไม่ใช่เครื่อง dev) ใช้ไฟล์ `docker-compose-prosuction.yml` ที่ root ของ repo — เป็น production variant ของ `docker-compose.yml` เดิม (service เดียวกัน: `api`, `postgres`, `redis`, `worker`, `nginx`) แต่ปิดช่องโหว่ที่ไม่ควรมีใน production:

- `postgres`/`redis` **ไม่เปิด host port** (เข้าถึงได้เฉพาะในวง Compose network ผ่าน `api`/`worker`)
- **ไม่มี default secret** ฝังในไฟล์ — ทุกค่า secret อ่านจาก `apps/server/.env.production` ผ่าน `env_file:` ถ้าไฟล์นี้ไม่มี `docker compose` จะ error ทันที ไม่ fallback ไปใช้ค่า dev
- `api`/`worker` build จาก Dockerfile target `runtime` (production image, non-root user) ไม่ใช่ `development` ที่ bind-mount source
- Migration แยกเป็น job `migrate` ต่างหาก ไม่รันอัตโนมัติตอน `up` (กัน container หลายตัวรัน migration ซ้ำกัน)

> [!WARNING]
> **ยังไม่มี HTTPS** — `infra/nginx/nginx.conf` ยังเป็น HTTP ล้วน ไฟล์นี้จึงเหมาะสำหรับทดสอบว่า stack รันได้จริงบน VM เท่านั้น **ห้ามเปิดพอร์ตนี้สู่อินเทอร์เน็ตสาธารณะ** จนกว่าจะมี TLS termination (เช่น Let's Encrypt/Certbot หรือ reverse proxy อื่นที่ทำ HTTPS ให้) ซึ่งยังไม่ได้ implement ใน repo นี้

### ขั้นตอน Deploy

**1) Clone repo ขึ้น VM และติดตั้ง Docker + Docker Compose v2** (ถ้ายังไม่มี)

**2) ตั้งค่า secrets** (ไฟล์นี้ gitignore อยู่แล้ว ไม่ถูก commit แน่นอน):
```bash
cp apps/server/.env.production.example apps/server/.env.production
# แก้ไข apps/server/.env.production ด้วยค่าจริง:
# - POSTGRES_DB/USER/PASSWORD ต้องตรงกับ DB_NAME/DB_USER/DB_PASSWORD
# - DATABASE_URL ต้อง sync กับค่าด้านบน
# - JWT_SECRET ต้องสุ่มด้วย CSPRNG อย่างน้อย 32 ตัวอักษร
```

**3) ตรวจสอบว่า compose ไฟล์ถูกต้องและ secrets ครบ:**
```bash
docker compose -f docker-compose-prosuction.yml config
```

**4) รัน database migration ครั้งแรก (ก่อน `up` เสมอ):**
```bash
docker compose -f docker-compose-prosuction.yml run --rm migrate
```

**5) ขึ้นระบบทั้งหมด:**
```bash
docker compose -f docker-compose-prosuction.yml up -d --build
```

**6) ตรวจสอบสถานะและทดสอบ end-to-end:**
```bash
docker compose -f docker-compose-prosuction.yml ps
curl -i http://localhost/health
```
ควรได้ `HTTP/1.1 200 OK` พร้อม `"status":"ok","checks":{"database":"ok"}` ที่ผ่านเส้นทาง Nginx (พอร์ต 80) → `api:8080` → PostgreSQL

**7) หยุดระบบ (เก็บข้อมูลไว้ใน volume):**
```bash
docker compose -f docker-compose-prosuction.yml down
```
ใช้ `down -v` เฉพาะเมื่อต้องการลบข้อมูล PostgreSQL โดยตั้งใจเท่านั้น

> มี production compose อีกไฟล์ที่ `apps/server/docker-compose-prosuction.yml` สำหรับกรณีต้องการ deploy เฉพาะ backend scope แยกจาก root — ใช้ไฟล์ secrets ร่วมกัน (`apps/server/.env.production`) แต่สำหรับการใช้งานทั่วไปแนะนำไฟล์ root ด้านบนเพราะรวม Nginx reverse proxy ไว้ให้แล้ว

---

## 📚 เอกสารอ้างอิงของโปรเจกต์ (Documentation Matrix)

| ข้อมูล / เอกสาร | รายละเอียดและขอบเขตเนื้อหา |
|---|---|
| 🌐 **[System Overview](SYSTEM_OVERVIEW.md)** | เอกสารสรุปภาพรวมทางเทคนิคและสถาปัตยกรรมทั้งระบบ (Frontend, Backend, Deploy & Infra) |
| 📋 **[Agent Instructions & Operational Rules](agent.md)** | กฎระเบียบและแนวทางการทำงานร่วมกับ AI Agent ภายในโปรเจกต์ |

---

## 🌿 กิ่งพัฒนาและระบบ Git (Branching Model)

โปรเจกต์นี้ใช้โมเดลการพัฒนาแบบมาตรฐาน:
- **`main`:** กิ่ง Production / Releases (เสถียร 100% พร้อมทดสอบและ deploy)
- **`develop`:** กิ่งรวบรวมงานพัฒนาหลักของทีม (Feature Integration)

---

## 🤝 ทีมพัฒนา (Core Contributors)
- **Nekokun2004** (`netiwut2004@gmail.com`)
- **Nawaphon Sungthong** (`nawaphonsungthong@gmail.com`)
