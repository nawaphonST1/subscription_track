# 📱 Subscription Track — Frontend Screens & Architecture Spec

**Project:** Subscription Track

**Phase:** MVP (Full Frontend Design)

**Status:** Living Specification (Frontend MVP Feature-Complete)

**Last Updated:** 12 September 2026

---

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Screen List & Hierarchy](#screen-list--hierarchy)
3. [Detailed Screen Specifications](#detailed-screen-specifications)
4. [Widgets Inventory](#widgets-inventory)
5. [BLoC/State Management Strategy](#bloccubit-vs-riverpod-recommendation)
6. [Mock Data Structure](#mock-data-structure)
7. [Navigation Flow](#navigation-flow)
8. [Design System & Theme](#design-system--theme)

---

## Architecture Overview

### Current Implementation Baseline

รายละเอียดส่วนนี้เป็น source of truth สำหรับ Frontend MVP และใช้แทนตัวอย่าง proposal เดิมที่อาจยังปรากฏในหัวข้อถัดไป:

- Startup flow เป็น state-driven redirect: Splash → Onboarding → Login → Dashboard โดยไม่มี `Future.delayed` navigation ใน Splash (พร้อมรองรับ Direct URL Deep-linking สำหรับ Dev/Testing)
- `/dashboard` render `MainNavigationShell` และใช้ `IndexedStack` เก็บ state ของ 5 destinations:
  - **Tab 0: หน้าแรก (Dashboard)** — KPI Cards, Creep Risk, Upcoming Renewals, Unused Service Alert
  - **Tab 1: รายการ (Subscriptions)** — Search, Category Filter, Subscription List, Add FAB (`/dashboard/add`), Detail Sheet, Delete Confirmation + PIN Verification
  - **Tab 2: ประหยัด (Savings)** — Saving Goal Banner, Selection Checklist, Cancel Selected Action
  - **Tab 3: ตั้งค่า (Settings)** — แจ้งเตือนก่อนตัดเงิน (Notification Reminder), โหมดกลางคืน (Light/Dark Theme Switch), ภาษาและสกุลเงิน, เกี่ยวกับแอป
  - **Tab 4: โปรไฟล์ (Profile)** — ข้อมูลผู้ใช้ (Profile Identity), ข้อมูลส่วนตัว (Personal Info Sheet), ตั้งค่า PIN (Change PIN Dialog), บัตรที่เชื่อมต่อ (Linked Payment Cards + Auto-import), ออกจากระบบ
- Sub-routes ภายใต้ `/dashboard`:
  - `/dashboard/notifications` — Notification Center Screen (แถบตัวกรอง: ทั้งหมด, ยังไม่อ่าน, ระบบ)
  - `/dashboard/add` — Add Subscription Screen (Preset picker, appearance selector, general fields, usage status)
  - `/dashboard/add/select-package` — Select Package Screen (Preset package catalog)
- Modal Sheets & Dialogs:
  - `SubscriptionDetailSheet` — ดูรายละเอียด, ปรับวันแจ้งเตือน, ทำเครื่องหมายว่ายกเลิกแล้ว
  - `PinVerificationDialog` — ยืนยันรหัส PIN 6 หลักก่อนเพิ่มหรือลบรายการ
  - `ChangePinDialog` — เปลี่ยนรหัส PIN 3 ขั้นตอน
  - `ConfirmationDialog` — ยืนยันการลบแบบ Generic Confirmation
  - `PersonalInfoSheet` — แก้ไขชื่อ-นามสกุล เบอร์โทร และวันเกิด
  - `IncomeEditorSheet` — แก้ไขรายได้รายเดือน
  - `AddPaymentCardSheet` — เลือกผูกบัตรจำลองและนำเข้า Subscription อัตโนมัติ
- Shared Header (`MainAppHeader`): แสดง Avatar อักษรย่อ, คำทักทายชื่อผู้ใช้แบบ Realtime, ปุ่มกระดิ่งแจ้งเตือนพร้อม Badge, ชิปแสดงยอดเงินรายได้
- Theme Mode: ควบคุมผ่าน `themeModeProvider` (`ThemeModeController`) รองรับทั้ง Light Theme และ Dark Theme
- Source code จัดแบบ Feature-First Architecture (`app/`, `core/`, `features/`)

---

## Screen List & Hierarchy

### Navigation Hierarchy Tree

```text
[App Root]
└── Splash (/splash) (อยู่จน app flow initialization เสร็จ)
    ├── Onboarding (/onboarding) (first time)
    │   └── Login (/login)
    ├── Login (/login) (returning unauthenticated user)
    │   ├── Google OAuth Mock
    │   ├── Apple OAuth Mock
    │   └── Continue as Guest Mode
    └── Dashboard Shell (/dashboard) (authenticated user)
        ├── MainAppHeader (Avatar / Greeting / Noti Button / Income Chip)
        └── MainNavigationShell (IndexedStack 5 Tabs)
            ├── Tab 0: Dashboard (หน้าแรก)
            │   ├── Hero Payout KPI + Creep Risk Indicator
            │   ├── Upcoming Renewals Timeline
            │   └── Unused Service Alert
            ├── Tab 1: Subscriptions (รายการ)
            │   ├── Search + Category Filter Bar
            │   ├── Subscription List / Checkbox Selection / Delete Flow
            │   ├── Subscription Card Tap → SubscriptionDetailSheet (Modal Bottom Sheet)
            │   │   ├── Reminder toggle & days selector (1, 3, 5, 7 days)
            │   │   └── Mark cancelled checkbox & save action
            │   └── Floating Action Button (+) → Route: /dashboard/add
            │       ├── Preset Picker Card → Route: /dashboard/add/select-package
            │       │   └── Preset Package Catalog (Netflix, Spotify, ChatGPT, etc.)
            │       ├── Form Fields (Name, Price, Category, Billing Period, Usage Status)
            │       ├── Appearance Selector (Icon & Color)
            │       └── Submit → PinVerificationDialog (6-digit PIN)
            ├── Tab 2: Savings (ประหยัด)
            │   ├── Saving Goal Banner
            │   ├── Selection Checklist for Simulation
            │   └── Cancel Selected Button → ConfirmationDialog
            ├── Tab 3: Settings (ตั้งค่า)
            │   ├── Notification Reminder Switch (notificationReminderProvider)
            │   ├── Language & Currency Selectors (Placeholders)
            │   ├── Dark / Light Mode Switch (themeModeProvider)
            │   └── About App Modal Dialog
            └── Tab 4: Profile (โปรไฟล์)
                ├── Profile Identity Card (Avatar + Dynamic Name & Email)
                ├── Profile Settings Card
                │   ├── Monthly Income Item → IncomeEditorSheet
                │   ├── Set/Change PIN Item → ChangePinDialog (3-step PIN workflow)
                │   └── Personal Info Item → PersonalInfoSheet (Name, Phone, Birthday)
                ├── Linked Accounts Card (Connected Cards + Auto-calculated Balance)
                ├── Add Payment Card Button → AddPaymentCardSheet
                │   └── Mock Card Picker (KBank, SCB, UOB, Krungsri) → Auto-import Subscriptions
                └── Logout Button → Clears Auth State → Redirects to Onboarding
        └── Sub-Route: /dashboard/notifications (Notification Center Screen)
            ├── Filter Tabs: ทั้งหมด (All), ยังไม่อ่าน (Unread), ระบบ (System)
            ├── Notification List Items (Icon, Title, Body, Timestamp, Read State)
            ├── Mark Single as Read on Tap
            └── Mark All as Read Button in AppBar
```

---

## Detailed Screen Specifications

### 1️⃣ Splash Screen

| Property | Value |
|----------|-------|
| **Purpose** | Initial loading screen with logo & app name |
| **Duration** | เท่ากับเวลาตรวจ app flow/session; ไม่มี fixed delay |
| **State Management** | `appFlowProvider` + GoRouter `refreshListenable`/`redirect` |
| **Widgets Used** | `Scaffold`, `Center`, `Column`, `CircularProgressIndicator` |
| **Mock Data** | None (static UI) |
| **Navigation** | Router redirect ไป Onboarding, Login หรือ Dashboard ตาม state |

**UI Layout:**
```
┌─────────────────────────┐
│                         │
│      [Logo Image]       │
│    Subscription Track   │
│                         │
│   [Circular Loading]    │
│                         │
└─────────────────────────┘
```

---

### 2️⃣ Onboarding (3 Pages)

#### Onboarding Coordinator
| Property | Value |
|----------|-------|
| **Purpose** | Sequential pages to introduce app features |
| **Pages** | 3-4 pages with PageView |
| **State** | Track current page index + scroll to next |
| **Navigation** | Final button "Get Started" → Login |

**Page 1: "Manage All Subscriptions"**
```
┌─────────────────────────┐
│    [Illustration]       │  (SVG of stacked cards)
│                         │
│  Manage All Your        │
│  Subscriptions in       │
│  One Place             │
│                         │
│  See all your monthly   │
│  and yearly bills at    │
│  a glance              │
│                         │
│  [Skip] ————— [Next ➜]  │
└─────────────────────────┘
```

**Page 2: "Save Money Smart"**
```
┌─────────────────────────┐
│    [Illustration]       │  (SVG of piggy bank + coins)
│                         │
│  Find & Cancel          │
│  Unused Services       │
│                         │
│  Identify subscriptions │
│  you never use and      │
│  start saving today    │
│                         │
│  [Skip] ————— [Next ➜]  │
└─────────────────────────┘
```

**Page 3: "Get Smart Alerts"**
```
┌─────────────────────────┐
│    [Illustration]       │  (SVG of bell + notification)
│                         │
│  Never Miss a           │
│  Renewal Again         │
│                         │
│  Get notified before    │
│  each billing date so   │
│  you stay in control   │
│                         │
│  [Skip] ————— [Get Started ➜] │
└─────────────────────────┘
```

**Widgets:**
- `PageView.builder`
- `Indicator dots` (custom or package)
- `SingleChildScrollView` per page
- Buttons with smooth transitions

---

### 3️⃣ Login Screen

| Property | Value |
|----------|-------|
| **Purpose** | OAuth Google/Apple Sign-In & Guest Demo Mode |
| **State** | `AsyncNotifierProvider<AuthNotifier, User?>` (`apps/mobile/lib/features/auth/application/auth_provider.dart`) |
| **Repository** | `InMemoryAuthRepository` (`apps/mobile/lib/features/auth/data/in_memory_auth_repository.dart`) |
| **Navigation** | Success/Guest → Redirects to Dashboard; Supports Direct URL Deep-linking for Dev |

**UI Layout:**
```
┌─────────────────────────┐
│                         │
│   [App Logo Large]      │
│                         │
│  Subscription Track     │
│  Manage & Save Money    │
│                         │
│  ┌───────────────────┐  │
│  │ Sign in with 🔵 G │  │ (Google OAuth button)
│  └───────────────────┘  │
│                         │
│  ┌───────────────────┐  │
│  │ Sign in with 🍎 A │  │ (Apple OAuth button)
│  └───────────────────┘  │
│                         │
│  [Or continue as guest] │
│  (tap to use without    │
│   login - demo mode)    │
│                         │
│  By signing in you agree│
│  to Terms & Privacy     │
│                         │
└─────────────────────────┘
```

**State Management & Implementation:**
```dart
// apps/mobile/lib/features/auth/application/auth_provider.dart
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return InMemoryAuthRepository();
});

final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<User?> {
  Future<void> loginWithGoogle() async => ...
  Future<void> loginWithApple() async => ...
  Future<void> loginAsGuest() async => ...
  Future<void> logout() async => ...
}
```

---

### 4️⃣ Dashboard Screen & Adaptive Navigation Shell

| Property | Value |
|----------|-------|
| **Purpose** | Main application shell with 5 feature tabs, responsive navigation, and smart app header |
| **Current State** | ✅ Adaptive navigation shell with 5 integrated destinations |
| **State Management** | Riverpod `AsyncNotifier` + Repository Pattern + derived read models |
| **Responsive** | ✅ `NavigationBar` on mobile (<900px); `NavigationRail` + adaptive grid at desktop (≥900px) |

**Shared Header (`MainAppHeader`):**
- **User Avatar**: CircleAvatar with initial letter of user's first name (`personalInfo.firstName`), tap switches to Tab 4 (Profile)
- **Greeting**: Dynamic greeting `SUBSCRIPTION TRACK` + `สวัสดี, คุณ{firstName} 👋`
- **Notification Action**: Bell icon button with route `/dashboard/notifications`
- **Income Action Chip**: Displays `฿XXk` (e.g. `฿35k`), tap triggers `IncomeEditorSheet`

**Implemented 5 Navigation Destinations:**

| Tab | Destination | Content | State binding |
|-----|-------------|---------|---------------|
| 0 | **หน้าแรก** (Dashboard) | Hero payout KPI, Creep Risk indicator, renewal timeline, unused alert | `dashboardSummaryProvider`, `userIncomeProvider` |
| 1 | **รายการ** (Subscriptions) | Search, category filter chips, subscription list, Add FAB, Detail sheet | `visibleSubscriptionsProvider`, `subscriptionListProvider` |
| 2 | **ประหยัด** (Savings) | Yearly saving goal, checklist simulation, cancel selected action | `savingsViewStateProvider`, `savingsActionsProvider` |
| 3 | **ตั้งค่า** (Settings) | แจ้งเตือนก่อนตัดเงิน, ภาษา, สกุลเงิน, โหมดกลางคืน (Light/Dark), เกี่ยวกับแอป | `notificationReminderProvider`, `themeModeProvider` |
| 4 | **โปรไฟล์** (Profile) | ข้อมูลผู้ใช้, ข้อมูลส่วนตัว, ตั้งรหัส PIN, บัตรชำระเงิน, ออกจากระบบ | `personalInfoProvider`, `linkedPaymentCardsProvider` |

**Adaptive Layout Structure:**
```text
Mobile Layout (<900px):
┌─────────────────────────────────────────┐
│ [Avatar] SUBSCRIPTION TRACK     [🔔][฿35k]│ ← MainAppHeader
│ สวัสดี, คุณเน 👋                         │
├─────────────────────────────────────────┤
│                                         │
│       [ Active Tab Content ]            │
│            (IndexedStack)               │
│                                         │
├─────────────────────────────────────────┤
│ [🏠 หน้าแรก] [📋 รายการ] [💰 ประหยัด] [⚙️ ตั้งค่า] [👤 โปรไฟล์] │ ← NavigationBar
└─────────────────────────────────────────┘

Desktop Layout (≥900px):
┌──────────────────────────────────────────────────────────────┐
│ [Avatar] SUBSCRIPTION TRACK                     [🔔][฿35k]   │
├─────────┬────────────────────────────────────────────────────┤
│ [🏠]    │                                                    │
│ [📋]    │               [ Active Tab Content ]               │
│ [💰]    │             (Adaptive 2-column or grid)            │
│ [⚙️]    │                                                    │
│ [👤]    │                                                    │
│ (Rail)  │                                                    │
└─────────┴────────────────────────────────────────────────────┘
```

---

### 5️⃣ Subscriptions Tab (รายการ)

| Property | Value |
|----------|-------|
| **Purpose** | ดูรายการการสมัครสมาชิก ค้นหา กรองหมวดหมู่ จำลองเลือกยกเลิก เพิ่ม และลบรายการ |
| **State** | `visibleSubscriptionsProvider` (derived filtered list), `subscriptionListProvider` |
| **Add Route** | Floating Action Button (+) → `/dashboard/add` |
| **Detail Interaction** | แตะที่การ์ด → เปิด `SubscriptionDetailSheet` (Modal Bottom Sheet) |
| **Delete Interaction** | แตะไอคอนถังขยะ → `ConfirmationDialog` → `PinVerificationDialog` |

**UI Layout:**
```
┌─────────────────────────────────────────┐
│ [🔍 ค้นหาบริการ...]                     │ ← SubscriptionFilterBar
│ [ทั้งหมด] [🎬 สตรีมมิ่ง] [🤖 AI] [☁️ คลาวด์]│
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │ [🎬] Netflix               ฿599/ด. │ │ ← SubscriptionCard
│ │      🟢 บ่อยครั้ง  ความมั่นใจ 92%   │ │   (Tap → DetailSheet)
│ │      [✓] จำลองยกเลิก    [🗑️ ลบ]    │ │   (Trash → Confirm + PIN)
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ [🎵] Spotify               ฿178/ด. │ │
│ │      🟠 ปานกลาง    ความมั่นใจ 65%   │ │
│ │      [✓] จำลองยกเลิก    [🗑️ ลบ]    │ │
│ └─────────────────────────────────────┘ │
│                                         │
│                    [ + เพิ่มรายการ FAB ]│ ← Push to /dashboard/add
└─────────────────────────────────────────┘
```

---

### 6️⃣ Add Subscription Screen & Select Package Flow

| Property | Value |
|----------|-------|
| **Purpose** | เพิ่มรายการสมัครสมาชิกใหม่ โดยเลือกจาก Preset หรือกรอกข้อมูลเอง |
| **Routes** | Form: `/dashboard/add` (`AddSubscriptionScreen`), Preset: `/dashboard/add/select-package` (`SelectPackageScreen`) |
| **Validation** | `SubscriptionFormValidator` (ตรวจชื่อและราคาที่ถูกต้อง) |
| **Security Verification** | `PinVerificationDialog` (ต้องยืนยันรหัส PIN 6 หลักก่อนบันทึกลงระบบ) |

**UI Layout (`AddSubscriptionScreen`):**
```
┌─────────────────────────────────────────┐
│ [✕]          เพิ่มการสมัครสมาชิก         │
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │ 🌟 เลือกจากแพ็กเกจยอดนิยม (Preset)    │ │ ← PresetPickerCard
│ │ Netflix, Spotify, ChatGPT และอื่นๆ  │ │   (Tap → SelectPackageScreen)
│ └─────────────────────────────────────┘ │
│                                         │
│ ชื่อบริการ *                            │
│ ┌─────────────────────────────────────┐ │
│ │ Netflix                             │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ค่าบริการ (บาท) *                       │
│ ┌─────────────────────────────────────┐ │
│ │ 599                                 │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ หมวดหมู่: [ สตรีมมิ่ง ▼ ]               │
│ รอบการเรียกเก็บ: [ รายเดือน (Monthly) ▼ ]│
│                                         │
│ ความถี่ในการใช้งาน:                     │
│ (•) บ่อยครั้ง  ( ) ปานกลาง  ( ) ไม่ได้ใช้ │
│                                         │
│ สีและไอคอน:                             │
│ [🔴][🔵][🟢][🟡][🟣]  [🎬][🎵][🤖][☁️]   │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │         [ บันทึกการสมัครสมาชิก ]      │ │ ← Prompts PinVerificationDialog
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

**Preset Package Catalog (`SelectPackageScreen`):**
- คลัง Preset สำหรับกรอกข้อมูลอัตโนมัติจาก `PresetPackageCatalog.packages`:
  - **Netflix**: ฿599 / เดือน, หมวดสตรีมมิ่ง
  - **Spotify**: ฿178 / เดือน, หมวดสตรีมมิ่ง
  - **ChatGPT Plus**: ฿750 / เดือน, หมวด AI
  - **YouTube Premium**: ฿159 / เดือน, หมวดสตรีมมิ่ง
  - **Google One**: ฿99 / เดือน, หมวดคลาวด์
  - **Adobe Creative Cloud**: ฿599 / เดือน, หมวดสร้างสรรค์
  - **Apple One**: ฿295 / เดือน, หมวดสตรีมมิ่ง
- เมื่อเลือกแพ็กเกจ ระบบจะนำชื่อ ราคา หมวดหมู่ สี และไอคอนมา pre-fill ให้ในหน้า Add ทันที

---

### 7️⃣ Subscription Detail Sheet (ดูรายละเอียด & ตั้งเตือน)

| Property | Value |
|----------|-------|
| **Purpose** | ดูรายละเอียด Subscription, ตั้งค่าการแจ้งเตือนเตือนล่วงหน้า และทำเครื่องหมายยกเลิก |
| **Triggered By** | แตะที่ Subscription card ใน SubscriptionsTab |
| **Component** | `SubscriptionDetailSheet` (Modal Bottom Sheet) |
| **Theme Integration** | รองรับ `theme.cardColor` และ Dynamic Light/Dark mode อัตโนมัติ |

**UI Layout:**
```
┌─────────────────────────────────────────┐
│              ═══════ (Handle)           │
│ [🎬] Netflix                  [รีเซ็ต]  │ ← SubscriptionDetailHeader
│      ฿599 / เดือน                       │
├─────────────────────────────────────────┤
│ สถานะการใช้งาน: 🟢 บ่อยครั้ง             │ ← SubscriptionDetailOverview
│ ค่าความมั่นใจ: 92%                      │
├─────────────────────────────────────────┤
│ 🔔 แจ้งเตือนก่อนตัดเงิน         [ Switch ]│ ← SubscriptionReminderEditor
│    เตือนล่วงหน้า: [ 1 วัน ] [ 3 วัน ]    │
│                 [ 5 วัน ] [ 7 วัน ]    │
├─────────────────────────────────────────┤
│ [✓] ยกเลิกแล้ว (Mark as Cancelled)      │
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │          [ บันทึกการเปลี่ยนแปลง ]     │ │ ← Calls updateSubscription
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

---

### 8️⃣ Add Payment Card & Auto-import Subscriptions

| Property | Value |
|----------|-------|
| **Purpose** | เชื่อมต่อบัตรชำระเงินจำลอง และนำเข้ารายการ Subscription จาก recurring charges ที่ตรวจพบโดยอัตโนมัติ |
| **Navigation Flow** | Tab 4 (Profile) → แตะปุ่ม "เพิ่มบัตร" → `AddPaymentCardSheet` → เลือกบัตรจำลอง → Auto-import |
| **State Owner** | `features/profile/application/payment_card_linking_controller.dart` |
| **Income Integration** | ยอดเงินคงเหลือในบัตร (Balance) จะถูกนำไปคำนวณรวมเป็นยอดเงินของผู้ใช้ใน `userIncomeProvider` โดยอัตโนมัติ |

**Profile + Add Card Bottom Sheet:**
```
┌──────────────────────────────┐
│ บัตรที่เชื่อมต่อ             │
│ ┌──────────────────────────┐ │
│ │ KBank •••• 4242          │ │
│ │ ยอดเงิน: ฿25,000         │ │
│ │ พบ 2 Subscriptions       │ │
│ └──────────────────────────┘ │
│ ┌──────────────────────────┐ │
│ │ SCB •••• 8888            │ │
│ │ ยอดเงิน: ฿15,000         │ │
│ │ พบ 3 Subscriptions       │ │
│ └──────────────────────────┘ │
│                              │
│ [       + เพิ่มบัตร       ] │
└──────────────────────────────┘

          Tap “เพิ่มบัตร”
                 ↓
┌──────────────────────────────┐
│ เพิ่มบัตรชำระเงิน            │
│ เลือกบัตรที่ต้องการเชื่อมต่อ │
├──────────────────────────────┤
│ UOB •••• 1234                │
│ ตรวจพบ 2 รายการ      [เพิ่ม] │
├──────────────────────────────┤
│ Krungsri •••• 5454           │
│ ตรวจพบ 2 รายการ      [เพิ่ม] │
└──────────────────────────────┘
```

**Auto-import flow:**
1. `PaymentCardLinkingController.linkCard(cardId)` ดำเนินการผูกบัตร
2. ตรวจสอบ recurring subscriptions ของบัตรนั้น
3. กรอง Subscription ที่มี `id` ซ้ำกับที่มีอยู่แล้วออก
4. ส่งรายการใหม่เข้าสู่ `subscriptionListProvider` เพื่อ sync ข้อมูลทั่วทั้งแอป
5. ยอดเงินคงเหลือของบัตรจะรวมเข้ากับ `userIncomeProvider` เพื่อนำไปคำนวณ Creep Risk ใน Dashboard ทันที

---

### 9️⃣ Profile Tab & Personal Info Management

| Property | Value |
|----------|-------|
| **Purpose** | แสดงข้อมูลประจำตัว, จัดการข้อมูลส่วนตัว, ตั้งค่ารหัส PIN, จัดการบัตร และออกจากระบบ |
| **State Owners** | `personalInfoProvider`, `securityPinProvider`, `userIncomeProvider`, `authProvider` |

**UI Layout:**
```
┌──────────────────────────────┐
│ [👤 Avatar]                  │ ← ProfileIdentityCard
│ John Doe                     │
│ john.doe@example.com         │
├──────────────────────────────┤
│ การตั้งค่าโปรไฟล์            │ ← ProfileSettingsCard
│ ├─ รายได้ต่อเดือน: ฿35,000    │   (Tap → IncomeEditorSheet)
│ ├─ ตั้งรหัส PIN: ••••••       │   (Tap → ChangePinDialog)
│ └─ ข้อมูลส่วนตัว              │   (Tap → PersonalInfoSheet)
├──────────────────────────────┤
│ บัตรที่เชื่อมต่อ             │ ← LinkedAccountsCard
│ [KBank •••• 4242 - ฿25,000]  │
│ [       + เพิ่มบัตร        ] │
├──────────────────────────────┤
│                              │
│ ┌──────────────────────────┐ │
│ │ [🚪 ออกจากระบบ]          │ │ ← _LogoutButton (Clears state → Onboarding)
│ └──────────────────────────┘ │
└──────────────────────────────┘
```

**Personal Info Sheet (`PersonalInfoSheet`):**
- Modal Bottom Sheet สำหรับแก้ไข:
  - ชื่อ (First Name)
  - นามสกุล (Last Name)
  - เบอร์โทรศัพท์ (Phone Number)
  - วันเกิด (Birth Date)
- ข้อมูลชื่อจะ sync ขึ้น Header ทันที (`สวัสดี, คุณ{firstName} 👋`)

---

### 🔟 Settings Tab (ตั้งค่า)

| Property | Value |
|----------|-------|
| **Purpose** | ตั้งค่าระบบแจ้งเตือน, โหมดสี (Light/Dark Theme), ภาษา และข้อมูลเกี่ยวกับแอป |
| **State Owners** | `notificationReminderProvider`, `themeModeProvider` |

**UI Layout:**
```
┌──────────────────────────────┐
│ [🔔] แจ้งเตือนก่อนตัดเงิน     │ ← SwitchListTile
│      [ Switch: เปิดใช้งาน ]   │
├──────────────────────────────┤
│ [🌐] ภาษา (Language)   [ไทย] │ ← Modal: เร็วๆ นี้
│ [💱] สกุลเงินเริ่มต้น  [THB] │ ← Modal: เร็วๆ นี้
│ [🌙] โหมดกลางคืน              │ ← SwitchListTile (Light/Dark Theme Mode)
│      [ Switch: เปิด/ปิด ]     │
├──────────────────────────────┤
│ [ℹ️] เกี่ยวกับแอป             │ ← Dialog: Subscription Track v1.0.0
└──────────────────────────────┘
```

---

### 1️⃣1️⃣ Notification Center Screen

| Property | Value |
|----------|-------|
| **Purpose** | ศูนย์รวมการแจ้งเตือน รอบบิลที่ใกล้จะถึง เตือนบริการที่ไม่ได้ใช้งาน |
| **Route** | `/dashboard/notifications` (เข้าถึงได้จากกระดิ่งใน Header) |
| **Controller** | `notificationCenterProvider` (`NotificationCenterController`) |

**UI Layout:**
```
┌──────────────────────────────┐
│ [←] การแจ้งเตือน [✓ อ่านหมด]  │ ← AppBar
├──────────────────────────────┤
│ [ทั้งหมด (5)] [ยังไม่อ่าน (2)]│ ← Filter Tabs
│ [ระบบ (1)]                   │
├──────────────────────────────┤
│ ┌──────────────────────────┐ │
│ │ 🔵 [🔔] Netflix ต่ออายุในอีก 3 วัน │
│ │    รอบบิลถัดไป: 28 ม.ค.    │
│ └──────────────────────────┘ │
│ ┌──────────────────────────┐ │
│ │ ⚪ [💡] Google One ไม่ได้ใช้งาน│
│ │    ประหยัดได้ ฿99/เดือน    │
│ └──────────────────────────┘ │
└──────────────────────────────┘
```

---

### 1️⃣2️⃣ Security, Verification & Confirmation Dialogs

| Component | Purpose & Behavior | State Binding |
|-----------|-------------------|---------------|
| `PinVerificationDialog` | Dialog กรอกรหัส PIN 6 หลักเพื่อยืนยันรายการ พร้อมระบบสั่น (Shake animation) เมื่อกรอกผิด | `securityPinProvider` (Default PIN: `123456`) |
| `ChangePinDialog` | Dialog เปลี่ยนรหัส PIN 3 ขั้นตอน: ยืนยัน PIN ปัจจุบัน → กรอก PIN ใหม่ 6 หลัก → ยืนยัน PIN ใหม่อีกครั้ง | `securityPinProvider.notifier.setPin(...)` |
| `ConfirmationDialog` | Reusable Generic Dialog สำหรับยืนยันการลบหรือการกระทำอันตราย มีหัวข้อ ข้อความ และปุ่มสไตล์ Danger | ส่งคืน `Future<bool>` |

**Widgets:**
- `TabBar` (filter)
- `ListView.builder` (notification list)
- `Dismissible` (swipe to dismiss)
- Custom notification tile widget

**Mock Data:**
```dart
🔄 List<Notification> mockNotifications = [
  Notification(
    id: '1',
    type: 'upcoming_bill',
    title: 'Netflix Upcoming Renewal',
    body: 'Renews in 3 days',
    scheduledAt: DateTime.now().add(Duration(days: 3)),
    isRead: false,
  ),
  // ... more
];
```

---

## Widgets Inventory

### Existing Widgets (Keep & Refactor)

| Widget | File | Status | Changes |
|--------|------|--------|---------|
| `KPICard` | `kpi_card.dart` | ✅ Keep | Update hover animation for mobile |
| `SubscriptionTile` | `subscription_tile.dart` | 🔄 Refactor | Add swipe-to-edit, use callback instead of setState |
| `SavingSimulationCard` | `saving_simulation_card.dart` | ✅ Keep | Connect to provider, remove hardcoded logic |
| `SubscriptionFilterBar` | `subscription_filter_bar.dart` | ✅ Keep | Connect to filterProvider for state |
| `PINVerificationDialog` | `pin_verification_dialog.dart` | ✅ Keep | 🔄 Mock PIN verification |
| `ConfirmationDialog` | `common/confirmation_dialog.dart` | ✅ Implemented | Dynamic copy/icon, danger style, `Future<bool>` result; used by Subscriptions/Savings |

### New Widgets to Create

| Widget | Purpose | Location |
|--------|---------|----------|
| `CustomAppBar` | Reusable top bar with title, back button, profile icon | `widgets/custom_app_bar.dart` |
| `PackageCard` | Display preset package with icon, name, price | `widgets/package_card.dart` |
| `CategoryChip` | Filter chip for category (reusable filter button) | `widgets/category_chip.dart` |
| `BiometricPrompt` | Face ID / Fingerprint detection UI | `widgets/biometric_prompt.dart` |
| `LoadingSkeleton` | Shimmer/skeleton loading state | `widgets/loading_skeleton.dart` |
| `ErrorStateWidget` | Fallback UI for errors | `widgets/error_state_widget.dart` |
| `EmptyStateWidget` | Placeholder when no subscriptions | `widgets/empty_state_widget.dart` |
| `NotificationTile` | Display single notification | `widgets/notification_tile.dart` |
| `OnboardingPageView` | Reusable onboarding page template | `widgets/onboarding_page_view.dart` |
| `SettingsListTile` | Enhanced ListTile for settings | `widgets/settings_list_tile.dart` |

### Reusable Components (Helper Widgets)

```dart
// widgets/common/
├── bottom_sheet_header.dart    // Reusable bottom sheet top
├── confirmation_dialog.dart    // ✅ Generic primary/danger confirmation
├── snack_bar_helper.dart       // Custom snack bars
├── divider_section.dart        // Section divider with label
└── gradient_button.dart        // Gradient button (CTA)
```

---

## BLoC/Cubit vs Riverpod Recommendation

### Decision: **Use Riverpod**

**Why?**
1. **Simpler for 3-person team** - Faster onboarding than BLoC
2. **Less boilerplate** - Fewer files per feature
3. **Built-in async support** - FutureProvider handles loading/error automatically
4. **Testability** - Easy to mock providers in tests
5. **Scoped state** - Family modifiers for multiple instances

### Riverpod Usage Patterns

**Project convention (current):** ใช้ `NotifierProvider` สำหรับ synchronous UI state และ `AsyncNotifierProvider` สำหรับ mutable async data หลีกเลี่ยงการเพิ่ม `StateProvider`/`StateNotifierProvider` ใหม่ เพราะเป็น legacy API ใน Riverpod 3 สำหรับโปรเจกต์นี้

```dart
final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => InMemorySubscriptionRepository(),
);

final subscriptionListProvider =
    AsyncNotifierProvider<SubscriptionListController, List<Subscription>>(
  SubscriptionListController.new,
);
```

ตัวอย่าง Pattern 1-3 ด้านล่างเป็นแนวคิดจาก proposal เดิม ให้ยึด provider API ปัจจุบันข้างต้นเมื่อนำไป implement

#### Pattern 1: Simple State (Toggles, Counters)
```dart
// providers/filter_provider.dart
final selectedFilterProvider = StateProvider<String>((ref) {
  return 'all'; // default
});

// Usage in widget
class FilterBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedFilterProvider);
    
    return GestureDetector(
      onTap: () => ref.read(selectedFilterProvider.notifier).state = 'streaming',
      child: Text('Filter: $selected'),
    );
  }
}
```

#### Pattern 2: Async Data (API Calls)
```dart
// providers/subscription_provider.dart
final subscriptionListProvider = FutureProvider<List<Subscription>>((ref) async {
  // 🔄 Mock: hardcoded + delay
  await Future.delayed(Duration(milliseconds: 500));
  return [
    Subscription(id: '1', name: 'Netflix', price: 599),
    Subscription(id: '2', name: 'Spotify', price: 178),
  ];
});

// Usage in widget
class SubscriptionList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(subscriptionListProvider);
    
    return asyncValue.when(
      data: (subscriptions) => ListView(
        children: subscriptions.map((sub) => SubscriptionTile(sub)).toList(),
      ),
      loading: () => LoadingSkeleton(),
      error: (err, stack) => ErrorStateWidget(error: err),
    );
  }
}
```

#### Pattern 3: Complex State (Notifier)
```dart
// providers/add_subscription_provider.dart
class AddSubscriptionNotifier extends StateNotifier<AddSubscriptionState> {
  AddSubscriptionNotifier() : super(AddSubscriptionState());
  
  Future<void> submitForm(String name, double price) async {
    state = state.copyWith(isLoading: true);
    try {
      // 🔄 Mock: save to local storage
      await _saveSubscription(name, price);
      state = state.copyWith(
        isLoading: false,
        savedSubscription: newSub,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final addSubscriptionProvider = StateNotifierProvider((ref) {
  return AddSubscriptionNotifier();
});

// Usage
class AddForm extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addSubscriptionProvider);
    
    return ElevatedButton(
      onPressed: () => ref.read(addSubscriptionProvider.notifier)
          .submitForm(nameCtrl.text, priceCtrl.text),
      child: state.isLoading ? CircularProgressIndicator() : Text('Add'),
    );
  }
}
```

#### Pattern 4: Derived State (Computed)
```dart
// No need to manually rebuild when dependencies change
final filteredSubscriptionsProvider = Provider<List<Subscription>>((ref) {
  final all = ref.watch(subscriptionListProvider).value ?? [];
  final filter = ref.watch(selectedFilterProvider);
  
  return all.where((s) => s.category == filter).toList();
});
```

### When to Use StateNotifier vs Provider

| Use Case | Choose |
|----------|--------|
| Simple toggle (on/off) | `StateProvider` |
| Read-only computed value | `Provider` |
| Async data fetch (GET) | `FutureProvider` |
| Complex logic with multiple methods | `StateNotifierProvider` |
| Real-time data stream | `StreamProvider` |
| Family (parameterized state) | Any + `.family` modifier |

---

## Mock Data Structure

### Current mock source

Mock subscription ที่ใช้งานจริงอยู่ใน `InMemorySubscriptionRepository` ซึ่ง seed Netflix Premium, Spotify Premium, Google One Cloud, ChatGPT Plus และ Adobe Creative Cloud พร้อม delay เริ่มต้น 300 ms เพื่อทดสอบ loading state ข้อมูลที่แสดงในตัวอย่างด้านล่างเป็น sample จาก proposal เดิมและราคา/ID อาจไม่ตรง runtime data

### 1. Mock Users

```dart
// services/mock_data/mock_user.dart
class MockUserService {
  static final User mockUser = User(
    id: 'mock-user-123',
    email: 'user@example.com',
    name: 'John Doe',
    avatar: 'https://i.pravatar.cc/150?img=1',
    income: 35000,
    currency: 'THB',
    settings: UserSettings(
      notificationDays: 3,
      biometricEnabled: true,
      language: 'th',
    ),
  );
}
```

### 2. Mock Subscriptions

```dart
// services/mock_data/mock_subscriptions.dart
final mockSubscriptions = [
  Subscription(
    id: '1',
    name: 'Netflix',
    price: 599,
    billingPeriod: BillingPeriod.monthly,
    category: 'streaming',
    nextBillingDate: DateTime.now().add(Duration(days: 5)),
    usageStatus: UsageStatus.frequent,
    confidence: 92,
    isSelected: false,
  ),
  Subscription(
    id: '2',
    name: 'Spotify',
    price: 178,
    billingPeriod: BillingPeriod.monthly,
    category: 'streaming',
    nextBillingDate: DateTime.now().add(Duration(days: 12)),
    usageStatus: UsageStatus.moderate,
    confidence: 65,
    isSelected: false,
  ),
  Subscription(
    id: '3',
    name: 'ChatGPT Plus',
    price: 750,
    billingPeriod: BillingPeriod.monthly,
    category: 'ai',
    nextBillingDate: DateTime.now().add(Duration(days: 8)),
    usageStatus: UsageStatus.frequent,
    confidence: 88,
    isSelected: false,
  ),
  Subscription(
    id: '4',
    name: 'Google One',
    price: 99,
    billingPeriod: BillingPeriod.monthly,
    category: 'cloud',
    nextBillingDate: DateTime.now().add(Duration(days: 3)),
    usageStatus: UsageStatus.unused,
    confidence: 15,
    isSelected: false,
  ),
  Subscription(
    id: '5',
    name: 'Adobe Creative Cloud',
    price: 599,
    billingPeriod: BillingPeriod.monthly,
    category: 'creative',
    nextBillingDate: DateTime.now().add(Duration(days: 20)),
    usageStatus: UsageStatus.moderate,
    confidence: 45,
    isSelected: false,
  ),
];
```

### 3. Preset Package Catalog (Active in Add Subscription Flow)

คลังข้อมูลแพ็กเกจพรีเซ็ต (`apps/mobile/lib/features/subscriptions/domain/preset_package_catalog.dart`) ที่ใช้งานจริงในหน้า `SelectPackageScreen`:

```dart
class PresetPackageCatalog {
  PresetPackageCatalog._();

  static const List<PresetPackage> packages = [
    PresetPackage(
      name: 'Netflix',
      price: 599,
      billingPeriod: 'Monthly',
      category: 'streaming',
    ),
    PresetPackage(
      name: 'Spotify',
      price: 178,
      billingPeriod: 'Monthly',
      category: 'streaming',
    ),
    PresetPackage(
      name: 'ChatGPT Plus',
      price: 750,
      billingPeriod: 'Monthly',
      category: 'ai',
    ),
    PresetPackage(
      name: 'YouTube Premium',
      price: 159,
      billingPeriod: 'Monthly',
      category: 'streaming',
    ),
    PresetPackage(
      name: 'Google One',
      price: 99,
      billingPeriod: 'Monthly',
      category: 'cloud',
    ),
    PresetPackage(
      name: 'Adobe Creative Cloud',
      price: 599,
      billingPeriod: 'Monthly',
      category: 'creative',
    ),
    PresetPackage(
      name: 'Apple One',
      price: 295,
      billingPeriod: 'Monthly',
      category: 'streaming',
    ),
  ];
}
```

### 4. Mock Notifications

```dart
// services/mock_data/mock_notifications.dart
final mockNotifications = [
  AppNotification(
    id: '1',
    type: 'upcoming_bill',
    title: 'Netflix renews in 3 days',
    body: 'Mon, 28 Jan 2024 - ฿599',
    scheduledAt: DateTime.now().add(Duration(days: 3)),
    isRead: false,
  ),
  AppNotification(
    id: '2',
    type: 'unused_warning',
    title: 'Google One not used lately',
    body: 'Consider cancelling to save ฿99/month',
    scheduledAt: DateTime.now().subtract(Duration(days: 2)),
    isRead: true,
  ),
  // ... more
];
```

### 5. Mock Usage Logs (Phase 2)

```dart
// services/mock_data/mock_usage_logs.dart
final mockUsageLogs = [
  UsageLog(
    id: '1',
    subscriptionId: '1', // Netflix
    date: DateTime.now(),
    screenTimeMinutes: 120,
    appOpenCount: 5,
  ),
  UsageLog(
    id: '2',
    subscriptionId: '2', // Spotify
    date: DateTime.now(),
    screenTimeMinutes: 45,
    appOpenCount: 8,
  ),
  // ...
];
```

### Storage Strategy

```dart
// services/storage_service.dart
class StorageService {
  // 🔄 Mock: Use in-memory for MVP
  static final Map<String, dynamic> _store = {};
  
  static Future<void> save(String key, dynamic value) async {
    await Future.delayed(Duration(milliseconds: 50));
    _store[key] = value;
  }
  
  static Future<T?> get<T>(String key) async {
    await Future.delayed(Duration(milliseconds: 50));
    return _store[key];
  }
  
  // Future: Replace with SharedPreferences + Hive
}
```

---

## Navigation Flow

### Current Navigation Structure (GoRouter + Riverpod Integration)

```dart
// apps/mobile/lib/app/routing/app_router.dart
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier();
  ref.listen<AppFlowState>(appFlowProvider, (_, __) => refreshNotifier.refresh());

  return GoRouter(
    initialLocation: RouteConstants.dashboard, // Direct access for dev
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final location = state.matchedLocation;
      // Default to dashboard when hitting '/' or '/splash'
      if (location == '/' || location == RouteConstants.splash) {
        return RouteConstants.dashboard;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: RouteConstants.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteConstants.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteConstants.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteConstants.dashboard,
        builder: (context, state) => const MainNavigationShell(),
        routes: [
          GoRoute(
            path: RouteConstants.notifications, // 'notifications' -> /dashboard/notifications
            builder: (context, state) => const NotificationCenterScreen(),
          ),
          GoRoute(
            path: RouteConstants.addSubscription, // 'add' -> /dashboard/add
            builder: (context, state) => const AddSubscriptionScreen(),
            routes: [
              GoRoute(
                path: RouteConstants.selectPackage, // 'select-package' -> /dashboard/add/select-package
                builder: (context, state) => const SelectPackageScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
```

### Programmatic Navigation Examples

```dart
// Open Notification Center from header
context.push('/dashboard/notifications');

// Open Add Subscription Screen from FAB
final newSub = await context.push<Subscription>('/dashboard/add');

// Open Select Package Screen from Add Form
final preset = await Navigator.push<PresetPackage>(
  context,
  MaterialPageRoute(builder: (_) => const SelectPackageScreen()),
);

// Switch main tabs in shell
ref.read(currentTabProvider.notifier).select(1); // 0: Dashboard, 1: Subscriptions, 2: Savings, 3: Settings, 4: Profile

// Logout and redirect to onboarding
ref.read(onboardingProvider.notifier).setCompleted(false);
await ref.read(authProvider.notifier).logout();
context.go(RouteConstants.onboarding);
```

---

## Design System & Theme

### Color Palette (Dark & Light Mode Support)

```dart
// apps/mobile/lib/core/theme/app_colors.dart
class AppColors {
  // Primary Brand
  static const Color primary = Color(0xFF6366F1);       // Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  
  // Semantic Accents
  static const Color success = Color(0xFF10B981);       // Emerald green
  static const Color warning = Color(0xFFF59E0B);       // Amber
  static const Color danger = Color(0xFFEF4444);        // Red
  static const Color info = Color(0xFF3B82F6);          // Blue

  // Dark Palette
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  
  // Light Palette
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
}
```

### Theme Mode Controller

- ควบคุมธีมด้วย `themeModeProvider` (`apps/mobile/lib/app/application/theme_mode_controller.dart`)
- สลับระหว่าง `ThemeMode.light` และ `ThemeMode.dark` ได้ทันทีจาก Switch ใน `SettingsTab`
- หน้าจอพิเศษแบบ Branded-Dark: `SplashScreen` และ `OnboardingScreen` ถูกออกแบบให้เป็น Dark-Themed ตลอดเวลาเพื่อเอกลักษณ์ของแบรนด์

---

## Summary: MVP Frontend Screens

### Total Screens & Modals: **13 Components**

| # | Screen / Modal Name | Type | Status | Priority |
|---|---------------------|------|--------|----------|
| 1 | **Splash** | Setup | ✅ IMPLEMENTED | High |
| 2 | **Onboarding (3 Slides)** | Setup | ✅ IMPLEMENTED | High |
| 3 | **Login (OAuth Mock & Guest)** | Auth | ✅ IMPLEMENTED | High |
| 4 | **Dashboard & Adaptive Shell** | Core | ✅ IMPLEMENTED | High |
| 5 | **Subscriptions Tab** | Core | ✅ IMPLEMENTED | High |
| 6 | **Add Subscription Screen** | Core | ✅ IMPLEMENTED | High |
| 7 | **Select Package Screen (Presets)** | Core | ✅ IMPLEMENTED | High |
| 8 | **Subscription Detail Sheet** | Modal Sheet | ✅ IMPLEMENTED | High |
| 9 | **Savings Tab** | Simulation | ✅ IMPLEMENTED | Medium |
| 10 | **Settings Tab (Reminder, Theme Mode)** | Settings | ✅ IMPLEMENTED | Medium |
| 11 | **Profile Tab & Personal Info Sheet** | Profile | ✅ IMPLEMENTED | Medium |
| 12 | **Add Payment Card Sheet & Auto-import** | Profile/Core | ✅ IMPLEMENTED | High |
| 13 | **Notification Center Screen** | Notifications | ✅ IMPLEMENTED | Medium |
| 14 | **Dialogs (PIN Verify, Change PIN, Confirm)** | Security/Modals | ✅ IMPLEMENTED | High |

---

## Development Roadmap (Status: Frontend MVP Feature-Complete)

### Week 1: Setup & Foundation
- [x] Setup Riverpod package + GoRouter
- [x] Create models (User, Subscription, PaymentCard, AppNotification, PresetPackage)
- [x] Create in-memory repositories and mock data sources
- [x] Setup theme & color system (Light & Dark themes)
- [x] Setup AppHeader and NavigationShell with 5 destinations

### Week 2: Auth & Onboarding
- [x] Splash screen with state-driven redirect
- [x] Onboarding flow with PageView & progress indicator
- [x] Login screen (Google, Apple, Guest mode)
- [x] Auth and app-flow providers (Riverpod `AsyncNotifierProvider`)
- [x] Deep-linking support for development and testability

### Week 3: Dashboard & Subscriptions Refactor
- [x] Dashboard 5-destination adaptive navigation shell
- [x] Repository-backed subscription list provider (`AsyncNotifierProvider`)
- [x] Search and typed category derived filtering
- [x] Savings checklist selection and dynamic Creep Score
- [x] Tablet/desktop layout optimization (NavigationRail, adaptive grid)

### Week 4: Card Import & CRUD Features
- [x] Add Payment Card bottom sheet ใน Profile (`AddPaymentCardSheet`)
- [x] Mock cards (KBank, SCB, UOB, Krungsri) พร้อม recurring subscriptions
- [x] Auto-import subscriptions without duplicate IDs
- [x] Auto-sum credit card balance to user income
- [x] Add Subscription screen with validation (`AddSubscriptionScreen`)
- [x] Preset Package Catalog and picker screen (`SelectPackageScreen`)

### Week 5: Profile, Settings & Security
- [x] Profile tab with `ProfileIdentityCard` and `ProfileSettingsCard`
- [x] Personal Info modal sheet (`PersonalInfoSheet`)
- [x] Settings tab with notification reminder toggle
- [x] Dynamic Light / Dark theme mode toggle via `themeModeProvider`
- [x] 6-digit PIN verification dialog with shake animation (`PinVerificationDialog`)
- [x] 3-step PIN change dialog (`ChangePinDialog`)
- [x] Generic confirmation dialog (`ConfirmationDialog`)

### Week 6: Notification Center & Polish
- [x] Notification Center screen (`/dashboard/notifications`)
- [x] Notification Center controller with filter tabs (All, Unread, System)
- [x] Mark notification as read and Mark all as read
- [x] App header notification badge and shortcut button
- [x] UI polish & animations across Light and Dark themes

### Week 7-8: Testing & Handoff
- [x] Unit tests for application controllers and providers
- [x] Widget tests for navigation, dialogs, and themes
- [x] Feature-first architecture and provider reference documentation
- [x] Final Frontend MVP validation

---

*End of Frontend Screens Specification Document*  
**Status: Frontend MVP Feature-Complete 🚀**
