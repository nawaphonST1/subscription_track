# 📱 Subscription Track (Full-Stack Monorepo)

[![Flutter](https://img.shields.io/badge/Flutter-3.47.4_Stable-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13.3-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Riverpod](https://img.shields.io/badge/State_Management-Riverpod_3-black)](https://riverpod.dev)
[![FVM](https://img.shields.io/badge/Version_Management-FVM-4.3.1-58CDFA)](https://fvm.app)
[![Architecture](https://img.shields.io/badge/Architecture-Feature--First_Clean_Arch-brightgreen)](doc/architecture/feature_first_architecture.md)
[![Status](https://img.shields.io/badge/Frontend_MVP-43%2F43_Tests_Passing-success)](apps/mobile)

ระบบตรวจจับและประเมินค่าบริการสมาชิกรายเดือน/รายปี (Subscription Tracker & Analytics System) ที่มาพร้อมกับระบบคำนวณ **Subscription Creep Score** เพื่อประเมินความเสี่ยงทางการเงินจากการสมัครบริการซ้ำซ้อนหรือไม่ได้ใช้งาน พร้อมทั้งระบบจำลองการประหยัดค่าใช้จ่าย (Savings Simulation)

โครงสร้างโปรเจกต์จัดระเบียบในรูปแบบ **Apps & Infra Monorepo** ตามมาตรฐาน `$clean-code` เพื่อรองรับทั้ง Mobile Client, Backend API, และ Cloud Infrastructure อย่างเป็นสัดส่วน

---

## 🏛️ สถาปัตยกรรมโปรเจกต์ (Repository Architecture)

```text
subscription_track/
├── apps/
│   ├── mobile/          # แอปพลิเคชันมือถือ (Flutter 3.47.4, Riverpod, Feature-First Architecture)
│   └── api/             # ขอบเขตระบบ Backend API (NestJS Modular Monolith - Phase 2)
│
├── infra/               # ขอบเขตการตั้งค่า Infrastructure & DevOps
│   ├── nginx/           # Nginx Reverse Proxy
│   ├── postgres/        # PostgreSQL Database
│   ├── redis/           # Redis Cache & BullMQ Queue
│   └── monitoring/      # Prometheus / Grafana
│
├── scripts/             # สคริปต์อัตโนมัติสำหรับการพัฒนาและทดสอบระดับ Monorepo
│
├── doc/                 # เอกสารข้อกำหนดระบบ สถาปัตยกรรม และการจัดสรรงาน
│   ├── architecture/    # Feature-First & Riverpod State Management Guides
│   ├── frontend/        # UI Screen Specifications & Component Matrix
│   ├── backend/         # Backend Modular Monolith Specifications (Phase 2)
│   ├── devops/          # Infrastructure & Deployment Specifications (Phase 2)
│   ├── task/            # Developer Task Allocations & Work Breakdown
│   └── Subscription_Track_PRD.md # Product Requirement Document
│
├── .agents/             # Antigravity AI Agent Skills & Repository Knowledge
│   ├── skills/          # clean-code, tree-repo, dart & flutter skills
│   └── tree_repo/       # ผังไฟล์และคำอธิบายสถาปัตยกรรมระดับ Repository
│
├── .github/             # GitHub Actions CI/CD Workflows
├── .gitignore           # กฎการละเว้นไฟล์ระดับ Full-Stack Monorepo
└── skills-lock.json     # Locked configuration for agent skills
```

> 📖 ดูโครงสร้างไฟล์อย่างละเอียดพร้อมคำอธิบายรายไฟล์ได้ที่: **[Repository Tree Overview](.agents/tree_repo/tree_repo.md)**

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

**รันผ่าน Local Web Server (แนะนำบน Linux):**
```bash
fvm flutter run -d web-server --web-port 8080
```
เปิดเบราว์เซอร์ไปที่: **[http://localhost:8080](http://localhost:8080)**

**หรือรันผ่าน Chrome โดยตรง:**
```bash
fvm flutter run -d chrome
```

---

## 🖥️ Backend API (`apps/api/`)

- **สถานะ:** วางขอบเขตโครงสร้างสถาปัตยกรรมพร้อมสำหรับการพัฒนาใน **Phase 2**
- **สถาปัตยกรรม:** **NestJS Modular Monolith**
- **เทคโนโลยีหลัก:** TypeScript, PostgreSQL, TypeORM, Redis (Cache & Session), BullMQ (Background Jobs & Reminder Dispatcher)
- ดูรายละเอียดข้อกำหนดระบบ Backend ได้ที่ [doc/Subscription_Track_PRD.md](doc/Subscription_Track_PRD.md)

---

## 🏗️ Infrastructure & Deployment (`infra/`)

- **สถานะ:** วางขอบเขตโครงสร้าง Infrastructure สำหรับรองรับ Phase 2
- **โฟลเดอร์หลัก:**
  - `infra/nginx/`: การตั้งค่า Nginx Reverse Proxy และ SSL termination
  - `infra/postgres/`: สคริปต์ Schema initialization และ Volume persistence
  - `infra/redis/`: การตั้งค่า Redis Cache และ Queue storage
  - `infra/monitoring/`: การตั้งค่า Prometheus, Grafana และ Health probe endpoints

---

## 📚 เอกสารอ้างอิงของโปรเจกต์ (Documentation Matrix)

| เอกสาร | รายละเอียดและขอบเขตเนื้อหา |
|---|---|
| 📄 **[Product Requirement Document (PRD)](doc/Subscription_Track_PRD.md)** | เอกสารข้อกำหนดผลิตภัณฑ์, User Persona, MVP Feature Matrix, และ Roadmaps |
| 📱 **[Frontend Screen Specifications](doc/frontend/subscription_track_frontend_screens.md)** | รายละเอียดหน้าจอทั้ง 5 แท็บ, Design Tokens, Color Palette, และ State Mapping |
| 🏛️ **[Feature-First Architecture Guide](doc/architecture/feature_first_architecture.md)** | สถาปัตยกรรม Feature-First, โครงสร้าง 4 เลเยอร์, และเกณฑ์การตรวจสอบโค้ด |
| ⚡ **[Riverpod State Management Guide](doc/architecture/riverpod_architecture_guide.md)** | แผนผัง Controller และ Provider ทั้งหมดในแอปพลิเคชัน พร้อมคู่มือการใช้งาน |
| 👥 **[Team Task Allocation & Schedule](doc/task/team_task_allocation.md)** | การจัดสรรงานของทีมพัฒนา (Person 1, 2, 3), สถานะงาน, และแผนการส่งมอบ |
| 🌳 **[Repository Tree Overview](.agents/tree_repo/tree_repo.md)** | ผังไดเรกทอรีโปรเจกต์ฉบับเต็ม พร้อมคำอธิบายหน้าที่ของแต่ละไฟล์ |

---

## 🌿 กิ่งพัฒนาและระบบ Git (Branching Model)

โปรเจกต์นี้ใช้โมเดลการพัฒนาแบบมาตรฐาน:
- **`main`:** กิ่ง Production / Releases (เสถียร 100% พร้อมทดสอบและ deploy)
- **`develop`:** กิ่งรวบรวมงานพัฒนาหลักของทีม (Feature Integration)

---

## 🤝 ทีมพัฒนา (Core Contributors)
- **Nekokun2004** (`netiwut2004@gmail.com`)
- **Nawaphon Sungthong** (`nawaphonsungthong@gmail.com`)
