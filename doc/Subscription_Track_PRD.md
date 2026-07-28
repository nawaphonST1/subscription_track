# 📋 Product Requirement Document (PRD)
## Subscription Track — Full-Stack Architecture & Feature Design

---

## 1. Executive Summary

**Subscription Track** คือแอปพลิเคชันบริหารจัดการรายจ่ายสมัครสมาชิก (Subscription Management) ที่ช่วยให้ผู้ใช้มองเห็นภาพรวมรายจ่ายทั้งหมด แจ้งเตือนก่อนวันต่ออายุ และแนะนำการยกเลิกบริการที่ไม่ได้ใช้งานผ่านการวิเคราะห์ Usage Pattern จากข้อมูลการใช้งานจริงบนมือถือ

**กลุ่มเป้าหมาย:** บุคคลทั่วไปที่มี subscription หลายตัว, ผู้บริหาร, ผู้ให้เช่าบัญชีออนไลน์

---

## 2. Tech Stack (Full-Stack)

### Frontend (Mobile)
| Layer | Technology |
|-------|------------|
| Framework | Flutter (Dart SDK ^3.12.0) |
| State Management | **Riverpod** (แนะนำ) หรือ BLoC/Cubit |
| Local DB | **Hive** (primary) + ObjectBox (secondary consideration) |
| Local Cache | SharedPreferences (token, settings) |
| HTTP Client | Dio + Retrofit |
| Auth | Firebase Auth (OAuth Google/Apple) |
| Push Noti | Firebase Cloud Messaging (FCM) |
| Biometric | local_auth (Face ID / Touch ID / Fingerprint) |
| Screen Time | iOS: ScreenTime API / Android: UsageStatsManager |
| Intl | flutter_localizations (Thai + English สำหรับ Phase 2) |

### Backend
| Layer | Technology |
|-------|------------|
| Framework | NestJS (TypeScript) |
| Database | MongoDB |
| ODM | Mongoose |
| Auth | Passport.js (JWT + OAuth Google/Apple) |
| Push Noti | Firebase Admin SDK |
| API Style | RESTful + WebSocket (real-time sync) |
| Validation | class-validator + class-transformer |

### Infrastructure (GCP — $50 Credit)
| Service | Usage |
|---------|-------|
| Cloud Run / App Engine | Deploy NestJS Backend |
| Cloud Build | CI/CD Pipeline |
| Firebase | Auth + FCM + Hosting (ถ้ามี Web) |
| MongoDB Atlas | Database (Free Tier M0 ก่อน) |
| Cloud Storage | เก็บรูปโปรไฟล์, ไฟล์แนบ |

---

## 3. System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │   Flutter    │  │   Firebase   │  │   Screen Time    │  │
│  │   Mobile App │  │   (Auth/FCM) │  │   (iOS/Android)  │  │
│  └──────┬───────┘  └──────┬───────┘  └────────┬─────────┘  │
└─────────┼─────────────────┼───────────────────┼────────────┘
          │                 │                   │
          ▼                 ▼                   ▼
┌─────────────────────────────────────────────────────────────┐
│                      GATEWAY LAYER                           │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              NestJS Main API (Monolithic)             │   │
│  │  - Auth Module (OAuth + JWT)                        │   │
│  │  - Subscription Module (CRUD + Analytics)           │   │
│  │  - Package Module (Admin preset management)         │   │
│  │  - User Module (Profile, Income, Settings)          │   │
│  │  - Notification Module (Push scheduling)            │   │
│  └────────────────────┬─────────────────────────────────┘   │
└───────────────────────┼─────────────────────────────────────┘
                        │
          ┌─────────────┼─────────────┐
          ▼             ▼             ▼
┌──────────────┐ ┌─────────────┐ ┌─────────────────┐
│  MongoDB     │ │  Firebase   │ │  Microservices  │
│  (Primary DB)│ │  (Auth/FCM) │ │  (Optional)     │
└──────────────┘ └─────────────┘ └─────────────────┘
```

### Microservices ที่แนะนำ (ถ้าอยากเท่ 😎)
| Service | หน้าที่ | เหตุผล |
|---------|---------|--------|
| **Notification Service** | จัดการ cron job ส่ง Push Notification ก่อนวันต่ออายุ | แยกออกจาก Main API เพราะมี cron job หนัก, ทำงาน background |
| **Analytics Service** | คำนวณ Creep Score, Confidence Score, Usage Pattern | ประมวลผลหนัก, ไม่กระทบ Main API |

---

## 4. Feature Scope & Priority

### 🔴 MVP (เดือนที่ 1) — Must Have
| Feature | รายละเอียด |
|---------|------------|
| **Authentication** | OAuth Google/Apple Sign-In, JWT Token |
| **Onboarding** | หน้าแนะนำแอปครั้งแรก, กรอกรายได้ |
| **Dashboard** | KPI Cards, Subscription List, Filter, Simulation (มีอยู่แล้ว) |
| **Add Subscription** | เลือกจาก Preset Packages หรือกรอกเอง |
| **Edit/Delete Subscription** | แก้ไขรายละเอียด, ลบพร้อม PIN/Biometric |
| **Category Filter** | ทั้งหมด, สตรีมมิ่ง, AI, คลาวด์, สร้างสรรค์ (มีอยู่แล้ว) |
| **Saving Simulation** | คำนวณเงินประหยัดเมื่อเลือกยกเลิก (มีอยู่แล้ว) |
| **Local Storage** | Hive เก็บข้อมูล subscription, รองรับ Offline |
| **Biometric Lock** | Face ID / Fingerprint + PIN 6 หลัก fallback |
| **Push Notification** | FCM เตือนก่อนวันต่ออายุ (ตั้งค่าวันเองได้) |
| **Profile/Settings** | แก้ไขรายได้, ตั้งค่าแจ้งเตือน, ออกจากระบบ |

### 🟡 Phase 2 (เดือนที่ 2) — Should Have
| Feature | รายละเอียด |
|---------|------------|
| **Admin Panel (Web)** | หน้าเพิ่ม/จัดการ Preset Packages สำหรับทีม |
| **Usage Pattern Tracking** | ดึง Screen Time จากมือถือ → คำนวณ Confidence Score |
| **Confidence Score Auto** | เปรียบเทียบกับสถิติทั่วไปจาก Google |
| **Package Comparison** | เปรียบเทียบแพ็กเกจระหว่างแอปในกลุ่มเดียวกัน |
| **History/Analytics** | กราฟแสดงแนวโน้มรายจ่ายรายเดือน/ปี |
| **Multi-language** | รองรับ Thai + English |

### 🟢 Phase 3 (Future) — Nice to Have
| Feature | รายละเอียด |
|---------|------------|
| **Gamification** | Streak การยกเลิก, Badge ประหยัดเงิน, แชร์ผลงาน |
| **Subscription Sharing** | แชร์ค่าใช้จ่ายกับเพื่อน/ครอบครัว |
| **Web Dashboard** | รองรับการใช้งานบน Browser |
| **AI Recommendation** | ML แนะนำว่าควรยกเลิกตัวไหน |

---

## 5. Database Schema (MongoDB)

### Collections

```javascript
// 1. Users
{
  _id: ObjectId,
  email: String,
  name: String,
  avatar: String,
  authProvider: "google" | "apple",
  authProviderId: String,
  income: Number,           // รายได้ต่อเดือน
  currency: String,         // "THB"
  settings: {
    notificationDays: Number,  // แจ้งเตือนก่อนกี่วัน (default: 3)
    biometricEnabled: Boolean,
    pinCode: String,        // hashed
    language: "th" | "en"
  },
  createdAt: Date,
  updatedAt: Date
}

// 2. Subscriptions (ของผู้ใช้แต่ละคน)
{
  _id: ObjectId,
  userId: ObjectId,         // ref: Users
  packageId: ObjectId,      // ref: Packages (ถ้าเลือกจาก preset)
  name: String,             // ชื่อที่แสดง (อาจ override จาก preset)
  price: Number,
  billingPeriod: "monthly" | "yearly" | "quarterly",
  category: "streaming" | "ai" | "cloud" | "creative" | "other",
  nextBillingDate: Date,
  usageStatus: "frequent" | "moderate" | "unused",
  confidence: Number,       // 0-100 (คำนวณจาก usage pattern)
  isSelected: Boolean,      // สำหรับ simulation
  customFields: [           // ฟิลด์เพิ่มเติมที่ผู้ใช้กำหนด
    { key: "token", value: "xxx" },
    { key: "note", value: "shared with friend" }
  ],
  reminderEnabled: Boolean,
  createdAt: Date,
  updatedAt: Date
}

// 3. Packages (Preset จาก Admin)
{
  _id: ObjectId,
  name: String,             // "Netflix", "Spotify", "ChatGPT Plus"
  description: String,
  category: "streaming" | "ai" | "cloud" | "creative" | "other",
  defaultPrice: Number,
  billingPeriod: "monthly" | "yearly",
  iconUrl: String,          // URL รูปไอคอน
  websiteUrl: String,
  isActive: Boolean,
  createdAt: Date
}

// 4. UsageLogs (สำหรับคำนวณ Confidence)
{
  _id: ObjectId,
  userId: ObjectId,
  subscriptionId: ObjectId,
  date: Date,
  screenTimeMinutes: Number,  // ดึงจาก Screen Time API
  appOpenCount: Number,
  createdAt: Date
}

// 5. Notifications
{
  _id: ObjectId,
  userId: ObjectId,
  type: "upcoming_bill" | "unused_warning" | "system",
  title: String,
  body: String,
  scheduledAt: Date,
  sentAt: Date,
  isRead: Boolean,
  createdAt: Date
}
```

---

## 6. API Endpoints (NestJS)

### Auth Module
```
POST /auth/google          → OAuth Google Login
POST /auth/apple           → OAuth Apple Login
POST /auth/refresh         → Refresh JWT Token
POST /auth/logout          → Revoke Token
```

### User Module
```
GET    /users/me           → ดึงข้อมูลตัวเอง
PATCH  /users/me           → แก้ไขข้อมูล (name, income, settings)
PATCH  /users/me/pin       → ตั้งค่า PIN 6 หลัก
PATCH  /users/me/biometric → เปิด/ปิด Biometric Lock
```

### Subscription Module
```
GET    /subscriptions              → ดึงรายการทั้งหมด
POST   /subscriptions              → เพิ่ม subscription
GET    /subscriptions/:id          → ดึงรายละเอียด
PATCH  /subscriptions/:id          → แก้ไข
DELETE /subscriptions/:id          → ลบ (ต้องผ่าน PIN/Biometric)
POST   /subscriptions/:id/toggle   → Toggle isSelected (simulation)
GET    /subscriptions/analytics    → ดึงสถิติรายจ่าย
```

### Package Module (Admin)
```
GET    /packages           → ดึง preset list (public)
POST   /packages           → Admin เพิ่ม package (protected)
PATCH  /packages/:id       → Admin แก้ไข
DELETE /packages/:id       → Admin ลบ
```

### Notification Module
```
GET    /notifications      → ดึงประวัติการแจ้งเตือน
PATCH  /notifications/:id/read → อ่านแล้ว
POST   /notifications/test → ทดสอบส่ง Push (dev only)
```

---

## 7. Screen List & Navigation Flow

```
[Splash] → [Onboarding] → [Login (OAuth)]
                              │
                              ▼
                    ┌─────────────────┐
                    │   [Dashboard]   │ ← หน้าหลัก
                    │   (มีอยู่แล้ว)  │
                    └────────┬────────┘
                             │
        ┌────────────────────┼────────────────────┐
        ▼                    ▼                    ▼
 [Add Subscription]    [Edit Subscription]   [Profile/Settings]
        │                    │                    │
        ▼                    ▼                    ▼
 [Select Package]      [PIN/Biometric]      [Income Setting]
 (Preset List)         (Verify before       [Noti Settings]
 [Custom Form]          delete/edit)        [Language]
                                                  [Logout]
        │
        ▼
 [Subscription Detail]
 [Usage Stats]
 [Comparison]
```

### หน้าจอที่ต้องออกแบบเพิ่มจากที่มี:

| หน้า | รายละเอียด |
|------|------------|
| **Splash Screen** | โลโก้ + Loading |
| **Onboarding** | 3-4 หน้าแนะนำฟีเจอร์หลัก |
| **Login Screen** | ปุ่ม Sign in with Google / Apple |
| **Add Subscription** | เลือกจาก Preset หรือกรอกเอง |
| **Select Package** | รายการ preset (Netflix, Spotify, etc.) |
| **Subscription Detail** | รายละเอียดเต็ม + กราฟ usage |
| **Edit Subscription** | แก้ไขข้อมูลทั้งหมด |
| **Profile** | รูปโปรไฟล์, ชื่อ, อีเมล |
| **Settings** | รายได้, แจ้งเตือน, Biometric, PIN, ภาษา |
| **Notification Center** | รายการแจ้งเตือนทั้งหมด |
| **History/Analytics** | กราฟรายจ่ายย้อนหลัง |
| **Admin Panel (Web)** | จัดการ Preset Packages |

---

## 8. Local Storage Strategy (Offline-First)

### แนะนำ: **Hive + SharedPreferences**

```
SharedPreferences (Key-Value)
├── auth_token
├── refresh_token
├── user_id
├── biometric_enabled
├── pin_code (encrypted)
└── language

Hive (NoSQL Boxes)
├── subscriptions_box     → List<SubscriptionModel>
├── packages_box          → List<PackageModel> (cache preset)
├── notifications_box     → List<NotificationModel>
└── usage_logs_box        → List<UsageLogModel>
```

### Sync Strategy
```
1. อ่านจาก Hive ก่อนเสมอ (แสดงทันที)
2. เรียก API ดึงข้อมูลล่าสุด (background)
3. ถ้า success → อัปเดต Hive + แสดงข้อมูลใหม่
4. ถ้า fail → แสดงข้อมูลเก่าจาก Hive + แสดง "ออฟไลน์โหมด"
5. การเพิ่ม/แก้ไข/ลบ → บันทึกลง Hive ทันที + ส่ง API (ถ้ามีเน็ต)
   ถ้าไม่มีเน็ต → เก็บใน pending_actions_box → sync ตอนมีเน็ต
```

### ทำไมไม่ใช้ ObjectBox?
| Criteria | Hive | ObjectBox |
|----------|------|-----------|
| ความเร็ว | ⚡⚡⚡ เร็วมาก | ⚡⚡⚡ เร็วมาก |
| ขนาด | เล็ก | ใหญ่กว่า |
| Query | ง่าย (key-based) | ซับซ้อนกว่า (SQL-like) |
| Relations | ต้องจัดการเอง | รองรับ Relations |
| Sync | ไม่มี | มี ObjectBox Sync |

**สรุป:** Hive เพียงพอสำหรับ MVP ของคุณ (ข้อมูลไม่ซับซ้อน, ทีมคุ้นเคย) ถ้าอนาคตต้องการ Sync หลายอุปกรณ์แบบ real-time ค่อยย้ายไป ObjectBox

---

## 9. Microservices Recommendation

### ถ้าอยากเท่จริง ๆ (แต่ไม่ over-engineer) 😎

```
Main API (NestJS) — Monolithic
├── Auth
├── User
├── Subscription CRUD
└── Package Management

Microservices (แยกออกมา)
├── Notification Service (Node.js/NestJS)
│   ├── รับ message จาก Main API ผ่าน Redis/RabbitMQ
│   ├── จัดการ Cron Job (node-cron / Bull Queue)
│   └── ส่ง Push ผ่าน Firebase Admin SDK
│
└── Analytics Service (Node.js/Python)
    ├── รับ Screen Time Data จาก Mobile
    ├── คำนวณ Confidence Score
    └── ส่งผลลัพธ์กลับไปเก็บใน MongoDB
```

### ทำไมแยกแค่ 2 ตัว?
- **Notification:** มี cron job หนัก ถ้าอยู่ใน Main API จะกิน resource → แยกดีที่สุด
- **Analytics:** คำนวณหนัก อาจใช้เวลา ถ้าอยู่ใน Main API จะทำให้ API ช้า → แยกดีที่สุด
- **ที่เหลือ:** ยังเป็น Monolithic เพราะทีม 3 คน 2 เดือน ไม่ควร over-engineer

---

## 10. Monetization Ideas (สำหรับตอบอาจารย์)

### แนวทางที่เป็นไปได้จริง:

| โมเดล | รายละเอียด | ความเป็นไปได้ |
|--------|------------|---------------|
| **Freemium** | Free: ติดตามได้ 5 subscription, ไม่มี analytics. Pro: ไม่จำกัด + AI แนะนำ + รายงานละเอียด | ⭐⭐⭐⭐⭐ |
| **Affiliate Marketing** | แนะนำแพ็กเกจทางเลือกที่ถูกกว่า → ได้ค่าคอมมิชชั่นจากผู้ให้บริการ (เช่น แนะนำย้ายจาก Netflix ไป Disney+ ที่ถูกกว่า) | ⭐⭐⭐⭐ |
| **Referral System** | ชวนเพื่อนใช้ → ได้ Pro ฟรี 1 เดือน | ⭐⭐⭐⭐ |
| **White Label / B2B** | ขายระบบให้บริษัทที่ให้เช่าบัญชี (เช่น ร้านค้าออนไลน์ที่ขาย Netflix รายเดือน) ใช้จัดการลูกค้าของตัวเอง | ⭐⭐⭐⭐⭐ (ตรงกลุ่มเป้าหมายคุณมาก!) |
| **Data Insights (Anonymous)** | รวบรวมข้อมูลแบบไม่ระบุตัวตน → ขายให้บริษัทวิจัยตลาด (เช่น "คนไทยใช้ Netflix น้อยลง 30% ในปีนี้") | ⭐⭐⭐ |
| **In-App Ads (Non-intrusive)** | โฆษณาแบบไม่รบกวน (เช่น แถบล่าง หรือ native ads ในหน้า comparison) | ⭐⭐⭐ |

### 🏆 ไอเดียที่แนะนำมากที่สุดสำหรับโปรเจกต์คุณ:
> **"Freemium + White Label B2B"**
> 
> แอปฟรีสำหรับคนทั่วไป (สร้าง user base) + ขายระบบให้ร้านค้าที่ให้เช่าบัญชี (สร้างรายได้จริง) ตรงกับกลุ่มเป้าหมาย "ผู้ให้เช่าบัญชีออนไลน์" ที่คุณบอกไว้พอดี!

---

## 11. Risk & Constraints

| ความเสี่ยง | ระดับ | แนวทางแก้ไข |
|------------|--------|-------------|
| **Screen Time API บน iOS** | 🔴 สูง | iOS จำกัดการเข้าถึง Screen Time มาก ต้องใช้ ScreenTime API ซึ่งต้องเป็น parental control app หรือใช้ Shortcuts automation ช่วย → อาจต้อง fallback เป็น "ผู้ใช้กรอก usage เอง" ใน MVP |
| **ทีมไม่เคยใช้ NestJS/Flutter** | 🟡 ปานกลาง | จัดเวลาเรียนรู้ 1 สัปดาห์แรก, ใช้ tutorial ของ NestJS + Flutter อย่างดี |
| **MongoDB Schema เปลี่ยนบ่อย** | 🟡 ปานกลาง | ใช้ Mongoose + วาง schema ให้รองรับการขยายตัวตั้งแต่แรก |
| **GCP $50 อาจไม่พอ** | 🟡 ปานกลาง | ใช้ Cloud Run (จ่ายตามการใช้งาน) + MongoDB Atlas Free Tier ก่อน |
| **2 เดือนอาจไม่พอทำทุกฟีเจอร์** | 🔴 สูง | Focus MVP ก่อน ตัด Gamification, Multi-language, AI ออกไป Phase 3 |

---

## 12. Timeline & Milestones (2 เดือน)

### Week 1: Setup & Foundation
- [ ] Setup Flutter project + Theme + Navigation
- [ ] Setup NestJS + MongoDB + Firebase Auth
- [ ] ออกแบบ Database Schema ให้เรียบร้อย
- [ ] สร้าง UI Kit / Design System (Dark Navy Theme)

### Week 2: Auth & Core
- [ ] OAuth Google/Apple Login
- [ ] JWT + Secure Storage
- [ ] Onboarding Flow
- [ ] Biometric Lock + PIN
- [ ] Hive Local Storage Setup

### Week 3: Subscription CRUD
- [ ] Dashboard (refactor จากของเดิม)
- [ ] Add Subscription (Preset + Custom)
- [ ] Edit/Delete with PIN verification
- [ ] Category Filter (refactor)
- [ ] Saving Simulation (refactor)
- [ ] Sync ระหว่าง Local ↔ Server

### Week 4: Notification & Polish MVP
- [ ] FCM Push Notification
- [ ] Notification Settings
- [ ] Profile/Settings Page
- [ ] Admin Panel (Web) สำหรับจัดการ Packages
- [ ] Testing & Bug Fix

### Week 5-6: Phase 2 Features
- [ ] Usage Pattern Tracking (Android ก่อน, iOS ตามหลัง)
- [ ] Confidence Score Calculation
- [ ] Package Comparison
- [ ] History/Analytics Charts
- [ ] Multi-language (Thai + English)

### Week 7-8: DevOps & Final
- [ ] Deploy Backend ขึ้น GCP Cloud Run
- [ ] CI/CD Pipeline (GitHub Actions / Cloud Build)
- [ ] Final Testing (Unit + Integration)
- [ ] Documentation & Presentation

---

## 13. สรุปสิ่งที่ต้องออกแบบเพิ่ม (Checklist)

### Frontend Screens
- [ ] Splash / Onboarding (3-4 หน้า)
- [ ] Login (OAuth buttons)
- [ ] Add Subscription (Preset selector + Custom form)
- [ ] Subscription Detail (full info + usage graph)
- [ ] Edit Subscription
- [ ] Profile
- [ ] Settings (Income, Noti, Biometric, PIN, Language)
- [ ] Notification Center
- [ ] History/Analytics (charts)

### Backend APIs
- [ ] Auth (OAuth + JWT)
- [ ] User CRUD + Settings
- [ ] Subscription CRUD + Analytics
- [ ] Package Management (Admin)
- [ ] Notification Scheduling
- [ ] Usage Logs

### Infrastructure
- [ ] NestJS on GCP Cloud Run
- [ ] MongoDB Atlas
- [ ] Firebase (Auth + FCM)
- [ ] CI/CD Pipeline

---

*เอกสารฉบับนี้จัดทำขึ้นเพื่อใช้เป็นแนวทางในการพัฒนา Subscription Track สู่ Full-Stack Application*
*จัดทำเมื่อ: 28 กรกฎาคม 2026*
