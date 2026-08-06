# 📱 Subscription Track — Frontend Screens & Architecture Spec

**Project:** Subscription Track

**Phase:** MVP (Full Frontend Design)

**Status:** Living Specification (Feature-First Architecture implemented)

**Last Updated:** 6 August 2026

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

รายละเอียดส่วนนี้เป็น source of truth สำหรับ Dashboard MVP และใช้แทนตัวอย่าง proposal เดิมที่อาจยังปรากฏในหัวข้อถัดไป:

- Startup flow เป็น state-driven redirect: Splash → Onboarding → Login → Dashboard โดยไม่มี `Future.delayed` navigation ใน Splash
- `/dashboard` render `MainNavigationShell` และใช้ `IndexedStack` เก็บ state ของ 5 destinations ที่รวมจากงานทีม
- source code จัดแบบ feature-first; ดูกฎฉบับปัจจุบันที่ [`doc/architecture/feature_first_architecture.md`](../architecture/feature_first_architecture.md)
- tabs อยู่ใน `lib/features/<feature>/presentation/`; app shell อยู่ใน `lib/app/presentation/`
- navigation, filter, income และ reminder มี controller แยกตาม owner จริง ไม่มี provider รวมหลาย feature
- subscription data ใช้ `SubscriptionRepository` → `InMemorySubscriptionRepository` ผ่าน `subscriptionRepositoryProvider`
- `subscriptionListProvider` เป็น `AsyncNotifierProvider<SubscriptionListController, List<Subscription>>` ไม่ใช่ `FutureProvider` หรือ legacy `StateNotifierProvider`
- CRUD/toggle เรียกผ่าน controller; delete/toggle อัปเดต UI แบบ optimistic และจัดการ rollback/error
- tests override repository ด้วย `subscriptionRepositoryProvider.overrideWithValue(...)`

> หมายเหตุ: Hive/REST, Add Subscription form, PIN persistence, biometric และ notification backend ยังไม่เสร็จ UI ที่แสดงใน shell เป็น integration point สำหรับงานถัดไป

### Recommended State Management: **Riverpod**

**Why Riverpod over BLoC?**
| Aspect | Riverpod | BLoC |
|--------|----------|------|
| Learning Curve | ✅ Simpler (provider pattern) | ❌ Steeper (event/state) |
| Boilerplate | ✅ ต่ำมาก | ❌ สูง |
| Testing | ✅ ง่าย (mockable) | ✅ ง่าย |
| Async Handling | ✅ Built-in (FutureProvider) | ❌ ต้อง .fromStream() |
| File Size | ✅ โครงการจะเล็ก | ❌ โครงการจะใหญ่ |
| Team Ramp-up | ✅ 3 คน เรียนได้เร็ว | ❌ ช้า |

### Folder Structure (Current)

```text
lib/
├── app/                             # routing, startup, navigation shell
├── core/                            # shared concerns/widgets ที่มีผู้ใช้จริง
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── notifications/
│   ├── onboarding/
│   ├── profile/
│   ├── savings/
│   ├── settings/
│   └── subscriptions/
└── main.dart
```

แต่ละ feature แยก `domain/`, `data/`, `application/`, `presentation/` เท่าที่จำเป็น
และใช้ `application/` แทน `bloc/` เนื่องจากโปรเจกต์ใช้ Riverpod เท่านั้น

---

## Screen List & Hierarchy

### Navigation Hierarchy Tree

```text
[App Root]
└── Splash (อยู่จน app flow initialization เสร็จ)
    ├── Onboarding (first time)
    │   └── Login
    ├── Login (returning unauthenticated user)
    └── /dashboard (authenticated user)
        └── MainNavigationShell / IndexedStack
            ├── Tab 0: Dashboard
            │   ├── Hero payout + Creep Risk
            │   ├── Upcoming renewals
            │   └── Unused service alert
            ├── Tab 1: Subscriptions
            │   ├── Search + category filter
            │   ├── Subscription list / selection / delete
            │   └── Add FAB → Add route/form (pending)
            ├── Tab 2: Savings
            │   ├── Saving goal banner
            │   ├── Selection checklist
            │   └── Cancel selected
            └── Tab 3: Profile & Settings
                ├── Monthly income bottom sheet
                ├── PIN settings entry point (backend pending)
                └── Notification reminder toggle
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
| **Purpose** | OAuth Google/Apple Sign-In |
| **State** | `StateNotifierProvider<AuthNotifier>` |
| **Mock Status** | 🔄 Mock until backend ready |
| **Navigation** | Success → Dashboard; Skip → (same user ID) |

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
│  │ Sign in with 🔵 G │  │ (Google button)
│  └───────────────────┘  │
│                         │
│  ┌───────────────────┐  │
│  │ Sign in with 🍎 A │  │ (Apple button)
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

**State Management:**
```dart
// In providers/auth_provider.dart
final authStateProvider = StateNotifierProvider((ref) {
  return AuthNotifier();
});

// 🔄 Mock login
Future<bool> loginWithGoogle() async {
  // Simulate network delay
  await Future.delayed(Duration(seconds: 2));
  // Return mock user
  return true;
}
```

**Mock Data:**
```dart
class MockUser {
  final String id = '🔄 mock-user-123';
  final String email = '🔄 user@example.com';
  final String name = '🔄 John Doe';
  final String avatar = '🔄 https://i.pravatar.cc/150?img=1';
  final double income = 35000; // THB
}
```

---

### 4️⃣ Dashboard Screen (REFACTOR)

| Property | Value |
|----------|-------|
| **Purpose** | Main hub - view KPIs, subscriptions, simulate savings |
| **Current State** | ✅ Adaptive navigation shell with 5 integrated destinations |
| **State Management** | Riverpod `AsyncNotifier` + Repository Pattern + derived providers |
| **Responsive** | ✅ Bottom navigation on mobile; NavigationRail + adaptive columns/grid at 900px+ |

**Implemented navigation structure:**

| Tab | Content | State binding |
|-----|---------|---------------|
| 0 — Dashboard | Hero payout KPI, Creep Risk, renewal timeline, unused alert | `subscriptionListProvider`, `userIncomeProvider` |
| 1 — Subscriptions | Search, category chips, list tiles, Add FAB | `visibleSubscriptionsProvider` |
| 2 — Savings | yearly saving goal, checklist, cancel selected | `subscriptionListProvider.notifier` |
| 3 — Settings | reminder toggle, language/currency integration points | `notificationReminderProvider` |
| 4 — Profile | avatar, income sheet, PIN entry point, linked accounts | `userIncomeProvider` |

> เดิม Option 5 กำหนด 4 tabs โดยรวม Profile/Settings ไว้ด้วยกัน แต่หลัง team integration มี `SettingTab` แยกต่างหาก จึงคง 5 destinations ไว้ก่อนเพื่อไม่ทับงานของ Person 3; สามารถรวมกลับภายหลังเมื่อทีมยืนยัน information architecture รอบสุดท้าย

**Historical proposal below (superseded):** ตัวอย่าง `FutureProvider`, path แบบ
`providers/`/`screens/` และ layout หน้าเดียวด้านล่างเก็บไว้เป็น design history เท่านั้น
ไม่ใช่ API หรือโครงสร้างปัจจุบัน

**New Architecture Approach:**

```dart
// Instead of setState in one file, split into:

// 1. Providers (in providers/subscription_provider.dart)
final subscriptionListProvider = FutureProvider<List<Subscription>>((ref) async {
  // 🔄 Mock: return hardcoded + slight delay
  await Future.delayed(Duration(ms: 500));
  return mockSubscriptions;
});

final selectedSubscriptionsProvider = StateNotifierProvider<SelectedSubs>((ref) {
  return SelectedSubs([]);
});

final filteredSubscriptionsProvider = Provider<List<Subscription>>((ref) {
  final all = ref.watch(subscriptionListProvider).value ?? [];
  final selected = ref.watch(selectedSubscriptionsProvider);
  return all.where((s) => selected.contains(s.id)).toList();
});

// 2. Widget just consumes (in screens/dashboard_screen.dart)
class DashboardScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptions = ref.watch(subscriptionListProvider);
    
    return subscriptions.when(
      data: (subs) => _buildContent(subs),
      loading: () => LoadingSkeleton(),
      error: (err, stack) => ErrorStateWidget(error: err),
    );
  }
}
```

**UI Stays Same:**
```
Mobile Layout:
┌──────────────────────────┐
│ [← Back] Dashboard [🔔☺️] │ ← CustomAppBar
├──────────────────────────┤
│ ╔══════════════════════╗ │
│ ║ Monthly: ฿4,250      ║ │ ← KPI Cards
│ ║ Yearly: ฿51,000      ║ │   (refactor to use data from provider)
│ ║ Creep: 12.14%        ║ │
│ ╚══════════════════════╝ │
├──────────────────────────┤
│ [All] [🎬 Stream] [🤖 AI]│ ← SubscriptionFilterBar
│ [☁️ Cloud] [🎨 Creative] │   (keep as is)
├──────────────────────────┤
│ Subscriptions:           │
│ ┌────────────────────┐   │
│ │ Netflix     ฿599   │ ← SubscriptionTile
│ │ 🟢 Frequent │      │   (add edit/delete via swipe)
│ │ Confidence: 92%    │   (add to swipe actions)
│ └────────────────────┘   │
│ ┌────────────────────┐   │
│ │ Spotify     ฿178   │   │
│ │ 🟠 Moderate │      │   │
│ │ Confidence: 65%    │   │
│ └────────────────────┘   │
│ [... more tiles ...]     │
├──────────────────────────┤
│ ╔══════════════════════╗ │
│ ║ Savings Simulation   ║ │ ← SavingSimulationCard
│ ║ If cancel selected:  ║ │   (keep as is, refactor logic
│ ║ Save ฿177/month      ║ │    to use notifier)
│ ╚══════════════════════╝ │
│ [Cancel All Selected] btn│
└──────────────────────────┘

Desktop Layout (900px+):
┌────────────────────────────────────────────────────┐
│ [← Back] Dashboard                  [🔔☺️ Profile] │
├──────────────────────────────────────────────────────┤
│                    │                                  │
│  KPI Cards         │  [All] [🎬] [🤖] [☁️] [🎨]      │
│  (3 col grid)      │                                  │
│                    │  Subscriptions List              │
│                    │  ┌──────────────────────────┐   │
│  Monthly           │  │ Netflix    ฿599          │   │
│  Yearly            │  │ 🟢 Frequent Confidence:92% │   │
│  Creep %           │  └──────────────────────────┘   │
│                    │                                  │
│  ─────────────     │  ┌──────────────────────────┐   │
│                    │  │ Spotify    ฿178          │   │
│  Savings Sim       │  │ 🟠 Moderate Confidence:65%│   │
│  Card              │  └──────────────────────────┘   │
│                    │                                  │
│                    │  [... more tiles ...]            │
│                    │                                  │
│                    │  ╔──────────────────────────┐   │
│                    │  ║ Savings Simulation       ║   │
│                    │  ║ Save ฿177/month          ║   │
│                    │  ╚──────────────────────────┘   │
└────────────────────────────────────────────────────┘
```

**Implemented changes:**
1. ย้าย hardcoded subscription list ออกจาก `DashboardScreen` ไปไว้หลัง repository interface
2. ใช้ `AsyncNotifier` เป็น single source of truth สำหรับ CRUD/selection
3. แยก search/category เป็น derived provider และใช้ typed `SubscriptionCategoryFilter`
4. แยก 5 tab views ออกจาก navigation shell ตามผล team integration
5. รองรับ loading/error/refresh และทดสอบ state binding ด้วย Provider override
6. ใช้ breakpoint กลางจาก `AppBreakpoints`: mobile เป็น `NavigationBar`, desktop เป็น `NavigationRail`; Dashboard/Savings ใช้สองคอลัมน์และ Subscriptions ใช้ adaptive grid

---

### 5️⃣ Add Subscription Screen

| Property | Value |
|----------|-------|
| **Purpose** | Choose from preset package OR add custom |
| **Navigation Flow** | Dashboard → Add Subscription → (Select Package OR Custom Form) |
| **State** | Track form data, validation errors |
| **Mock Data** | 🔄 Mock package list, custom validation |

**UI Layout - Step 1: Choose Method**

```
┌─────────────────────────┐
│ ← Add Subscription  [X] │
├─────────────────────────┤
│                         │
│  Choose How to Add      │
│                         │
│  ┌─────────────────────┐│
│  │ 📱 Pick from List   ││ ← Tap → Select Package Screen
│  │                     ││   (see next section)
│  │ Browse Netflix,     ││
│  │ Spotify, Disney+... ││
│  └─────────────────────┘│
│                         │
│  ┌─────────────────────┐│
│  │ ✏️ Add Manually     ││ ← Tap → Custom Form
│  │                     ││   (see below)
│  │ Enter subscription  ││
│  │ name & price        ││
│  └─────────────────────┘│
│                         │
└─────────────────────────┘
```

**UI Layout - Step 2a: Select Package (Preset)**

```
┌─────────────────────────┐
│ ← Select Package    [X] │
├─────────────────────────┤
│ 🔍 Search packages...   │
├─────────────────────────┤
│                         │
│ 🎬 Streaming (5)        │
│ ┌───────────────────┐   │
│ │ 🎬 Netflix    ฿599│   │ ← PackageCard
│ │                   │   │   (with icon, name, price)
│ │ 📺 Monthly  [Select]│ ← Tap → Custom Amount Form
│ └───────────────────┘   │
│                         │
│ ┌───────────────────┐   │
│ │ 🎮 Disney+   ฿249 │   │
│ │                   │   │
│ │ 📺 Monthly  [Select]  │
│ └───────────────────┘   │
│                         │
│ 🤖 AI (3)               │
│ ┌───────────────────┐   │
│ │ 🤖 ChatGPT+ ฿20  │   │
│ │                   │   │
│ │ 💳 Monthly  [Select]  │
│ └───────────────────┘   │
│                         │
│ [... more categories]   │
│                         │
└─────────────────────────┘
```

**UI Layout - Step 2b: Custom Form**

```
┌──────────────────────────────┐
│ ← Add Subscription       [X] │
├──────────────────────────────┤
│                              │
│ Service Name                 │
│ ┌──────────────────────────┐ │
│ │ YouTube Premium [cursor] │ │
│ └──────────────────────────┘ │
│                              │
│ Price                        │
│ ┌──────────────────────────┐ │
│ │ 99.00              [🇹🇭] │ │
│ └──────────────────────────┘ │
│                              │
│ Billing Period               │
│ ⦿ Monthly  ○ Quarterly       │
│ ○ Yearly   ○ Custom          │
│                              │
│ Category                     │
│ [▼ Streaming            ]    │
│                              │
│ Next Billing Date            │
│ [📅 31 Dec 2024    ][Calc]  │
│                              │
│ Reminder Before (days)       │
│ [+ 3 -]                     │
│                              │
│ Additional Notes (optional)  │
│ ┌──────────────────────────┐ │
│ │ Shared with friend       │ │
│ └──────────────────────────┘ │
│                              │
│ ┌──────────────────────────┐ │
│ │ [Cancel]    [Add Service]│ │
│ └──────────────────────────┘ │
└──────────────────────────────┘
```

**Widgets Used:**
- `TextFormField` (with validation)
- `RadioListTile` (billing period)
- `DropdownButton` (category)
- `DatePickerField` (custom)
- `CustomPackageCard` (for preset selection)
- `ListView` (scrollable form)

**State Management:**
```dart
// providers/add_subscription_provider.dart
final addSubscriptionFormProvider = StateNotifierProvider((ref) {
  return AddSubscriptionNotifier();
});

// Track form state: loading, success, error
class AddSubscriptionState {
  final bool isLoading;
  final String? error;
  final Subscription? savedSubscription;
}
```

**Mock Data:**
```dart
🔄 List<Package> mockPackages = [
  Package(
    id: 'netflix',
    name: 'Netflix',
    category: 'streaming',
    defaultPrice: 599,
    iconUrl: 'assets/icons/netflix.png',
    websiteUrl: 'netflix.com',
  ),
  // ... more
];
```

---

### 6️⃣ Subscription Detail Screen

| Property | Value |
|----------|-------|
| **Purpose** | View full details, edit, or delete |
| **Triggered By** | Tap subscription tile on Dashboard |
| **Parameters** | Subscription ID (passed via route) |
| **State** | Load subscription data + UI state |

**UI Layout:**

```
┌──────────────────────────────┐
│ ← Back              [⋯ Menu] │
├──────────────────────────────┤
│                              │
│         [🎬 Icon]            │
│                              │
│  Netflix                     │
│  ฿599 / month                │
│                              │
│  ┌────────────────────────┐  │
│  │ Status: 🟢 Frequent    │  │
│  │ Confidence: 92%        │  │
│  │ Last renewed: Dec 1    │  │
│  │ Next renewal: Jan 1    │  │
│  └────────────────────────┘  │
│                              │
│  ─────────────────────────   │
│  Description                 │
│  Video streaming service     │
│  with 4K content            │
│  ─────────────────────────   │
│                              │
│  Usage Stats (Phase 2)       │
│  [Graph placeholder]         │
│  Last 7 days: 12 hrs        │
│  ─────────────────────────   │
│                              │
│  Category: 🎬 Streaming      │
│  Billing: Monthly            │
│  Reminder: 3 days before     │
│  ─────────────────────────   │
│                              │
│  Notes: "Shared with family" │
│                              │
│  ┌──────────────────────────┐│
│  │ [Edit Subscription]      ││
│  └──────────────────────────┘│
│                              │
│  ┌──────────────────────────┐│
│  │ [Cancel Subscription]    ││ ← Danger button
│  └──────────────────────────┘│
│                              │
└──────────────────────────────┘
```

**Buttons:**
- **Edit** → Edit Subscription Screen
- **Cancel/Delete tracking item** → Generic Confirmation → Delete → Show result SnackBar
- PIN/Biometric สงวนไว้สำหรับ sensitive action จริง เช่น เปลี่ยน PIN, เปิด biometric lock หรือเชื่อม API เพื่อยกเลิกบริการภายนอก

---

### 7️⃣ Edit Subscription Screen

| Property | Value |
|----------|-------|
| **Purpose** | Modify existing subscription details |
| **Flow** | Dashboard → Detail → Edit → Save |
| **Differences from Add** | Pre-filled form + Delete option |

**UI Layout:** (Same as Add Custom Form, but with pre-filled values)

```
┌──────────────────────────────┐
│ ← Edit Subscription      [X] │
├──────────────────────────────┤
│                              │
│ Service Name                 │
│ ┌──────────────────────────┐ │
│ │ Netflix          [cursor]│ │ ← Pre-filled
│ └──────────────────────────┘ │
│                              │
│ Price                        │
│ ┌──────────────────────────┐ │
│ │ 599.00             [🇹🇭]  │ │
│ └──────────────────────────┘ │
│                              │
│ [... other fields ...]       │
│                              │
│ ┌──────────────────────────┐ │
│ │ [Cancel]   [Save Changes]│ │
│ └──────────────────────────┘ │
│                              │
│ [Delete This Subscription]   │ ← Danger zone
│                              │
└──────────────────────────────┘
```

**On Save:**
1. Show loading spinner
2. ไม่เรียก PIN/Biometric สำหรับการแก้ข้อมูล tracking ทั่วไป
3. 🔄 Mock update to local storage
4. Show success SnackBar
5. Navigate back to Dashboard or Detail

---

### 8️⃣ Profile Screen

| Property | Value |
|----------|-------|
| **Purpose** | View & edit user profile |
| **Content** | Avatar, name, email, income summary |
| **Navigation** | Tap profile icon on Dashboard |

**UI Layout:**

```
┌──────────────────────────────┐
│ ← Back              Profile   │
├──────────────────────────────┤
│                              │
│         [Avatar]             │
│        (tap to change)        │
│                              │
│  John Doe                    │
│  john.doe@gmail.com          │
│                              │
│  ─────────────────────────   │
│  Monthly Income: ฿35,000     │
│  (tap to edit)               │
│  ─────────────────────────   │
│                              │
│  Quick Stats                 │
│  ┌─────────────┬────────────┐│
│  │ Total Cost  │ ฿4,250/mo  ││
│  ├─────────────┼────────────┤│
│  │ Creep Score │ 12.14%     ││
│  ├─────────────┼────────────┤│
│  │ Services    │ 5 active   ││
│  └─────────────┴────────────┘│
│                              │
│  ─────────────────────────   │
│  [Edit Profile]              │
│  [Settings]                  │
│  [Help & Feedback]           │
│  ─────────────────────────   │
│                              │
└──────────────────────────────┘
```

**Widgets:**
- `CircleAvatar` (with image picker on tap)
- `ListTile` (for each stat)
- Custom edit modal for income

---

### 9️⃣ Settings Screen

| Property | Value |
|----------|-------|
| **Purpose** | Configure app behavior, security, localization |
| **Sections** | Financial, Security, Notifications, General |
| **Navigation** | Profile → Settings |

**UI Layout:**

```
┌──────────────────────────────┐
│ ← Back              Settings  │
├──────────────────────────────┤
│                              │
│ 📊 Financial                 │
│ ├─ Monthly Income: ฿35,000   │
│ │  (tap to change)           │
│ └─ Currency: THB             │
│                              │
│ 🔐 Security                  │
│ ├─ Biometric Lock: ⦿ ON      │
│ │  (Face ID / Fingerprint)   │
│ ├─ Change PIN: [Set PIN]     │
│ │  (currently: ••••••)       │
│ └─ Login Method: OAuth        │
│                              │
│ 🔔 Notifications             │
│ ├─ Remind Before: [+ 3 -]    │
│ │  (days before billing)     │
│ ├─ Sound: ⦿ ON               │
│ └─ Vibrate: ⦿ ON             │
│                              │
│ 🌐 General                   │
│ ├─ Language: [Thai ▼]        │
│ ├─ Theme: Dark (auto)        │
│ └─ Version: 1.0.0            │
│                              │
│ ─────────────────────────    │
│ [About Us]                   │
│ [Privacy Policy]             │
│ [Terms of Service]           │
│ ─────────────────────────    │
│                              │
│ ┌──────────────────────────┐ │
│ │ [Log Out]                │ │ ← Danger button
│ └──────────────────────────┘ │
│                              │
└──────────────────────────────┘
```

**Widgets:**
- `SwitchListTile` (toggles)
- `ListTile` (navigation items)
- `TextFormField` (inline edit)
- `DropdownButton` (select options)
- Custom Pin Setup Dialog

**State Management:**
```dart
final settingsProvider = StateNotifierProvider((ref) {
  return SettingsNotifier();
});

// Auto-save to SharedPreferences on change
```

---

### 🔟 Notification Center Screen

| Property | Value |
|----------|-------|
| **Purpose** | View all notifications (reminders, alerts) |
| **Triggered By** | Bell icon on Dashboard OR from app drawer |
| **Mock Data** | 🔄 Mock notification list |

**UI Layout:**

```
┌──────────────────────────────┐
│ ← Back         Notifications │
├──────────────────────────────┤
│ [All] [Unread] [Archived]    │ ← Filter tabs
├──────────────────────────────┤
│                              │
│ ⭕ Upcoming Renewal          │ ← Unread (gray dot)
│ Netflix renews in 3 days     │
│ Mon, 28 Jan 2024 - 2:30 PM   │
│ [Dismiss]                    │
│                              │
│ ✓ Subscription Cancelled     │ ← Read
│ You cancelled Spotify        │
│ Fri, 25 Jan 2024 - 10:15 AM  │
│ [Dismiss]                    │
│                              │
│ ⭕ Service Alert             │ ← Unread
│ ChatGPT+ price increased     │
│ Thu, 24 Jan 2024 - 6:45 PM   │
│ [Dismiss]                    │
│                              │
│ [... swipe to dismiss ...]   │
│                              │
│ (No more notifications)      │ ← Empty state
│                              │
└──────────────────────────────┘
```

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

### 3. Mock Packages (Preset List)

```dart
// services/mock_data/mock_packages.dart
final mockPackages = [
  Package(
    id: 'netflix',
    name: 'Netflix',
    category: 'streaming',
    defaultPrice: 599,
    billingPeriod: 'monthly',
    iconUrl: 'assets/icons/netflix.png',
    websiteUrl: 'netflix.com',
    isActive: true,
  ),
  Package(
    id: 'spotify',
    name: 'Spotify',
    category: 'streaming',
    defaultPrice: 178,
    billingPeriod: 'monthly',
    iconUrl: 'assets/icons/spotify.png',
    websiteUrl: 'spotify.com',
    isActive: true,
  ),
  // ... 15+ more packages
];
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

### Current Navigation Structure (Using GoRouter + Riverpod Redirect)

```dart
GoRouter(
  initialLocation: '/splash',
  refreshListenable: routerRefreshNotifier,
  redirect: (context, state) {
    // ตรวจ initializing → onboarding → authentication ตามลำดับ
    // และเช็ค state.matchedLocation ก่อนคืน route เพื่อกัน redirect loop
  },
  routes: [
    GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(
      path: '/dashboard',
      builder: (_, _) => const MainNavigationShell(),
    ),
  ],
);
```

Bottom navigation เป็น in-page state ผ่าน `currentTabProvider`; การเปลี่ยน tab ไม่สร้าง route ใหม่และ `IndexedStack` รักษา state ของแต่ละ tab

### Planned Nested Routes (Not Implemented Yet)

โครงสร้างด้านล่างเป็นแผนสำหรับ Add/Detail/Edit/Notification หลังหน้าจอของผู้รับผิดชอบพร้อม ห้ามเรียก route เหล่านี้จนกว่าจะ register ใน `app_router.dart`

```dart
// router/app_router.dart
final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => DashboardScreen(),
      routes: [
        GoRoute(
          path: 'add-subscription',
          builder: (context, state) => AddSubscriptionScreen(),
          routes: [
            GoRoute(
              path: 'select-package',
              builder: (context, state) => SelectPackageScreen(),
            ),
          ],
        ),
        GoRoute(
          path: 'subscription/:id',
          builder: (context, state) => SubscriptionDetailScreen(
            id: state.params['id']!,
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => EditSubscriptionScreen(
                id: state.params['id']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: 'profile',
          builder: (context, state) => ProfileScreen(),
        ),
        GoRoute(
          path: 'settings',
          builder: (context, state) => SettingsScreen(),
        ),
        GoRoute(
          path: 'notifications',
          builder: (context, state) => NotificationCenterScreen(),
        ),
      ],
    ),
  ],
);
```

### Programmatic Navigation Examples

```dart
// Navigate to add subscription
context.go('/dashboard/add-subscription');

// Navigate to specific subscription detail
context.go('/dashboard/subscription/1');

// Navigate with state
context.push('/dashboard/subscription/1/edit');

// Go back
context.pop();

// Clear and go to dashboard (after logout)
context.go('/login');
```

---

## Design System & Theme

### Color Palette (Dark Fintech Theme)

```dart
// utils/app_colors.dart
class AppColors {
  // Base
  static const Color bgPrimary = Color(0xFF0B0F19);      // Darkest
  static const Color bgSecondary = Color(0xFF151D31);    // Cards
  static const Color bgTertiary = Color(0xFF1E2A47);     // Lighter dark
  
  // Accents
  static const Color primaryBlue = Color(0xFF3B82F6);    // Primary action
  static const Color emeraldGreen = Color(0xFF10B981);   // Success
  static const Color alertRed = Color(0xFFEF4444);       // Danger
  static const Color warningAmber = Color(0xFFF59E0B);   // Warning
  
  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);    // White
  static const Color textSecondary = Color(0xFF9CA3AF);  // Gray
  static const Color textTertiary = Color(0xFF6B7280);   // Darker gray
  
  // Semantic
  static const Color successGreen = emeraldGreen;
  static const Color errorRed = alertRed;
  static const Color warningYellow = warningAmber;
  static const Color infoBlue = primaryBlue;
}
```

### Typography

```dart
// utils/app_typography.dart
class AppTypography {
  static const TextStyle displayLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  
  // ... more styles
}
```

### Theme Data

```dart
// utils/app_theme.dart
ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.bgPrimary,
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.bgSecondary,
    elevation: 0,
    centerTitle: true,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: AppColors.textPrimary,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  // ... more theme customization
);
```

---

## Summary: MVP Frontend Screens

### Total Screens: **12 Major Screens**

| # | Screen Name | Type | Status | Priority |
|---|-------------|------|--------|----------|
| 1 | Splash | Setup | ✅ IMPLEMENTED | High |
| 2 | Onboarding | Setup | ✅ IMPLEMENTED | High |
| 3 | Login | Auth | ✅ MOCK IMPLEMENTED | High |
| 4 | Dashboard / adaptive shell | Core | ✅ IMPLEMENTED | High |
| 5 | Add Subscription | Core | ✅ IMPLEMENTED | High |
| 6 | Select Package | Core | ✅ IMPLEMENTED | High |
| 7 | Subscription Detail | Core | ✅ DETAIL SHEET IMPLEMENTED | High |
| 8 | Edit Subscription | Core | 🔴 NEW | High |
| 9 | Profile | User | ✅ TAB IMPLEMENTED | Medium |
| 10 | Settings | User | 🟡 REMINDER SCAFFOLD; SECURITY DEFERRED | Medium |
| 11 | Notification Center | Notifications | ✅ IMPLEMENTED | Medium |
| 12 | Dialogs (PIN, Bio, Confirm) | Modals | 🟡 CONFIRM DONE; SECURITY DEFERRED | High |

### Total New Widgets: **10 Major Widgets**

✅ Keep existing: 5 widgets (KPI, Subscription Tile, Saving Sim, Filter Bar, PIN Dialog)  
🔄 Refactor: 2 widgets (Subscription Tile, PIN Dialog)  
🔴 New: 10+ custom widgets

---

## Development Roadmap (2 Months)

### Week 1: Setup & Foundation
- [x] Setup Riverpod package + go_router
- [x] Create models (User, Notification, Package)
- [x] Create in-memory repository and mock data source
- [x] Setup theme & color system
- [x] Keep only shared widgets with at least two real consumers; remove unused scaffolds

### Week 2: Auth & Onboarding
- [x] Splash screen
- [x] Onboarding flow (3 pages)
- [x] Login screen (OAuth mock)
- [x] Auth/app-flow providers (Riverpod)
- [ ] Persist onboarding/auth state to local storage

### Week 3: Dashboard Refactor
- [x] Dashboard 4-tab mobile shell (Riverpod refactor)
- [x] Repository-backed subscription list provider
- [x] Search and typed category derived provider
- [x] Category filter functionality
- [x] Savings selection and dynamic Creep Score
- [x] Tablet/desktop layout optimization (NavigationRail, constrained content, adaptive columns/grid)

### Week 4: Add/Edit Subscriptions
- [x] Add Subscription screen
- [x] Select Package screen (preset list)
- [x] Custom form validation
- [ ] Edit Subscription screen
- [x] Delete with generic confirmation (tracking action; no PIN/Biometric)

### Week 5: User Profile & Settings
- [x] Profile tab
- [x] Settings tab (MVP reminder preference; security deferred)
- [x] Notification reminder provider owned by Settings
- [ ] Language/Theme switching (mock)

### Week 6: Notifications & Polish
- [x] Notification Center screen
- [x] Notification Center controller
- [ ] Mock notification scheduling
- [ ] UI Polish & animations

### Week 7-8: Testing & Refinement
- [x] Unit tests for application/controllers
- [x] Widget tests for routing, navigation shell and shared confirmation
- [ ] Integration test navigation flow
- [ ] Final bug fixes
- [x] Feature-first architecture and state ownership documentation

---

## Next Steps

1. **Review this spec** with the team
2. **Prioritize widget order** based on dependencies
3. **Start with Week 1** (Setup & Foundation)
4. **Create mock data services** before building screens
5. **Establish code review process** for consistency
6. **Setup CI/CD for Flutter** (GitHub Actions)

---

*End of Frontend Screens Specification Document*  
*Ready for implementation*
