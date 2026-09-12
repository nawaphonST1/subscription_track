# Subscription Track (Full-Stack Monorepo)

ระบบตรวจจับและประเมินค่าบริการสมาชิกรายเดือน/รายปี (Subscription Tracker & Analytics System) ที่มาพร้อมกับระบบคำนวณ **Subscription Creep Score** เพื่อประเมินความเสี่ยงทางการเงินจากการสมัครบริการซ้ำซ้อนหรือไม่ได้ใช้งาน

โครงสร้างโปรเจกต์จัดระเบียบในรูปแบบ **Apps & Infra Monorepo** เพื่อรองรับทั้ง Mobile Client, Backend API, และ Cloud Infrastructure

---

## 🏛️ สถาปัตยกรรมโปรเจกต์ (Repository Architecture)

```text
subscription_track/
├── apps/
│   ├── mobile/          # แอปพลิเคชันมือถือ (Flutter, Riverpod, Feature-First Architecture)
│   └── api/             # ระบบ Backend API (NestJS Modular Monolith - Phase 2)
├── infra/               # การตั้งค่า Infrastructure & DevOps (Docker, Nginx, PostgreSQL, Redis)
│   ├── nginx/
│   ├── postgres/
│   ├── redis/
│   └── monitoring/
├── scripts/             # สคริปต์อัตโนมัติสำหรับการพัฒนาและทดสอบระดับ Repository
├── doc/                 # เอกสารข้อกำหนดระบบ สถาปัตยกรรม และการจัดสรรงาน
│   ├── architecture/
│   ├── frontend/
│   ├── backend/
│   ├── devops/
│   ├── task/
│   └── Subscription_Track_PRD.md
├── .agents/             # Antigravity AI Agent Skills & Repository Knowledge
├── .github/             # GitHub Actions CI/CD Workflows
└── .gitignore           # กฎการละเว้นไฟล์ระดับ Full-Stack Monorepo
```

---

## 📱 Mobile Application (`apps/mobile/`)

แอปพลิเคชันมือถือพัฒนาด้วย **Flutter** พร้อมระบบจัดการสถานะ **Riverpod** โดยใช้สถาปัตยกรรม **Feature-First Clean Architecture**

### ฟีเจอร์หลัก (Features):
- **Dashboard สรุปยอดค่าใช้จ่าย:** สรุปยอดจ่ายออกทั้งหมดต่อเดือนและต่อปีแบบเรียลไทม์
- **Subscription Creep Score:** ประเมินเปอร์เซ็นต์ค่าบริการเมื่อเทียบกับรายได้ พร้อมบอกระดับความเสี่ยงทางการเงิน
- **ระบบจำลองการประหยัดค่าใช้จ่าย (Savings Simulation):** ติ๊กเลือกบริการเพื่อคำนวณยอดเงินที่จะประหยัดได้ต่อเดือนและต่อปี
- **Add & Preset Packages:** เพิ่มรายการและเลือกแพ็กเกจพรีเซ็ตยอดนิยมในไทยกว่า 10 บริการ
- **Linked Accounts & Auto-Import:** จำลองการผูกบัตรธนาคาร ตรวจจับบิลเรียกเก็บซ้ำ และซิงก์ยอดคงเหลือสะท้อนรายได้
- **Security PIN:** ระบบรักษาความปลอดภัย PIN 6 หลัก พร้อมระบบยืนยันก่อนทำรายการแก้ไข/ลบ
- **Responsive Layout:** รองรับหน้าจอทั้งมือถือ แท็บเล็ต และคอมพิวเตอร์ (Adaptive Shell)

### การติดตั้งและรัน Mobile Application:
เข้าสู่ไดเรกทอรี `apps/mobile/`:

```bash
cd apps/mobile
```

1. **ตรวจสอบความพร้อมของระบบ Flutter:**
   ```bash
   flutter doctor
   ```

2. **ดาวน์โหลด Dependencies:**
   ```bash
   flutter pub get
   ```

3. **รัน Unit & Widget Tests:**
   ```bash
   flutter test
   ```

4. **รันแอปพลิเคชัน (Debug Mode):**
   ```bash
   flutter run
   ```

---

## 🖥️ Backend API (`apps/api/`)

*สถานะ: วางขอบเขตโครงสร้างพร้อมสำหรับการพัฒนาใน Phase 2 (NestJS Modular Monolith, PostgreSQL, TypeORM, Redis, BullMQ)*
ดูรายละเอียดเพิ่มเติมได้ที่ [doc/Subscription_Track_PRD.md](doc/Subscription_Track_PRD.md)

---

## 🏗️ Infrastructure & Deployment (`infra/`)

*สถานะ: วางโครงสร้างสำหรับ Nginx Reverse Proxy, PostgreSQL, Redis Cache/Queue และ Production Containers*

---

## 📚 เอกสารอ้างอิงที่สำคัญ (Documentation)

* **[Product Requirement Document (PRD)](doc/Subscription_Track_PRD.md)**
* **[Frontend Living Screen Specifications](doc/frontend/subscription_track_frontend_screens.md)**
* **[Feature-First Clean Architecture](doc/architecture/feature_first_architecture.md)**
* **[Riverpod State Management Guide](doc/architecture/riverpod_architecture_guide.md)**
* **[Team Task Allocation & Schedule](doc/task/team_task_allocation.md)**
