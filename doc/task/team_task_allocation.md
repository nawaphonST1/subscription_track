# 👥 Team Task Allocation — Subscription Track Frontend

**Project:** Subscription Track MVP  
**Team Size:** 3 developers  
**Total Tasks:** 12 major screens + 10+ widgets  
**Duration:** 8 weeks  
**Date:** 28 July 2026

**Implementation status updated:** 12 September 2026 (Frontend MVP Feature-Complete — 5-Tab Shell, Add/Preset Packages, PIN Security & Theme Mode)

---

## 📊 Task Difficulty Analysis

### Difficulty Levels

| Level | Examples | Complexity | Est. Hours |
|-------|----------|-----------|-----------|
| ⭐ **Easy** | Splash, Profile, Notifications | UI only, no complex logic | 6-8 hrs |
| ⭐⭐ **Medium** | Login, Forms, Settings, Dialogs | Logic + validation + navigation | 12-16 hrs |
| ⭐⭐⭐ **Hard** | Dashboard, Add Subscription via Card, Add & Preset Package Flow | Cross-feature import, async state, duplicate prevention | 20-28 hrs |

### Screen Complexity Breakdown

| Screen | Difficulty | Why | Hours | Status |
|--------|-----------|-----|-------|--------|
| **Splash** | ⭐ | Static UI, state-driven redirect | 4 | ✅ Completed |
| **Onboarding** | ⭐⭐ | PageView, dots/progress indicator, navigation flow | 12 | ✅ Completed |
| **Login** | ⭐⭐ | OAuth mock (Google, Apple, Guest), auth provider setup | 14 | ✅ Completed |
| **Dashboard (Shell + 5 Tabs)** | ⭐⭐⭐ | Riverpod providers, responsive layout, 5 integrated tabs | 24 | ✅ Completed |
| **Add Subscription via Card** | ⭐⭐⭐ | Card linking, recurring-charge detection, auto-import to subscriptions | 26 | ✅ Completed |
| **Mock Card Picker** | ⭐⭐ | Card list, loading/error states and detected-item summary | 12 | ✅ Completed |
| **Add Subscription & Select Package** | ⭐⭐⭐ | Preset catalog, custom appearance, usage status, PIN verification | 20 | ✅ Completed |
| **Subscription Detail Sheet** | ⭐⭐ | Detail sheet, reminder editor (days/toggle), mark cancelled | 12 | ✅ Completed |
| **Profile & Personal Info** | ⭐⭐ | Identity card, personal info sheet, credit card balance integration | 10 | ✅ Completed |
| **Settings** | ⭐⭐ | Reminder toggle, Light/Dark theme mode switch, mock localization | 12 | ✅ Completed |
| **Notification Center** | ⭐ | ListView, tabs (All, Unread, System), mark read/all | 8 | ✅ Completed |
| **Dialogs (PIN, Change PIN, Confirm)** | ⭐⭐ | PIN verification (6-digit), change PIN dialog, reusable confirmation | 12 | ✅ Completed |

---

## 👨‍💻 Team Allocation (3 People)

### 👤 Team Members Mapping
- **Person 1**: เน (Lead Frontend Developer)
- **Person 2**: นะ (Card Import & Subscription Creation Lead)
- **Person 3**: อาทิตย์ (Auth, User Management & Security Lead)

### ✅ Distribution Strategy

Each person gets:
- **1 Hard task** (Heavy lifting) OR **2 Medium tasks** (Lead contribution)
- **1-2 Medium tasks** (Core work)
- **1 Easy task** (Polish/Quick win)

---

## 🎯 PERSON 1: เน (Lead Frontend Developer)

### 📋 Tasks (5 items | 54 hours total)

| # | Task | Difficulty | Est. Hours | Status |
|---|------|-----------|-----------|--------|
| 1 | **Dashboard & App Shell** | ⭐⭐⭐ Hard | 24 | ✅ Completed (5-tab shell + responsive rail/bar) |
| 2 | **Dialogs** (Confirm, PIN, Change PIN) | ⭐⭐ Medium | 12 | ✅ Completed (`ConfirmationDialog`, `PinVerificationDialog`, `ChangePinDialog`) |
| 3 | **Onboarding** | ⭐⭐ Medium | 12 | ✅ Completed (3 slides with progress bar) |
| 4 | **Splash** | ⭐ Easy | 4 | ✅ Completed (State-driven initialization) |
| 5 | **Theme System** (Light / Dark Mode) | ⭐ Easy | 2 | ✅ Completed (`ThemeModeController` + Light/Dark palettes) |

### 📝 Responsibilities

**Person 1 (เน)'s Role:**
- 🏆 Lead Frontend Architecture
- 📐 Setup Riverpod providers (subscription, filter, theme)
- 🎨 Define shared theme & color system
- 🧩 Create reusable widgets (AppBar, Loading, Error, Empty states)
- ✅ Refactor Dashboard from existing code
- 📱 Ensure responsive design (mobile + desktop)
- 👁️ Code review for others

### 📌 Key Dependencies

```
Splash (Week 1)
    ↓
Onboarding (Week 1-2)
    ↓
Dashboard ← Refactor (Week 3-4) [BLOCKING for others]
    ↓
Dialogs (Week 4) [Used by Person 2 & 3 for Add/Edit]
```

### 💻 Tasks Breakdown

#### Week 1: Splash + Setup
```
[ Day 1-2 ] Splash Screen
  - Static logo + app name
  - แสดง loading ระหว่าง app flow initialization
  - GoRouter state-driven redirect (ไม่มี hardcoded delayed navigation)

[ Day 3-5 ] Setup & Foundation
  - Install Riverpod + GoRouter
  - Create color system & typography
  - Create mock data services
  - Create reusable widgets:
    * CustomAppBar (with back, title, profile icon)
    * LoadingSkeleton (shimmer)
    * ErrorStateWidget
    * EmptyStateWidget
```

#### Week 2: Onboarding
```
[ Day 1-3 ] Onboarding Screen
  - PageView with 3 pages
  - Dots indicator
  - Skip button logic
  - Next/Get Started buttons
  - Auto-navigation to Login

[ Day 4-5 ] Polish
  - Smooth transitions
  - Test all navigation flows
```

#### Week 3-4: Dashboard Refactor (MAIN TASK)
```
[ Week 3 ]
  Day 1-2: Setup providers and data boundary ✅
    - SubscriptionRepository + InMemorySubscriptionRepository
    - subscriptionListProvider (AsyncNotifierProvider)
    - currentTab/search/category/income/reminder NotifierProviders
    - visibleSubscriptionsProvider (derived AsyncValue)
  
  Day 3-5: Refactor Dashboard Widget ✅ (mobile)
    - MainNavigationShell + IndexedStack 4 tabs
    - Dashboard / Subscriptions / Savings / Profile tab views
    - Replace hardcoded data with repository-backed providers
    - Widget tests for tab, search/category and income/Creep binding

[ Week 4 ]
  Day 1-3: Integrate components
    - Connect KPI/Creep/renewal/unused alert to providers ✅
    - Connect subscription search/category/list ✅
    - Connect saving simulation checklist and totals ✅
    - Add loading/error/refresh states ✅
    - Tablet/desktop optimization ✅ (NavigationRail + adaptive columns/grid)
  
  Day 4-5: Polish & test
    - Responsive design verification
    - Animation smoothness
    - Error handling
```

#### Week 4: Dialogs
```
[ Day 1-2 ] PIN Verification Dialog ✅
  - 6-digit PIN input with obscured display and focus auto-request
  - Animated shake effect on incorrect entry
  - Integrated with securityPinProvider (default '123456')
  - Used in Add Subscription & Delete Subscription flows

[ Day 2-3 ] Change PIN Dialog ✅
  - 3-step PIN update: current PIN verification, new 6-digit PIN entry, confirmation
  - Persistent state in securityPinProvider
  - Accessible via Profile Settings

[ Day 4 ] Confirm Dialog (Generic) ✅
  - Reusable for delete confirmation
  - Dynamic title, message, icon and action buttons
  - Primary/danger style + Future<bool> result
  - Integrated with Subscriptions and Savings flows
```

---

## 👨‍💼 PERSON 2: นะ (Card Import & Subscription Creation Lead)

### 📋 Tasks (4 items | 66 hours total)

| # | Task | Difficulty | Est. Hours | Status |
|---|------|-----------|-----------|--------|
| 1 | **Add Subscription via Card** | ⭐⭐⭐ Hard | 26 | ✅ Completed (Card linking & auto-import) |
| 2 | **Mock Card Picker** | ⭐⭐ Medium | 12 | ✅ Completed in Profile (`AddPaymentCardSheet`) |
| 3 | **Add Subscription & Select Package** | ⭐⭐⭐ Hard | 20 | ✅ Completed (`AddSubscriptionScreen` + `SelectPackageScreen`) |
| 4 | **Notification Center** | ⭐ Easy | 8 | ✅ Completed (`NotificationCenterScreen` + controller) |

### 📝 Responsibilities

**Person 2 (นะ)'s Role:**
- 💳 ดูแล flow เพิ่มบัตรและการเชื่อมต่อ Card/Open Banking API ในอนาคต
- 🔄 แปลง recurring charges เป็น Subscription ผ่าน application boundary
- ➕ สร้างหน้าเพิ่มการสมัครสมาชิก (`AddSubscriptionScreen`) พร้อมเลือกแพ็กเกจพรีเซ็ต (`SelectPackageScreen`)
- ✅ ป้องกัน duplicate import และจัดการ loading/error/rollback
- 🔔 พัฒนา Notification Center พร้อมตัวกรอง (ทั้งหมด, ยังไม่อ่าน, ระบบ)
- 🧪 Unit test card repository, mapping และ import logic

### 📌 Key Dependencies

```
Person 1: Dashboard + Subscription state boundary (Week 3-4)
    ↓
Mock Card Repository + Picker (Week 2-3)
    ↓
Add Subscription via Card (Week 3-4)
    ↓
Add Subscription Screen + Select Package (Week 4-5)
    ↓
Notification Center (Week 5)
```

### 💻 Tasks Breakdown

#### Week 2: Mock Card Picker (Start Early)
```
[ Day 1-3 ] Card data source ✅
  - สร้าง PaymentCardRepository contract
  - Seed KBank, SCB, UOB และ Krungsri
  - กำหนด recurring subscriptions ที่ตรวจพบแยกตามบัตร

[ Day 4-5 ] Profile Flow ✅
  - แสดง linked cards ใน Profile
  - เปิด Add Payment Card bottom sheet
  - แสดงจำนวน Subscription ที่ตรวจพบก่อนเพิ่ม
```

#### Week 3-4: Add Subscription via Card (Main Task)
```
[ Week 3 ]
  Day 1-2: Setup application flow ✅
    - PaymentCardLinkingController เป็น owner ของการผูกบัตร
    - PaymentCardRepository override ได้ใน tests
    - UI ไม่ import data implementation โดยตรง

  Day 3-5: Auto-import ✅
    - Map DetectedSubscription → Subscription
    - Import ผ่าน SubscriptionListController
    - ข้าม id ที่มีอยู่แล้วเพื่อป้องกันข้อมูลซ้ำ
    - Profile, Dashboard และ Subscriptions อ่าน state ชุดเดียวกัน

[ Week 4 ]
  Day 1-3: UX states ✅
    - Loading, empty และ error state ของ card picker
    - Disable ปุ่มอื่นระหว่างกำลังเพิ่มบัตร
    - Success SnackBar ระบุจำนวนรายการที่นำเข้า

  Day 4-5: Card Linking Integration ✅
    - เชื่อมต่อยอดเงินคงเหลือในบัตร (balance) เข้ากับ userIncomeProvider อัตโนมัติ
```

#### Week 4-5: Add Subscription & Select Package Screens
```
[ Day 1-2 ] Preset Package Catalog & Picker ✅
  - PresetPackageCatalog รวบรวมบริการยอดนิยม (Netflix, Spotify, ChatGPT Plus, YouTube Premium, etc.)
  - SelectPackageScreen รองรับการค้นหาและเลือกแพ็กเกจ
  - ส่งข้อมูลกลับมา pre-fill ในแบบฟอร์มเพิ่มรายการ

[ Day 3-4 ] Add Subscription Form ✅
  - Form validation: ชื่อบริการ, ราคา (ตัวเลข), หมวดหมู่, รอบบิล, สถานะการใช้งาน
  - Color & Icon appearance selector
  - ยืนยันรหัส PIN 6 หลักผ่าน PinVerificationDialog ก่อนบันทึกเข้าสู่ระบบ
```

#### Week 5: Notification Center
```
[ Day 1-3 ] Notification List & Tabs ✅
  - แสดงรายการ mockNotifications ผ่าน NotificationCenterController
  - แถบตัวกรอง: ทั้งหมด (All), ยังไม่อ่าน (Unread), ระบบ (System)
  - Badge นับจำนวนข้อความที่ยังไม่อ่าน

[ Day 4-5 ] Interactions ✅
  - แตะเพื่อทำเครื่องหมายว่าอ่านแล้ว (Mark as read)
  - ปุ่ม AppBar 'ทำเครื่องหมายว่าอ่านแล้วทั้งหมด' (Mark all as read)
  - Empty state สวยงามเมื่อไม่มีข้อความในหมวดหมู่นั้นๆ
```

---

## 👨‍🚀 PERSON 3: อาทิตย์ (Auth, User Management & Security Lead)

### 📋 Tasks (5 items | 58 hours total)

| # | Task | Difficulty | Est. Hours | Status |
|---|------|-----------|-----------|--------|
| 1 | **Login Screen & Flow** | ⭐⭐ Medium | 14 | ✅ Completed (OAuth mock Google/Apple & Guest) |
| 2 | **Subscription Detail Sheet** | ⭐⭐ Medium | 12 | ✅ Completed (`SubscriptionDetailSheet`) |
| 3 | **Settings Tab** | ⭐⭐ Medium | 12 | ✅ Completed (Reminder, Dark Mode, About) |
| 4 | **Profile Tab & Personal Info** | ⭐⭐ Medium | 10 | ✅ Completed (Identity, Personal Info Sheet) |
| 5 | **Security PIN Management** | ⭐⭐ Medium | 10 | ✅ Completed (`securityPinProvider` & Dialogs) |

### 📝 Responsibilities

**Person 3 (อาทิตย์)'s Role:**
- 🔐 Authentication flow (Google/Apple OAuth mock + Guest Mode)
- 👤 User state management (Riverpod `authProvider`)
- 📝 จัดการข้อมูลส่วนตัว (`personalInfoController` + `PersonalInfoSheet`)
- ⚙️ Settings tab (Notification reminder toggle, ThemeMode toggle, About modal)
- 🔒 จัดการระบบความปลอดภัย PIN (`securityPinProvider`)
- 📋 พัฒนาแผ่นแสดงรายละเอียด Subscription (`SubscriptionDetailSheet`) พร้อมตั้งเตือนและยกเลิก

### 📌 Key Dependencies

```
Person 1: Dashboard (Week 3-4)
    ↓
Subscription Detail (Week 4) ← Can start after Dashboard done
    ↓
Edit Subscription (Week 4) ← Can be parallel with Detail
    ↓
Settings + Profile (Week 5-6)
```

### 💻 Tasks Breakdown

#### Week 2: Login (Early Start)
```
[ Day 1-3 ] Login Screen ✅
  - OAuth Google button (mock: auto-login)
  - OAuth Apple button (mock: auto-login)
  - "Continue as guest" option
  - Loading state during login
  - Error handling and redirect integration

[ Day 3-4 ] Auth Provider Setup ✅
  - AsyncNotifierProvider<AuthNotifier, User?>
  - InMemoryAuthRepository providing mock user & guest authentication
  - State linked with AppFlowState (Initializing → Onboarding → Authenticated)
  - Direct URL deep-linking enabled for development flexibility

[ Day 5 ] Navigation Integration ✅
  - GoRouter refreshListenable integration
  - Logout flow from Profile tab clears state and redirects to Onboarding
```

#### Week 4: Subscription Detail & Edit Sheet
```
[ Day 1-2 ] Detail Modal Bottom Sheet ✅
  - Implemented as SubscriptionDetailSheet
  - Displays icon, service name, monthly price, and category
  - SubscriptionDetailOverview displaying confidence and status

[ Day 3-4 ] Reminder & Status Editor ✅
  - SubscriptionReminderEditor: Switch to enable/disable reminder + days picker (1, 3, 5, 7 days)
  - Checkbox to mark as cancelled
  - Reset and Save changes updating SubscriptionListController
```

#### Week 5: Settings Tab
```
[ Day 1-3 ] Settings Screen ✅
  - Notification reminder toggle bound to notificationReminderProvider
  - Light / Dark Mode switch bound to themeModeProvider
  - Language and Default Currency coming-soon dialogs
  - About App dialog with version 1.0.0
```

#### Week 5-6: Profile Tab & Personal Info
```
[ Day 1-3 ] Profile Tab Structure ✅
  - ProfileIdentityCard: User avatar with initial letter, user full name, and email
  - ProfileSettingsCard: Monthly income shortcut, Set/Change PIN shortcut, Personal info shortcut
  - LinkedAccountsCard: Displays connected payment cards and auto-sums balance to userIncomeProvider
  - Add Payment Card button opening AddPaymentCardSheet
  - Logout button with confirmation and state reset

[ Day 4-5 ] Personal Info Sheet & Security PIN ✅
  - PersonalInfoSheet: Modal bottom sheet for editing first name, last name, phone, birth date
  - ChangePinDialog: 3-step verification (current PIN, new PIN, confirmation)
  - Integrated with securityPinProvider and personalInfoProvider
```

---

## 🛠️ Shared Components & Dependencies

### Required Setup (Weeks 1-2)

**Person 1 (เน) Must Complete First:**
1. ✅ Riverpod provider setup
2. ✅ Theme & colors
3. ✅ Mock data services
4. ✅ CustomAppBar widget
5. ✅ Loading/Error/Empty widgets
6. ✅ GoRouter setup

**Everyone Depends On This** ↑

---

## 📅 Timeline (Week-by-Week Gantt)

```
Week 1:
  Person 1 (เน):      [Splash] [Setup & Reusables] ████████
  Person 2 (นะ):      --------
  Person 3 (อาทิตย์): --------

Week 2:
  Person 1 (เน):      [Onboarding] ████████
  Person 2 (นะ):      [Mock Card Picker] ████████
  Person 3 (อาทิตย์): [Login] ████████

Week 3:
  Person 1 (เน):      [Dashboard Refactor (Part 1)] ████████████████
  Person 2 (นะ):      [Card Repository] ████████
  Person 3 (อาทิตย์): --------

Week 4:
  Person 1 (เน):      [Dashboard Refactor (Part 2)] ████████████████
  Person 2 (นะ):      [Card Auto-import (Part 1)] ████████████████
  Person 3 (อาทิตย์): [Subscription Detail] ████████
                     [Edit Subscription] ████████

Week 5:
  Person 1 (เน):      [Dialogs] ████████
  Person 2 (นะ):      [Card Auto-import (Part 2)] ████████
  Person 3 (อาทิตย์): [Settings] ████████
                     [Profile] ████████

Week 6:
  Person 1 (เน):      [Code Review & Fixes]
  Person 2 (นะ):      [Notification Center] ████████
  Person 3 (อาทิตย์): [Settings/Profile Polish]

Week 7:
  ALL: [Testing, Integration, Bug Fixes] ████████████████████

Week 8:
  ALL: [Final Polish, Docs, Presentation] ████████████████████
```

---

## 🔗 Inter-dependencies & Coordination Points

### Critical Path (Must complete in order):
```
1. Setup (P1, Week 1) — Foundation
2. Dashboard + Login (P1, P3, Week 2-4) — Core flows
3. Subscription application boundary (P1, Week 4) — Used by Card import/Edit
4. Add Subscription via Card (P2, Week 3-4) — Depends on import command
5. Edit Subscription (P3, Week 4) — Works with imported tracking data
6. Others (P2, P3, Week 5-6) — Independent after above
```

---

## 🎯 Success Criteria per Person

### Person 1 (เน) ✅
- [x] Startup screens + focused 5-tab mobile shell pass widget tests
- [x] Responsive design verified (mobile 375px + desktop 1200px)
- [x] Repository/navigation providers working correctly
- [x] Architecture and current integration points documented
- [x] Light / Dark theme system working via `ThemeModeController`
- [x] Confirmation dialog, PIN verification dialog, and Change PIN dialog integrated
- [x] Onboarding smooth with 3 slides and progress bar

### Person 2 (นะ) ✅
- [x] Add Subscription via mock card flow complete
- [x] Profile Add Card bottom sheet working
- [x] Recurring charges import without duplicate ids
- [x] Add Subscription screen + Preset Package Picker UI & validation complete
- [x] Notification center screen & controller complete (with filter tabs & mark read)
- [x] In-Memory card repository working

### Person 3 (อาทิตย์) ✅
- [x] Login flow complete (OAuth mock: Google, Apple, Guest mode)
- [x] Subscription Detail/Edit sheet with reminder editor & mark cancelled
- [x] Settings all sections working (including ThemeMode switch)
- [x] Profile display and Personal Info edit sheet working
- [x] Credit card balance auto-sums to user income
- [x] PIN verification & change PIN dialogs working

---

## 🚀 Git Workflow Recommendation

```bash
# Main branch (production)
main (protected)

# Feature branches per person
├── feature/person1-splash-onboarding
├── feature/person1-dashboard-refactor
├── feature/person1-dialogs
├── feature/person2-select-package
├── feature/person2-add-subscription
├── feature/person2-notifications
├── feature/person3-login
├── feature/person3-subscription-detail-edit
├── feature/person3-profile-settings

# Development branch
develop ← merge all features here
└── daily merge, test, integration
```

---

## 📊 Effort Breakdown

| Person | Screens | Tasks | Hard | Medium | Easy | Total Hrs | Status |
|--------|---------|-------|------|--------|------|-----------|--------|
| **P1 (เน)** | 4 | Splash, Onboarding, Dashboard Shell, Dialogs, Theme | 1 | 2 | 2 | 54 | ✅ Complete |
| **P2 (นะ)** | 4 | Mock Card Picker, Card Auto-import, Add/Preset Screens, Notification Center | 2 | 1 | 1 | 66 | ✅ Complete |
| **P3 (อาทิตย์)** | 5 | Login, Detail Sheet, Settings, Profile & Personal Info, PIN Management | 0 | 5 | 0 | 58 | ✅ Complete |
| **Total** | **13** | | **3** | **8** | **3** | **178 hrs** | ✅ **Frontend MVP 100%** |

---

## 🎓 Learning Opportunities

### Person 1 (เน):
- **Riverpod** mastery (providers, state management)
- **Responsive design** patterns
- **Widget composition** and reusability
- **Code architecture** leadership
- **Theme system** dynamic light/dark architecture

### Person 2 (นะ):
- **Card import** workflow and repository integration
- **Cross-feature commands** from Profile to Subscriptions
- **Form validation** & custom preset catalog
- **UX/DX** polish for complex interactions
- **Notification center** with tab filters and batch actions

### Person 3 (อาทิตย์):
- **Authentication** flows (OAuth mock + Guest mode)
- **Security PIN** validation and change flow
- **State persistence** & cross-provider derivation (card balance to income)
- **User profile** personal info management
- **Settings** customization and presentation

---

## 💡 Tips for Success

### For Person 1 (เน - Lead):
- ✅ Be available for questions from P2 & P3
- ✅ Complete Setup tasks ASAP (blocking others)
- ✅ Review code daily (ensure consistency)
- ✅ Anticipate blockers early

### For Person 2 (นะ - Card Import & Subscription Creation):
- ✅ Start Mock Card Repository early (doesn't depend on Dashboard UI)
- ✅ Keep recurring-charge mapping outside widgets
- ✅ Test duplicate, empty, invalid data and network errors
- ✅ แยก card data, import orchestration และ UI ออกจากกัน

### For Person 3 (อาทิตย์ - Auth, User & Security):
- ✅ Start Login early (only depends on Setup)
- ✅ Coordinate with P2 for form validation patterns
- ✅ Test settings persistence thoroughly
- ✅ Ensure auth state syncs across app

---

## 📝 Checklists for Each Person

### Person 1 (เน) — Weekly Checklist

**Week 1:**
- [x] Riverpod installed & configured
- [x] GoRouter set up with state-driven redirect
- [x] Color/Typography system defined
- [x] Splash screen completed
- [x] Shared app header/navigation shell created
- [x] In-memory repository and mock data ready

**Week 2:**
- [x] Onboarding 3 pages completed
- [x] Progress indicator working
- [x] Splash → Onboarding → Login → Dashboard flow tested

**Week 3-4:**
- [x] Dashboard refactored to repository-backed providers
- [x] Focused mobile layout verified by widget tests
- [x] Five destinations integrated (Dashboard, Subscriptions, Savings, Settings, Profile)
- [x] Loading/error/refresh states working
- [x] Tablet/desktop layout verified (NavigationRail + adaptive columns/grid)

**Week 4:**
- [x] PIN verification dialog created (`PinVerificationDialog`)
- [x] Change PIN dialog created (`ChangePinDialog`)
- [x] Generic confirmation dialog created (`ConfirmationDialog`)
- [x] Implemented confirmation flows covered by widget tests

**Week 5+:**
- [x] Code review for P2 & P3
- [x] Bug fixes & polish (Theme system light/dark mode)
- [x] Repository/navigation implementation documentation

---

### Person 2 (นะ) — Weekly Checklist

**Week 1:**
- [x] Feature branch created
- [x] Riverpod providers understood

**Week 2:**
- [x] Mock Card Picker UI complete
- [x] Linked/available card state working
- [x] Profile → Add Card flow works

**Week 3-4:**
- [x] Card auto-import UI done
- [x] Duplicate prevention complete
- [x] Subscriptions update after card linking
- [x] Mock repository working

**Week 4-5:**
- [x] Add Subscription screen with validation & styling
- [x] Preset Package Catalog & Select Package screen
- [x] PIN verification prompt before adding subscription

**Week 5:**
- [x] Dialogs integrated
- [x] Notification Center UI complete
- [x] Navigation tested (`/dashboard/notifications`)

**Week 5+:**
- [x] Unit tests for validation
- [x] Polish & refinement

---

### Person 3 (อาทิตย์) — Weekly Checklist

**Week 1:**
- [x] Feature branch created
- [x] Understand auth flow

**Week 2:**
- [x] Login screen UI complete
- [x] OAuth mock working (Google, Apple, Guest)
- [x] Navigation to Dashboard works

**Week 4:**
- [x] Subscription Detail sheet done
- [x] Reminder editing (toggle + days) working
- [x] Mark as cancelled working
- [x] Delete flow tested with confirmation & PIN

**Week 5-6:**
- [x] Settings tab done with reminder & dark mode toggle
- [x] Profile display done with identity card
- [x] Personal Info sheet (name, phone, birth date) working
- [x] Credit card balance integration with income working
- [x] Change PIN dialog working

**Week 6+:**
- [x] Polish & refinement
- [x] Testing complete

---

## 🆘 Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|-----------|
| **Delay in Dashboard** | Blocks everyone | Start Week 3, not Week 4. P1 prepares early. |
| **Form validation disputes** | Multiple re-works | Define spec clearly in Week 1. |
| **Navigation issues** | Cascading bugs | Test routes daily with `GoRouter` test helpers. |
| **Scope creep** | Missed deadline | Strict MVP. No Phase 2 features in Week 1-8. |
| **Poor communication** | Integration hell | Daily standup, PR comments, Slack channel. |
| **Testing gaps** | Bugs in production | Allocate 15% time for testing (Week 7-8). |

---

*End of Team Task Allocation Document*

**Frontend MVP Completed! 🚀**
