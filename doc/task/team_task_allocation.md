# 👥 Team Task Allocation — Subscription Track Frontend

**Project:** Subscription Track MVP  
**Team Size:** 3 developers  
**Total Tasks:** 12 major screens + 10+ widgets  
**Duration:** 8 weeks  
**Date:** 28 July 2026

**Implementation status updated:** 3 August 2026 (Person 1 commits through `f81d3f5`)

---

## 📊 Task Difficulty Analysis

### Difficulty Levels

| Level | Examples | Complexity | Est. Hours |
|-------|----------|-----------|-----------|
| ⭐ **Easy** | Splash, Profile, Notifications | UI only, no complex logic | 6-8 hrs |
| ⭐⭐ **Medium** | Login, Forms, Settings, Dialogs | Logic + validation + navigation | 12-16 hrs |
| ⭐⭐⭐ **Hard** | Dashboard, Add Subscription | Complex logic + refactor + responsive | 20-28 hrs |

### Screen Complexity Breakdown

| Screen | Difficulty | Why | Hours |
|--------|-----------|-----|-------|
| **Splash** | ⭐ | Static UI, simple navigation | 4 |
| **Onboarding** | ⭐⭐ | PageView, dots indicator, navigation flow | 12 |
| **Login** | ⭐⭐ | OAuth mock, auth provider setup, navigation | 14 |
| **Dashboard** | ⭐⭐⭐ | Refactor existing, Riverpod providers, responsive layout, multiple widgets | 24 |
| **Add Subscription** | ⭐⭐⭐ | Dual form paths, validation, two-screen flow, business logic | 26 |
| **Select Package** | ⭐⭐ | List, search/filter, selection logic, categories | 12 |
| **Subscription Detail** | ⭐⭐ | Fetch by ID, dynamic content, edit button, delete button | 12 |
| **Edit Subscription** | ⭐⭐ | Form pre-fill, update logic, shared validation with Add | 12 |
| **Profile** | ⭐ | Read-only display, simple edit modal for income | 6 |
| **Settings** | ⭐⭐ | Multiple sections, toggles, form inputs, state persistence | 14 |
| **Notification Center** | ⭐ | ListView, tabs, mock data display, dismiss logic | 6 |
| **Dialogs (PIN, Bio, Confirm)** | ⭐⭐ | Refactor existing PIN dialog, add Biometric, reusable confirm | 12 |

---

## 👨‍💻 Team Allocation (3 People)

### 👤 Team Members Mapping
- **Person 1**: เน (Lead Frontend Developer)
- **Person 2**: นะ (Forms & CRUD Lead)
- **Person 3**: อาทิตย์ (Auth & User Management Lead)

### ✅ Distribution Strategy

Each person gets:
- **1 Hard task** (Heavy lifting) OR **2 Medium tasks** (Lead contribution)
- **1-2 Medium tasks** (Core work)
- **1 Easy task** (Polish/Quick win)

---

## 🎯 PERSON 1: เน (Lead Frontend Developer)

### 📋 Tasks (4 items | 50 hours total)

| # | Task | Difficulty | Est. Hours | Status |
|---|------|-----------|-----------|--------|
| 1 | **Dashboard** | ⭐⭐⭐ Hard | 24 | ✅ Mobile 4-tab shell implemented |
| 2 | **Dialogs** (PIN, Bio, Confirm) | ⭐⭐ Medium | 12 | 🟡 After Dashboard |
| 3 | **Onboarding** | ⭐⭐ Medium | 12 | ✅ Completed |
| 4 | **Splash** | ⭐ Easy | 4 | ✅ Completed |

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
[ Day 1-2 ] Refactor PIN Dialog
  - 6-digit PIN entry
  - Correct/incorrect feedback
  - Mock verify: '123456' = success

[ Day 2-3 ] Biometric Dialog
  - Face ID / Fingerprint UI
  - Fallback to PIN
  - Success/failure states

[ Day 4 ] Confirm Dialog (Generic)
  - Reusable for delete confirmation ✅
  - Dynamic title, message, icon and action buttons ✅
  - Primary/danger style + Future<bool> result ✅
  - Integrated with Subscriptions and Savings flows ✅
```

---

## 👨‍💼 PERSON 2: นะ (Forms & CRUD Lead)

### 📋 Tasks (4 items | 50 hours total)

| # | Task | Difficulty | Est. Hours | Status |
|---|------|-----------|-----------|--------|
| 1 | **Add Subscription** | ⭐⭐⭐ Hard | 26 | 🔴 Highest Priority |
| 2 | **Select Package** | ⭐⭐ Medium | 12 | 🟡 Prerequisite for Add |
| 3 | **Dialogs** (Wait for Person 1) | ⭐⭐ Medium | 6 | 🟠 Week 4 (after P1) |
| 4 | **Notification Center** | ⭐ Easy | 6 | 🟢 Week 5 (quick win) |

### 📝 Responsibilities

**Person 2 (นะ)'s Role:**
- 📋 Form mastery (validation, error handling)
- 🔀 Manage dual-path navigation (Preset vs Custom)
- ✅ Implement form validation rules
- 🎯 Create reusable form components
- 🧪 Unit test validation logic
- 📊 Setup mock save logic

### 📌 Key Dependencies

```
Person 1: Dashboard + Dialogs (Week 3-4)
    ↓
Select Package (Week 2-3) ← Can start early
    ↓
Add Subscription (Week 3-4) ← Depends on Dialogs
    ↓
Notification Center (Week 5)
```

### 💻 Tasks Breakdown

#### Week 2: Select Package (Start Early)
```
[ Day 1-3 ] Package List Screen
  - Fetch/display mockPackages
  - Category tabs (Streaming, AI, Cloud, Creative, Other)
  - Search functionality
  - Selection logic (tap card → select this package)

[ Day 4-5 ] Navigation Flow
  - Seamless back to Add form with selected package
  - Pass package data via route parameters
```

#### Week 3-4: Add Subscription (Main Task)
```
[ Week 3 ]
  Day 1-2: Setup form structure
    - Decide: SingleChildScrollView vs TabBar approach
    - Create form state notifier
    - Mock save to local storage
  
  Day 3-5: Implement paths
    Path A (Preset):
      - Tap "Pick from List" → Select Package
      - Return with package data
      - Pre-fill: name, category, defaultPrice
      - Allow override price
    
    Path B (Manual):
      - Show custom form directly
      - All fields: name, price, category, billing period, etc.

[ Week 4 ]
  Day 1-3: Validation & UX
    - Name field: not empty, min 3 chars
    - Price field: positive number, max 5000
    - Category: must select
    - Billing period: must select
    - Show inline errors
    - Disable submit button if invalid
  
  Day 4-5: Final flow
    - Handle success → Back to Dashboard
    - Show success toast
    - Clear form state
    - Coordinate with Person 1 for Dialogs (if deletion needed)
```

#### Week 4-5: Wait for Dialogs, then use
```
[ When P1 finishes Dialogs ]
  - Integrate PIN verification for "Confirm & Add"
  - Maybe add optional delete checkbox
```

#### Week 5: Notification Center
```
[ Day 1-3 ] Notification List
  - Display mockNotifications
  - Filter tabs: All, Unread, Archived
  - Timestamp formatting
  - Notification tile widget

[ Day 4-5 ] Interactions
  - Tap to mark as read
  - Swipe to dismiss
  - Empty state when no notifications
```

---

## 👨‍🚀 PERSON 3: อาทิตย์ (Auth & User Management Lead)

### 📋 Tasks (4 items | 50 hours total)

| # | Task | Difficulty | Est. Hours | Status |
|---|------|-----------|-----------|--------|
| 1 | **Login** | ⭐⭐ Medium | 14 | 🔴 Critical Path |
| 2 | **Subscription Detail** | ⭐⭐ Medium | 12 | 🟡 After Dashboard (P1) |
| 3 | **Edit Subscription** | ⭐⭐ Medium | 12 | 🟡 After Add (P2) |
| 4 | **Settings** | ⭐⭐ Medium | 12 | 🟠 Week 5-6 |
| 5 | **Profile** | ⭐ Easy | 6 | 🟢 Week 5 |

### 📝 Responsibilities

**Person 3 (อาทิตย์)'s Role:**
- 🔐 Authentication flow (OAuth mock)
- 👤 User state management (Riverpod)
- ⚙️ Settings persistence
- 📸 Profile management
- 🔗 Coordinate with Detail/Edit for subscription updates
- 📝 Documentation

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
[ Day 1-3 ] Login Screen
  - OAuth Google button (mock: auto-login)
  - OAuth Apple button (mock: auto-login)
  - "Continue as guest" option
  - Loading state during login
  - Error handling

[ Day 3-4 ] Auth Provider Setup
  - StateNotifierProvider<AuthNotifier>
  - Mock user object
  - Token management (mock storage)
  - Redirect to Dashboard on success

[ Day 5 ] Navigation Integration
  - Router config: if logged in → Dashboard, else → Login
  - Logout flow from Settings (later)
```

#### Week 4: Subscription Detail
```
[ Day 1-2 ] Screen Layout
  - Fetch subscription by ID
  - Display: name, price, category, status, confidence
  - Show next billing date
  - Display usage stats placeholder (Phase 2)

[ Day 3-4 ] Interactive Elements
  - Edit button → Navigate to Edit screen
  - Delete button → Show Confirm Dialog → Delete
  - Undo on SnackBar (delete undo)
  - Error handling for missing data

[ Day 5 ] Polish
  - Loading skeleton
  - Error state
  - Animations
```

#### Week 4: Edit Subscription (Parallel with Detail)
```
[ Day 1-2 ] Form Pre-fill
  - Similar form to Add Subscription
  - Pre-fill all fields from subscription data
  - Fetch from subscriptionProvider.family(id)

[ Day 3-4 ] Update Logic
  - Validation (same as Add)
  - Mock update to local storage
  - Success notification → Back to Dashboard
  - Handle delete from this screen too

[ Day 5 ] Testing
  - Verify pre-fill works
  - Verify save works
  - Verify navigation
```

#### Week 5-6: Settings + Profile
```
[ Week 5 ]
  Day 1-3: Settings Screen
    Sections:
    - Financial: Monthly income, currency
    - Security: Biometric toggle, PIN change, Login method
    - Notifications: Remind before (days), sound, vibrate
    - General: Language, theme, version
    - Links: About, Privacy, Terms
    - Logout button
    
    Implementation:
    - Create settingsProvider (StateNotifierProvider)
    - All toggles → immediate UI + auto-save to storage
    - Income field → EditDialog on tap
    - Save to SharedPreferences (mock)

  Day 4-5: Profile Screen
    - Display user avatar (mock)
    - Show name (edit on tap)
    - Show email (read-only)
    - Display income summary
    - Display quick stats (total cost, creep score, services count)
    - Edit button → EditProfileModal
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
  Person 2 (นะ):      [Select Package] ████████
  Person 3 (อาทิตย์): [Login] ████████

Week 3:
  Person 1 (เน):      [Dashboard Refactor (Part 1)] ████████████████
  Person 2 (นะ):      [Select Package] ████████
  Person 3 (อาทิตย์): --------

Week 4:
  Person 1 (เน):      [Dashboard Refactor (Part 2)] ████████████████
  Person 2 (นะ):      [Add Subscription (Part 1)] ████████████████
  Person 3 (อาทิตย์): [Subscription Detail] ████████
                     [Edit Subscription] ████████

Week 5:
  Person 1 (เน):      [Dialogs] ████████
  Person 2 (นะ):      [Add Subscription (Part 2)] ████████
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
3. Dialogs (P1, Week 4) — Used by Add/Edit
4. Add Subscription (P2, Week 3-4) — Depends on Dialogs
5. Edit Subscription (P3, Week 4) — Depends on Add validation logic
6. Others (P2, P3, Week 5-6) — Independent after above
```

---

## 🎯 Success Criteria per Person

### Person 1 (เน) ✅
- [x] Startup screens + focused 4-tab mobile shell pass widget tests
- [x] Responsive design verified (mobile 375px + desktop 1200px)
- [x] Repository/navigation providers working correctly
- [x] Architecture and current integration points documented
- [ ] 90%+ test coverage for providers
- [ ] Onboarding smooth with 60 FPS animations

### Person 2 (นะ) ✅
- [ ] Add Subscription form complete with all validations
- [ ] Dual path (Preset/Custom) working seamlessly
- [ ] Select Package list with search functional
- [ ] Notification list displaying correctly
- [ ] Form validation rules tested
- [ ] Mock save logic working

### Person 3 (อาทิตย์) ✅
- [ ] Login flow complete (OAuth mock)
- [ ] Subscription Detail/Edit forms pre-filled correctly
- [ ] Settings all toggles and inputs working
- [ ] Profile display and edit working
- [ ] User data persisted to mock storage
- [ ] Settings changes reflected across app

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

| Person | Screens | Tasks | Hard | Medium | Easy | Total Hrs |
|--------|---------|-------|------|--------|------|-----------|
| **P1 (เน)** | 4 | Splash, Onboarding, Dashboard, Dialogs | 1 | 2 | 1 | 52 |
| **P2 (นะ)** | 4 | Select Package, Add Subscription, Notification, (Dialogs) | 1 | 2 | 1 | 50 |
| **P3 (อาทิตย์)** | 5 | Login, Detail, Edit, Settings, Profile | 0 | 4 | 1 | 56 |
| **Total** | **12** | | **2** | **8** | **3** | **158 hrs** |

---

## 🎓 Learning Opportunities

### Person 1 (เน):
- **Riverpod** mastery (providers, state management)
- **Responsive design** patterns
- **Widget composition** and reusability
- **Code architecture** leadership

### Person 2 (นะ):
- **Form validation** patterns
- **Navigation flows** between multiple screens
- **UX/DX** polish for complex interactions
- **Testing** validation logic

### Person 3 (อาทิตย์):
- **Authentication** flows
- **State persistence** (SharedPreferences)
- **Data binding** between screens
- **User settings** management

---

## 💡 Tips for Success

### For Person 1 (เน - Lead):
- ✅ Be available for questions from P2 & P3
- ✅ Complete Setup tasks ASAP (blocking others)
- ✅ Review code daily (ensure consistency)
- ✅ Anticipate blockers early

### For Person 2 (นะ - Forms):
- ✅ Start Select Package early (doesn't depend on Dashboard)
- ✅ Create reusable form validation utilities
- ✅ Test all edge cases (empty, invalid data, network errors)
- ✅ Design form for easy reuse in Edit screen

### For Person 3 (อาทิตย์ - Auth & User):
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
- [x] Five destinations integrated after Settings/Profile team merge (original Option 5 remains a future IA decision)
- [x] Loading/error/refresh states working
- [x] Tablet/desktop layout verified

**Week 4:**
- [ ] PIN dialog deferred until a real sensitive action is in MVP scope (YAGNI)
- [ ] Biometric dialog deferred until a real sensitive action is in MVP scope (YAGNI)
- [x] Generic confirmation dialog created
- [x] Implemented confirmation flows covered by widget tests

**Week 5+:**
- [ ] Code review for P2 & P3
- [ ] Bug fixes & polish
- [x] Repository/navigation implementation documentation

---

### Person 2 (นะ) — Weekly Checklist

**Week 1:**
- [ ] Feature branch created
- [ ] Riverpod providers understood

**Week 2:**
- [ ] Select Package list UI complete
- [ ] Search/filter working
- [ ] Navigation to Add works

**Week 3-4:**
- [ ] Add Subscription form UI done
- [ ] Validation logic complete
- [ ] Preset path tested
- [ ] Custom path tested
- [ ] Mock save working

**Week 5:**
- [ ] Dialogs integrated
- [ ] Notification Center UI complete
- [ ] Navigation tested

**Week 5+:**
- [ ] Unit tests for validation
- [ ] Polish & refinement

---

### Person 3 (อาทิตย์) — Weekly Checklist

**Week 1:**
- [ ] Feature branch created
- [ ] Understand auth flow

**Week 2:**
- [ ] Login screen UI complete
- [ ] OAuth mock working
- [ ] Navigation to Dashboard works

**Week 4:**
- [ ] Subscription Detail screen done
- [ ] Fetch by ID working
- [ ] Edit button navigation works
- [ ] Delete flow tested

**Week 4-5:**
- [ ] Edit Subscription form done
- [ ] Pre-fill verified
- [ ] Save/update working

**Week 5-6:**
- [ ] Settings all sections done
- [ ] Profile display done
- [ ] Toggles/inputs working
- [ ] Persistence verified

**Week 6+:**
- [ ] Polish & refinement
- [ ] Testing complete

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

**Ready to execute! 🚀**
