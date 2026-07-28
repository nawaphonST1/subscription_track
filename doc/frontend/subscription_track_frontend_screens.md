# 📱 Subscription Track — Frontend Screens & Architecture Spec

**Project:** Subscription Track  
**Phase:** MVP (Full Frontend Design)  
**Status:** Specification Document  
**Date:** 28 July 2026  

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

### Folder Structure
```
lib/
├── main.dart
├── models/                          # Data models
│   ├── subscription.dart            # (existing)
│   ├── user.dart                    # (new)
│   ├── package.dart                 # (new)
│   ├── notification.dart            # (new)
│   └── usage_log.dart               # (new)
├── providers/                       # Riverpod providers
│   ├── auth_provider.dart           # OAuth + JWT state
│   ├── user_provider.dart           # User profile & settings
│   ├── subscription_provider.dart   # Subscription CRUD + list
│   ├── package_provider.dart        # Package catalog
│   ├── notification_provider.dart   # Notifications
│   ├── filter_provider.dart         # Category filter state
│   └── theme_provider.dart          # Dark/Light theme
├── screens/                         # Full screens
│   ├── splash_screen.dart           # (new)
│   ├── onboarding/
│   │   ├── onboarding_screen.dart
│   │   ├── onboarding_page_1.dart
│   │   ├── onboarding_page_2.dart
│   │   └── onboarding_page_3.dart
│   ├── auth/
│   │   └── login_screen.dart        # (new)
│   ├── dashboard_screen.dart        # (refactor)
│   ├── subscription/
│   │   ├── add_subscription_screen.dart       # (new)
│   │   ├── select_package_screen.dart         # (new)
│   │   ├── subscription_detail_screen.dart    # (new)
│   │   └── edit_subscription_screen.dart      # (new)
│   ├── profile/
│   │   ├── profile_screen.dart                # (new)
│   │   └── settings_screen.dart               # (new)
│   └── notifications/
│       └── notification_center_screen.dart    # (new)
├── widgets/                         # Reusable widgets
│   ├── kpi_card.dart                # (existing)
│   ├── subscription_tile.dart       # (existing - refactor)
│   ├── saving_simulation_card.dart  # (existing)
│   ├── subscription_filter_bar.dart # (existing)
│   ├── pin_verification_dialog.dart # (existing)
│   ├── custom_app_bar.dart          # (new)
│   ├── package_card.dart            # (new)
│   ├── category_chip.dart           # (new)
│   ├── biometric_prompt.dart        # (new)
│   ├── loading_skeleton.dart        # (new)
│   ├── error_state_widget.dart      # (new)
│   └── empty_state_widget.dart      # (new)
├── services/                        # Services (mock for MVP)
│   ├── auth_service.dart            # 🔄 Mock OAuth
│   ├── subscription_service.dart    # 🔄 Mock API
│   ├── package_service.dart         # 🔄 Mock API
│   ├── storage_service.dart         # 🔄 Hive/SharedPref
│   └── notification_service.dart    # 🔄 Mock FCM
└── utils/
    ├── constants.dart
    ├── validators.dart
    └── extensions.dart
```

---

## Screen List & Hierarchy

### Navigation Hierarchy Tree

```
[App Root]
├── 🟢 Splash (500ms logo + loading)
│   └── → Onboarding (if first time)
│       └── → Login
│           └── → Dashboard (home route)
│
├── 📊 Dashboard (home)
│   ├── → Add Subscription
│   │   ├── → Select Package (Preset list)
│   │   │   └── → Add Custom Form (manual entry)
│   │   └── → Cancel
│   │
│   ├── → Tap Subscription Tile
│   │   ├── → Subscription Detail
│   │   │   ├── → Edit (แก้ไข)
│   │   │   │   ├── [PIN/Biometric] → Save
│   │   │   │   └── Cancel
│   │   │   ├── → Delete (ลบ)
│   │   │   │   ├── [PIN/Biometric Dialog]
│   │   │   │   └── [Confirm] → Back to Dashboard
│   │   │   └── Back
│   │   │
│   │   └── Swipe to Delete (Dismissible)
│   │       ├── [PIN/Biometric Dialog]
│   │       └── Undo on SnackBar
│   │
│   ├── → Filter Tap
│   │   └── Real-time filter
│   │
│   └── → Tap Profile Icon (top-right)
│       ├── → Profile Screen
│       │   ├── [Edit Name/Avatar] → Save
│       │   └── View Income
│       │
│       ├── → Settings Screen
│       │   ├── Income Setup
│       │   ├── Notification Days
│       │   ├── Biometric On/Off
│       │   ├── Change PIN
│       │   ├── Language (Thai/Eng)
│       │   └── Logout
│       │
│       └── → Notification Bell
│           └── → Notification Center
│               └── List of past notifications

📝 Notification Center (also accessible from Dashboard)
└── List all notifications with timestamp
```

---

## Detailed Screen Specifications

### 1️⃣ Splash Screen

| Property | Value |
|----------|-------|
| **Purpose** | Initial loading screen with logo & app name |
| **Duration** | 500ms - 2s (show mock loading indicator) |
| **State Management** | Simple `FutureProvider` to check if onboarding seen |
| **Widgets Used** | `Scaffold`, `Center`, `Column`, `CircularProgressIndicator` |
| **Mock Data** | None (static UI) |
| **Navigation** | Auto-navigate to Onboarding OR Dashboard |

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
| **Current State** | 70% done (need architecture refactor) |
| **State Management** | `Riverpod` with `subscriptionProvider`, `filterProvider` |
| **Responsive** | Desktop (900px+) = 60:40 split; Mobile = full column |

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

**Key Changes:**
1. Refactor `setState` → Riverpod providers
2. Extract computation logic to providers
3. Keep UI widgets mostly the same
4. Add error/loading states
5. Use `ConsumerWidget` instead of `StatefulWidget`

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
- **Cancel/Delete** → Show PIN/Biometric Dialog → Confirm → Delete → Back to Dashboard + Undo SnackBar

---

### 7️⃣ Edit Subscription Screen

| Property | Value |
|----------|-------|
| **Purpose** | Modify existing subscription details |
| **Flow** | Dashboard → Detail → Edit → [PIN verify] → Save |
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
2. Optionally trigger PIN/Biometric dialog (if sensitive field changed)
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
├── confirmation_dialog.dart    // Generic confirm dialog
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

### Navigation Structure (Using GoRouter)

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
  static const Color bgPrimary = Color(0xFF0A0F1D);      // Darkest
  static const Color bgSecondary = Color(0xFF131C2E);    // Dark
  static const Color bgTertiary = Color(0xFF1E2A47);     // Lighter dark
  
  // Accents
  static const Color primaryBlue = Color(0xFF3B82F6);    // Primary action
  static const Color emeraldGreen = Color(0xFF10B981);   // Success
  static const Color alertRed = Color(0xFFEF4444);       // Danger
  static const Color warningAmber = Color(0xFFFCD34D);   // Warning
  
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
| 1 | Splash | Setup | 🔴 NEW | High |
| 2 | Onboarding | Setup | 🔴 NEW | High |
| 3 | Login | Auth | 🔴 NEW | High |
| 4 | Dashboard | Core | 🟡 REFACTOR | High |
| 5 | Add Subscription | Core | 🔴 NEW | High |
| 6 | Select Package | Core | 🔴 NEW | High |
| 7 | Subscription Detail | Core | 🔴 NEW | High |
| 8 | Edit Subscription | Core | 🔴 NEW | High |
| 9 | Profile | User | 🔴 NEW | Medium |
| 10 | Settings | User | 🔴 NEW | Medium |
| 11 | Notification Center | Notifications | 🔴 NEW | Medium |
| 12 | Dialogs (PIN, Bio, Confirm) | Modals | 🟡 REFACTOR | High |

### Total New Widgets: **10 Major Widgets**

✅ Keep existing: 5 widgets (KPI, Subscription Tile, Saving Sim, Filter Bar, PIN Dialog)  
🔄 Refactor: 2 widgets (Subscription Tile, PIN Dialog)  
🔴 New: 10+ custom widgets

---

## Development Roadmap (2 Months)

### Week 1: Setup & Foundation
- [ ] Setup Riverpod package + go_router
- [ ] Create models (User, Notification, Package, UsageLog)
- [ ] Create mock data services
- [ ] Setup theme & color system
- [ ] Create reusable widgets (AppBar, Loading, Error, Empty states)

### Week 2: Auth & Onboarding
- [ ] Splash screen
- [ ] Onboarding flow (3 pages)
- [ ] Login screen (OAuth mock)
- [ ] Auth provider (Riverpod)
- [ ] Setup local storage (mock)

### Week 3: Dashboard Refactor
- [ ] Dashboard screen (Riverpod refactor)
- [ ] Subscription list provider
- [ ] Filter provider
- [ ] Category filter functionality

### Week 4: Add/Edit Subscriptions
- [ ] Add Subscription screen
- [ ] Select Package screen (preset list)
- [ ] Custom form validation
- [ ] Edit Subscription screen
- [ ] Delete with PIN verification

### Week 5: User Profile & Settings
- [ ] Profile screen
- [ ] Settings screen (all sections)
- [ ] Notification settings provider
- [ ] Language/Theme switching (mock)

### Week 6: Notifications & Polish
- [ ] Notification Center screen
- [ ] Notification provider
- [ ] Mock notification scheduling
- [ ] UI Polish & animations

### Week 7-8: Testing & Refinement
- [ ] Unit tests for providers
- [ ] Widget tests for complex screens
- [ ] Integration test navigation flow
- [ ] Final bug fixes
- [ ] Documentation

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
