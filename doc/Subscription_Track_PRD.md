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

### MVP Frontend Data Architecture (Implementation Baseline — 12 September 2026)

Flutter client ใช้ Repository Pattern ร่วมกับ **Riverpod Feature-First Architecture** เป็นขอบเขตระหว่าง UI state กับ data source:

```text
Tab Views / Sub-Screens / Modal Sheets
        ↓ watch / command
Riverpod Application Controllers (List, Filter, Linking, Info, Pin, Theme)
        ↓ depends on contracts
Abstract Repositories (SubscriptionRepository, PaymentCardRepository, AuthRepository)
        ↓ current implementations
InMemory Repositories (Mock I/O delay, Seed Data, Auto-import, State-driven Auth)
```

- `SubscriptionRepository` กำหนด CRUD, lookup และ `toggleSelection`
- `InMemorySubscriptionRepository` เป็น mock data source ระหว่างรอเชื่อมต่อ NestJS REST API
- `subscriptionListProvider` เป็น `AsyncNotifierProvider<SubscriptionListController, List<Subscription>>` รองรับ optimistic UI, rollback และ auto-import
- `PaymentCardLinkingController` บริหารการผูกบัตรชำระเงินจำลอง พร้อมนำเข้า Subscription รายการเรียกเก็บซ้ำโดยอัตโนมัติ (ป้องกัน ID ซ้ำ)
- `userIncomeProvider` คำนวณรายได้/ยอดเงินรวมจากผลรวมยอดเงินคงเหลือในบัตร (`currentBalance`) ที่ผูกไว้
- `securityPinProvider` ดูแลรหัสความปลอดภัย PIN 6 หลัก รองรับการยืนยันก่อนทำรายการ (`PinVerificationDialog`) และเปลี่ยนรหัส (`ChangePinDialog`)
- `themeModeProvider` ควบคุมธีมแอปพลิเคชัน รองรับทั้ง Light Theme และ Dark Theme แบบ Realtime
- `MainNavigationShell` รวม 5 แท็บหลัก (`IndexedStack`) พร้อมระบบ Nested Routing (`/dashboard/notifications`, `/dashboard/add`, `/dashboard/add/select-package`)

---

## 4. Feature Scope & Priority

### 🔴 MVP (เดือนที่ 1) — Must Have

| Feature | รายละเอียด | สถานะปัจจุบัน |
|---------|------------|---------------|
| **Authentication** | OAuth Google/Apple Sign-In (Mock), Guest Mode, JWT Session State | ✅ พัฒนาเสร็จสิ้น (Frontend UI + Mock Auth Repository) |
| **Onboarding** | หน้าแนะนำแอป 3 สไลด์พร้อมแถบความคืบหน้า (Progress Bar) | ✅ พัฒนาเสร็จสิ้น |
| **Dashboard** | 5-tab adaptive shell: หน้าแรก (KPI/Creep), รายการ, ประหยัด, ตั้งค่า, โปรไฟล์ | ✅ พัฒนาเสร็จสิ้น (Mobile NavigationBar + Desktop NavigationRail) |
| **Add Subscription** | เพิ่มรายการใหม่ผ่านฟอร์ม, กำหนดสี/ไอคอน, เลือกจาก Preset Packages | ✅ พัฒนาเสร็จสิ้น (`AddSubscriptionScreen` + `SelectPackageScreen`) |
| **Edit/Detail Subscription** | ดูรายละเอียด, แก้ไขวันเตือนล่วงหน้า, ทำเครื่องหมายยกเลิก | ✅ พัฒนาเสร็จสิ้น (`SubscriptionDetailSheet`) |
| **Delete Subscription** | ลบรายการพร้อมระบบ Generic Confirmation + ยืนยันรหัส PIN 6 หลัก | ✅ พัฒนาเสร็จสิ้น (`ConfirmationDialog` + `PinVerificationDialog`) |
| **Category Filter** | ทั้งหมด, สตรีมมิ่ง, AI, คลาวด์, สร้างสรรค์, อื่นๆ พร้อมระบบค้นหา | ✅ พัฒนาเสร็จสิ้น (`SubscriptionFilterBar` + derived provider) |
| **Saving Simulation** | คำนวณยอดเงินประหยัดรวมต่อปีเมื่อเลือกยกเลิกบริการ | ✅ พัฒนาเสร็จสิ้น (`SavingsTab` + `savingsViewStateProvider`) |
| **Card Linking & Auto-import** | ผูกบัตรจำลอง (KBank, SCB, UOB, Krungsri) และดึงรายการอัตโนมัติ | ✅ พัฒนาเสร็จสิ้น (`LinkedAccountsCard` + `AddPaymentCardSheet`) |
| **Personal Info Management** | แก้ไขชื่อ-นามสกุล, เบอร์โทร, วันเกิด พร้อมซิงก์ขึ้น Header | ✅ พัฒนาเสร็จสิ้น (`PersonalInfoSheet` + `personalInfoProvider`) |
| **Security PIN** | รหัสความปลอดภัย 6 หลัก พร้อมระบบสั่นเตือนเมื่อผิด และเปลี่ยนรหัส 3 ขั้นตอน | ✅ พัฒนาเสร็จสิ้น (`securityPinProvider`, `PinVerificationDialog`, `ChangePinDialog`) |
| **Notification Center** | หน้าต่างการแจ้งเตือน, แยกแท็บ (ทั้งหมด, ยังไม่อ่าน, ระบบ), มาร์กอ่านแล้ว | ✅ พัฒนาเสร็จสิ้น (`NotificationCenterScreen` + controller) |
| **Theme System** | สลับโหมดสี Dark Mode / Light Mode แบบไดนามิก | ✅ พัฒนาเสร็จสิ้น (`themeModeProvider` + AppDarkTheme / AppLightTheme) |
| **Local Storage** | Hive / SharedPreferences เก็บข้อมูลออฟไลน์ถาวร | 🔄 Baseline ปัจจุบันใช้ In-Memory Repository (พร้อมสำหรับ Hive/REST) |

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
DELETE /subscriptions/:id          → ลบหลังผู้ใช้ยืนยันแบบ Generic Confirmation
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

## 7. ข้อมูลหน้าจอและ Navigation (UI Flow)

### 7.1 Living Navigation Architecture (5-Destination Shell)

แอปพลิเคชันได้รับการพัฒนาบนสถาปัตยกรรม **5-Tab Navigation Shell** ด้วย `IndexedStack` เพื่อคงสถานะ State และ Scroll Position ในทุกหน้าจอหลัก พร้อม Sub-Routes สำหรับขั้นตอนการทำงานสำคัญ:

```text
[Splash (/splash)] ──(Auto Session Check)──> [Onboarding (/onboarding)] ──> [Login (/login)]
                                                                                   │
                                                                       (Guest / Google / Apple)
                                                                                   ▼
┌────────────────────────────────────────────── [/dashboard: MainNavigationShell (IndexedStack)] ──────────────────────────────────────────────┐
│                                                                                                                                              │
│   [0: หน้าแรก Dashboard]          [1: รายการ Subscriptions]     [2: ประหยัด Savings]       [3: ตั้งค่า Settings]         [4: โปรไฟล์ Profile]        │
│   • Header (Avatar/Name/Income)  • Filter (All/Active/Overdue) • Simulator Checklist    • Theme Switch (Light/Dark)  • Personal Info Sheet         │
│   • Hero KPI Cards & Summary     • Subscription Cards List     • Monthly Saving Target   • Reminder Push Switch       • Linked Cards Balance Auto-Sum│
│   • Renewal Timeline             • FAB "+ เพิ่มรายการ"         • Selected Items Cancel   • Language / Currency Sheets • Security PIN Setup Dialog   │
│   • Unused Services Warning      • Pin Verification on Action                                                         • Card Auto-Import Sheet      │
└──────────────┬───────────────────────────────────┬───────────────────────────────────────────────────────────────────────────────────────────┘
               │                                   │
               │ [Tap Notification Icon]          │ [Tap FAB "+ เพิ่มรายการ"]
               ▼                                   ▼
   [/dashboard/notifications]             [/dashboard/add: AddSubscriptionScreen]
   • All / Unread / System Tabs           • Preset vs Custom Selection
   • Mark as Read / Dismiss All           • Form Validation & PIN Verification
                                                   │
                                                   │ [Tap "เลือกจากแพ็กเกจ"]
                                                   ▼
                                          [/dashboard/add/select-package: SelectPackageScreen]
                                          • PresetPackageCatalog (Netflix, Spotify, etc.)
                                          • Tier & Billing Cycle Selection
```

#### Startup & Deep-Linking Redirect Rules
1. **Startup Check**: แอปเริ่มทำงานที่ `/splash` ตรวจสอบ Token ใน Secure Storage / Hive
2. **First Launch**: หากยังไม่เคย Onboarding หรือไม่มี session ให้ redirect ไป `/onboarding`
3. **Authentication**: หน้า `/login` รองรับ OAuth Google, Apple ID และ Guest Mode ผ่าน `authProvider`
4. **Shell Navigation**: เข้าสู่ `/dashboard` (Index 0: Dashboard)
5. **Deep-linking Sub-routes**:
   - `/dashboard/notifications` → เปิด `NotificationCenterScreen`
   - `/dashboard/add` → เปิด `AddSubscriptionScreen`
   - `/dashboard/add/select-package` → เปิด `SelectPackageScreen` (พร้อม preset data)

---

### 7.2 รายการหน้าจอและคอมโพเนนต์ที่พัฒนาเสร็จสมบูรณ์ (Implemented Screens & Components)

| # | หน้าจอ / คอมโพเนนต์ | Route / Presentation | Riverpod State Controller | สถานะการพัฒนา |
|---|--------------------|----------------------|---------------------------|:------------:|
| 1 | **Splash Screen** | `/splash` | `authProvider` | ✅ Implemented |
| 2 | **Onboarding Screen** | `/onboarding` | PageController (3 ขั้นตอน) | ✅ Implemented |
| 3 | **Login Screen** | `/login` | `authProvider` (Google/Apple/Guest) | ✅ Implemented |
| 4 | **Main Shell & Dashboard Tab** | `/dashboard` (Tab 0) | `subscriptionProvider`, `userIncomeProvider` | ✅ Implemented |
| 5 | **Subscriptions Tab** | `/dashboard` (Tab 1) | `subscriptionProvider` (Filter, Search, Delete) | ✅ Implemented |
| 6 | **Savings Tab** | `/dashboard` (Tab 2) | `savingsProvider` (Checklist, Goal) | ✅ Implemented |
| 7 | **Settings Tab** | `/dashboard` (Tab 3) | `themeModeProvider`, `notificationSettingsProvider` | ✅ Implemented |
| 8 | **Profile Tab** | `/dashboard` (Tab 4) | `userProfileProvider`, `paymentCardProvider` | ✅ Implemented |
| 9 | **Add Subscription Screen** | `/dashboard/add` (Push) | `subscriptionProvider`, `PresetPackageCatalog` | ✅ Implemented |
| 10 | **Select Package Screen** | `/dashboard/add/select-package` (Push) | `PresetPackageCatalog` | ✅ Implemented |
| 11 | **Notification Center** | `/dashboard/notifications` (Push) | `notificationProvider` | ✅ Implemented |
| 12 | **Subscription Detail Sheet** | Modal BottomSheet | `subscriptionProvider` | ✅ Implemented |
| 13 | **Personal Info & Card Sheets** | Modal BottomSheet | `userProfileProvider`, `paymentCardProvider` | ✅ Implemented |
| 14 | **Security PIN & Confirm Dialogs**| Dialog Modal | `pinVerificationProvider` (6-digit PIN) | ✅ Implemented |

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

## 12. Timeline & Milestones (สถานะปัจจุบัน: Frontend Feature-Complete)

### Week 1: Setup & Foundation (Completed)
- [x] Setup Flutter project + Dark/Light Theme System + GoRouter
- [x] ออกแบบ Data Models (`Subscription`, `PaymentCard`, `PresetPackageCatalog`)
- [x] สร้าง UI Kit / Design System Tokens และ Color Schemes

### Week 2: Auth & Navigation Shell (Completed)
- [x] Google / Apple / Guest Login Flow (`authProvider`)
- [x] Onboarding Screen 3 สไลด์พร้อม Skip & Progress Bar
- [x] MainNavigationShell (5-Tab `IndexedStack`)
- [x] Startup Redirect & Route Protection

### Week 3: Subscription Management & Preset Catalog (Completed)
- [x] Dashboard Tab (KPI Cards, Spending Creep Alert, Renewal Timeline)
- [x] Subscriptions Tab (Category Chips, Search, Filter)
- [x] Add Subscription Screen & Select Package Screen (Catalog 10 บริการ)
- [x] Subscription Detail Sheet (Reminder Frequency, Mark Cancelled)
- [x] Delete Flow พร้อม Confirmation Dialog และ Security PIN

### Week 4: Profile, Cards, Security & Settings (Completed)
- [x] Profile Tab (Personal Info Sheet, Avatar Initials, Card Balance Auto-Sum)
- [x] Payment Card Auto-Import Sheet (ตรวจจับและนำเข้ารายการอัตโนมัติ)
- [x] Security PIN Dialogs (Verify PIN, Change PIN 6 หลัก)
- [x] Settings Tab (Light/Dark Theme Switch, Reminder Toggle, Currency)
- [x] Notification Center Screen (All / Unread / System Tabs)

### Week 5-6: Backend API & Data Synchronization (Upcoming Phase)
- [ ] พัฒนา NestJS REST API (Auth, Subscriptions, Cards, Notifications)
- [ ] ติดตั้ง MongoDB Atlas และ Database Schemas
- [ ] Cloud Storage สำหรับรูปโปรไฟล์และใบเสร็จ
- [ ] เชื่อมต่อ Riverpod Repository กับ Backend API แทน In-Memory/Mock
- [ ] Cache & Offline-First Strategy (Hive Boxes)

### Week 7-8: Advanced Analytics & Production Launch (Upcoming Phase)
- [ ] FCM Push Notifications (Cron Job Server-side)
- [ ] AI Spending Creep & Subscription Overlap Analysis
- [ ] Deploy Backend ขึ้น GCP Cloud Run
- [ ] CI/CD Pipeline และ Automated Tests
- [ ] Production Build & App Store / Play Store Preparation

---

## 13. สรุปสิ่งที่พัฒนาเสร็จสมบูรณ์และแผนพัฒนาต่อ (Checklist)

### Frontend MVP (สถานะ: พัฒนาเสร็จสมบูรณ์ 100%)
- [x] **Splash & Onboarding**: สไลด์ 3 ขั้นตอน แนะนำฟีเจอร์หลัก
- [x] **Authentication**: OAuth Buttons (Google, Apple) และ Guest Mode
- [x] **5-Tab Navigation Shell**: Dashboard, Subscriptions, Savings, Settings, Profile
- [x] **Dashboard Tab**: KPI Summary Cards, Category Spending, Renewal Timeline
- [x] **Subscriptions Tab**: รายการสมาชิก, ค้นหา, กรองสถานะ, Pull-to-refresh
- [x] **Add & Select Package**: Form validation, Preset Packages Catalog (Netflix, Spotify, ฯลฯ)
- [x] **Subscription Detail Sheet**: ดูข้อมูลละเอียด, แก้ไขแจ้งเตือน, ยกเลิกสมาชิก
- [x] **Savings Tab**: คำนวณเงินออม, เลือกยกเลิกเพื่อจำลองประหยัดเงิน
- [x] **Profile & Card Management**: ข้อมูลส่วนตัว, เพิ่มบัตร, Auto-import รายการ, คำนวณยอดคงเหลือ
- [x] **Security PIN Dialogs**: ยืนยันรหัส PIN 6 หลักก่อนทำรายการลบ/แก้ไข, เปลี่ยนรหัส PIN
- [x] **Settings Tab**: สลับ Theme Mode (สว่าง/มืด), แจ้งเตือน, สกุลเงิน
- [x] **Notification Center**: รายการแจ้งเตือน 3 แท็บ (ทั้งหมด, ยังไม่อ่าน, ระบบ)

### Backend & Cloud Infrastructure (สิ่งที่ต้องพัฒนาในเฟสถัดไป)
- [ ] NestJS Backend REST APIs (Auth, Users, Subscriptions, Cards)
- [ ] Database Schema บน MongoDB Atlas
- [ ] FCM Push Notification Service สำหรับเตือนรอบบิล
- [ ] Deployment บน Google Cloud Run & Docker Container
- [ ] CI/CD Pipeline ผ่าน GitHub Actions
- [ ] Hive Local Storage Caching สำหรับ Offline Mode เต็มรูปแบบ

---

*เอกสารฉบับนี้ได้รับการอัปเดตสถานะล่าสุดให้สอดคล้องกับซอร์สโค้ด Frontend MVP ปัจจุบัน*
*อัปเดตล่าสุด: 12 กันยายน 2026*
