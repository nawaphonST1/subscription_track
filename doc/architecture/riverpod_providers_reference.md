# 📘 เอกสารอ้างอิง Riverpod Providers & Feature Modules Inventory

เอกสารนี้รวบรวม **รายการ Riverpod Providers ทั้งหมดในโปรเจกต์ Subscription Track** โดยแบ่งตามสถาปัตยกรรม **Feature-First Clean Architecture** รายละเอียดของแต่ละไฟล์ หน้าที่ ความรับผิดชอบ และการเชื่อมโยงข้อมูลระหว่างโมดูลต่างๆ

---

## 📊 1. ตารางสรุปภาพรวม Providers ทั้งหมดในระบบ (Providers Summary Matrix)

| โมดูล (Feature) | ชื่อ Provider | ชนิด (Type) | ไฟล์ต้นทาง (File Location) | หน้าที่และความรับผิดชอบหลัก |
| --------------- | ------------- | ----------- | -------------------------- | --------------------------- |
| **App Core** | `themeModeProvider` | `NotifierProvider` | [`apps/mobile/lib/app/application/theme_mode_controller.dart`](../../apps/mobile/lib/app/application/theme_mode_controller.dart) | จัดการโหมดธีมของแอป (Light / Dark) |
| **App Core** | `currentTabProvider` | `NotifierProvider` | [`apps/mobile/lib/app/application/current_tab_controller.dart`](../../apps/mobile/lib/app/application/current_tab_controller.dart) | ควบคุม Index แถบเมนูหลัก (Tab 0-4) |
| **App Core** | `mockAuthBypassProvider` | `NotifierProvider` | [`apps/mobile/lib/app/application/app_flow_provider.dart`](../../apps/mobile/lib/app/application/app_flow_provider.dart) | สวิตช์เปิด/ปิดการข้าม Auth สำหรับ Dev/Test |
| **App Core** | `appFlowProvider` | `Provider` | [`apps/mobile/lib/app/application/app_flow_provider.dart`](../../apps/mobile/lib/app/application/app_flow_provider.dart) | สรุปสถานะแอป (Initializing / Onboarding / Authenticated) |
| **App Core** | `appRouterProvider` | `Provider` | [`apps/mobile/lib/app/routing/app_router.dart`](../../apps/mobile/lib/app/routing/app_router.dart) | สร้างอินสแตนซ์ `GoRouter` สำหรับควบคุมทิศทางการเปลี่ยนหน้า |
| **Security Core** | `securityPinProvider` | `NotifierProvider` | [`apps/mobile/lib/core/security/pin_provider.dart`](../../apps/mobile/lib/core/security/pin_provider.dart) | จัดการและตรวจสอบรหัส PIN ความปลอดภัย 6 หลัก |
| **Auth** | `authRepositoryProvider` | `Provider` | [`apps/mobile/lib/features/auth/application/auth_provider.dart`](../../apps/mobile/lib/features/auth/application/auth_provider.dart) | ให้บริการ Data Source สำหรับเข้าสู่ระบบ |
| **Auth** | `authProvider` | `AsyncNotifierProvider` | [`apps/mobile/lib/features/auth/application/auth_provider.dart`](../../apps/mobile/lib/features/auth/application/auth_provider.dart) | เก็บและควบคุม State ของผู้ใช้งานปัจจุบัน (`User?`) |
| **Subscriptions** | `subscriptionRepositoryProvider` | `Provider` | [`apps/mobile/lib/features/subscriptions/application/subscription_list_controller.dart`](../../apps/mobile/lib/features/subscriptions/application/subscription_list_controller.dart) | ให้บริการ Repository ของ Subscription |
| **Subscriptions** | `subscriptionListProvider` | `AsyncNotifierProvider` | [`apps/mobile/lib/features/subscriptions/application/subscription_list_controller.dart`](../../apps/mobile/lib/features/subscriptions/application/subscription_list_controller.dart) | **Source of Truth** รายการ Subscription ทั้งหมด (CRUD + Auto-import) |
| **Subscriptions** | `subscriptionByIdProvider` | `FutureProvider.family` | [`apps/mobile/lib/features/subscriptions/application/subscription_list_controller.dart`](../../apps/mobile/lib/features/subscriptions/application/subscription_list_controller.dart) | ค้นหา Subscription ตาม ID |
| **Subscriptions** | `subscriptionFilterProvider` | `NotifierProvider` | [`apps/mobile/lib/features/subscriptions/application/subscription_filter_controller.dart`](../../apps/mobile/lib/features/subscriptions/application/subscription_filter_controller.dart) | ถือ State การค้นหาคำและหมวดหมู่การกรอง |
| **Subscriptions** | `visibleSubscriptionsProvider` | `Provider` | [`apps/mobile/lib/features/subscriptions/application/subscription_filter_controller.dart`](../../apps/mobile/lib/features/subscriptions/application/subscription_filter_controller.dart) | คำนวณรายการ Subscription ที่ผ่านการกรองแล้ว |
| **Subscriptions** | `subscriptionReadModelsProvider` | `Provider` | [`apps/mobile/lib/features/subscriptions/application/subscription_read_model.dart`](../../apps/mobile/lib/features/subscriptions/application/subscription_read_model.dart) | **Public Boundary** แปลงข้อมูลส่งให้ Dashboard/Savings |
| **Subscriptions** | `subscriptionCommandsProvider` | `Provider` | [`apps/mobile/lib/features/subscriptions/application/subscription_read_model.dart`](../../apps/mobile/lib/features/subscriptions/application/subscription_read_model.dart) | **Public Command Boundary** รับคำสั่งสั่งงานจากโมดูลอื่น |
| **Dashboard** | `dashboardSummaryProvider` | `Provider` | [`apps/mobile/lib/features/dashboard/application/dashboard_summary_provider.dart`](../../apps/mobile/lib/features/dashboard/application/dashboard_summary_provider.dart) | คำนวณ Creep Risk %, ยอดจ่ายรวม, บริการไม่ได้ใช้ |
| **Savings** | `savingsViewStateProvider` | `Provider` | [`apps/mobile/lib/features/savings/application/savings_provider.dart`](../../apps/mobile/lib/features/savings/application/savings_provider.dart) | คำนวณยอดเงินประหยัดรวมต่อปีสำหรับการจำลองยกเลิก |
| **Savings** | `savingsActionsProvider` | `Provider` | [`apps/mobile/lib/features/savings/application/savings_provider.dart`](../../apps/mobile/lib/features/savings/application/savings_provider.dart) | รวบรวม Actions หน้า Savings ส่งต่อสั่งงาน Subscriptions |
| **Profile** | `paymentCardRepositoryProvider` | `Provider` | [`apps/mobile/lib/features/profile/application/payment_card_linking_controller.dart`](../../apps/mobile/lib/features/profile/application/payment_card_linking_controller.dart) | ให้บริการ Repository ของบัตรชำระเงิน |
| **Profile** | `linkedPaymentCardsProvider` | `AsyncNotifierProvider` | [`apps/mobile/lib/features/profile/application/payment_card_linking_controller.dart`](../../apps/mobile/lib/features/profile/application/payment_card_linking_controller.dart) | จัดการรายการบัตรที่เชื่อมต่อแล้ว + Auto-import Subscriptions |
| **Profile** | `availablePaymentCardsProvider` | `FutureProvider` | [`apps/mobile/lib/features/profile/application/payment_card_linking_controller.dart`](../../apps/mobile/lib/features/profile/application/payment_card_linking_controller.dart) | ค้นหารายการบัตรจำลองที่พร้อมให้ผูกเพิ่ม |
| **Profile** | `userIncomeProvider` | `NotifierProvider` | [`apps/mobile/lib/features/profile/application/user_income_controller.dart`](../../apps/mobile/lib/features/profile/application/user_income_controller.dart) | คำนวณรายได้/ยอดเงินรวมอัตโนมัติจากบัตรที่เชื่อมต่อ |
| **Profile** | `personalInfoProvider` | `NotifierProvider` | [`apps/mobile/lib/features/profile/application/personal_info_controller.dart`](../../apps/mobile/lib/features/profile/application/personal_info_controller.dart) | จัดการข้อมูลส่วนตัว (ชื่อ, นามสกุล, เบอร์โทร, วันเกิด) |
| **Settings** | `notificationReminderProvider` | `NotifierProvider` | [`apps/mobile/lib/features/settings/application/notification_reminder_controller.dart`](../../apps/mobile/lib/features/settings/application/notification_reminder_controller.dart) | ถือ State เปิด/ปิดการตั้งค่าแจ้งเตือนเตือนล่วงหน้า |
| **Notifications** | `notificationCenterProvider` | `AsyncNotifierProvider` | [`apps/mobile/lib/features/notifications/application/notification_center_controller.dart`](../../apps/mobile/lib/features/notifications/application/notification_center_controller.dart) | จัดการรายการแจ้งเตือน (อ่านแล้ว, ล้างรายการ) |
| **Onboarding** | `onboardingProvider` | `NotifierProvider` | [`apps/mobile/lib/features/onboarding/application/onboarding_controller.dart`](../../apps/mobile/lib/features/onboarding/application/onboarding_controller.dart) | จดจำสถานะว่าผ่านสไลด์แนะนำแอปแล้วหรือยัง |

---

## 🕸️ 2. แผนผังความสัมพันธ์ระหว่าง Providers (Cross-Feature Dependency Graph)

```mermaid
flowchart TD
    %% Repositories
    SubRepo["subscriptionRepositoryProvider"]
    CardRepo["paymentCardRepositoryProvider"]
    AuthRepo["authRepositoryProvider"]

    %% Core Data Sources & Notifiers
    SubList["subscriptionListProvider\nAsyncNotifierProvider"]
    LinkedCards["linkedPaymentCardsProvider\nAsyncNotifierProvider"]
    AuthNotif["authProvider\nAsyncNotifierProvider"]

    %% Application State Derivations
    FilterState["subscriptionFilterProvider"]
    VisibleSubs["visibleSubscriptionsProvider"]
    ReadModels["subscriptionReadModelsProvider"]
    UserIncome["userIncomeProvider"]
    
    %% Analytics & Simulation
    DashboardSum["dashboardSummaryProvider"]
    SavingsState["savingsViewStateProvider"]
    AppFlow["appFlowProvider"]

    %% UI Consumers
    SubUI["SubscriptionsTab"]
    DashUI["DashboardTab"]
    SaveUI["SavingsTab"]
    HeaderUI["MainAppHeader"]
    ProfileUI["ProfileTab / LinkedAccountsCard"]

    %% Connections
    SubRepo --> SubList
    CardRepo --> LinkedCards
    AuthRepo --> AuthNotif

    LinkedCards -->|Auto-import detected items| SubList
    LinkedCards -->|Calculate sum currentBalance| UserIncome

    SubList --> VisibleSubs
    FilterState --> VisibleSubs

    SubList --> ReadModels
    ReadModels --> DashboardSum
    ReadModels --> SavingsState

    UserIncome --> DashboardSum
    UserIncome --> HeaderUI

    AuthNotif --> AppFlow

    VisibleSubs --> SubUI
    DashboardSum --> DashUI
    SavingsState --> SaveUI
    LinkedCards --> ProfileUI
```

---

## 🧩 3. เจาะลึกรายฟีเจอร์และไฟล์ที่ใช้งาน Riverpod

---

### 🌐 1) App Core & Navigation Layer (`apps/mobile/lib/app/`)

#### 📁 [`apps/mobile/lib/app/application/theme_mode_controller.dart`](../../apps/mobile/lib/app/application/theme_mode_controller.dart)
- **Providers**: `themeModeProvider` (`NotifierProvider<ThemeModeController, ThemeMode>`)
- **การทำงาน**: สลับและเก็บความต้องการเรื่องโหมดธีมของผู้ใช้ (System / Light / Dark)
- **การนำไปใช้ใน UI**: [`apps/mobile/lib/app/app.dart`](../../apps/mobile/lib/app/app.dart) ใช้ `ref.watch(themeModeProvider)` เพื่อเปลี่ยน `ThemeData` ของทั้งแอป

#### 📁 [`apps/mobile/lib/app/application/current_tab_controller.dart`](../../apps/mobile/lib/app/application/current_tab_controller.dart)
- **Providers**: `currentTabProvider` (`NotifierProvider<CurrentTabController, int>`)
- **การทำงาน**: เก็บ Index แท็บปัจจุบันที่เปิดอยู่ (0: Dashboard, 1: Subscriptions, 2: Savings, 3: Settings, 4: Profile)
- **การนำไปใช้ใน UI**: [`apps/mobile/lib/app/presentation/main_navigation_shell.dart`](../../apps/mobile/lib/app/presentation/main_navigation_shell.dart) อ่าน `ref.watch(currentTabProvider)` เพื่อเปลี่ยนหน้าใน `IndexedStack`

#### 📁 [`apps/mobile/lib/app/application/app_flow_provider.dart`](../../apps/mobile/lib/app/application/app_flow_provider.dart)
- **Providers**: 
  - `mockAuthBypassProvider` (`NotifierProvider<MockAuthBypassController, bool>`)
  - `appFlowProvider` (`Provider<AppFlowState>`)
- **การทำงาน**: รวมสถานะข้ามฟีเจอร์ (`authProvider` และ `onboardingProvider`) เพื่อประเมินสถานะของแอปในจุดเดียว
- **การนำไปใช้ใน UI**: [`apps/mobile/lib/app/routing/app_router.dart`](../../apps/mobile/lib/app/routing/app_router.dart) ใช้ `ref.listen` ฟัง `appFlowProvider` เพื่อแจ้งเตือน `_RouterRefreshNotifier` ทำการประเมิน Redirect เส้นทาง

---

### 🛡️ 2) Security Core (`apps/mobile/lib/core/security/`)

#### 📁 [`apps/mobile/lib/core/security/pin_provider.dart`](../../apps/mobile/lib/core/security/pin_provider.dart)
- **Providers**: `securityPinProvider` (`NotifierProvider<SecurityPinNotifier, String>`)
- **การทำงาน**: เก็บและยืนยันรหัส PIN ความปลอดภัย 6 หลัก มีเมธอด `updatePin()` และ `verifyPin()`
- **การนำไปใช้ใน UI**: 
  - [`apps/mobile/lib/core/widgets/pin_verification_dialog.dart`](../../apps/mobile/lib/core/widgets/pin_verification_dialog.dart): เรียก `ref.read(securityPinProvider.notifier).verifyPin(input)` เพื่อตรวจสอบสิทธิ์
  - [`apps/mobile/lib/core/widgets/change_pin_dialog.dart`](../../apps/mobile/lib/core/widgets/change_pin_dialog.dart): สั่งอัปเดตรหัส PIN ใหม่

---

### 🔐 3) Auth & Identity (`apps/mobile/lib/features/auth/`)

#### 📁 [`apps/mobile/lib/features/auth/application/auth_provider.dart`](../../apps/mobile/lib/features/auth/application/auth_provider.dart)
- **Providers**: 
  - `authRepositoryProvider` (`Provider<AuthRepository>`)
  - `authProvider` (`AsyncNotifierProvider<AuthNotifier, User?>`)
- **การทำงาน**: ควบคุมคำสั่งเข้าสู่ระบบด้วย Google/Apple และการออกจากระบบ (`logout()`)
- **การนำไปใช้ใน UI**: [`apps/mobile/lib/features/auth/presentation/login_screen.dart`](../../apps/mobile/lib/features/auth/presentation/login_screen.dart) ฟังการเปลี่ยนแปลงผ่าน `ref.listen` เมื่อล็อกอินสำเร็จจะย้ายหน้าไปยัง Dashboard

---

### 📦 4) Subscriptions Feature (`apps/mobile/lib/features/subscriptions/`)

#### 📁 [`apps/mobile/lib/features/subscriptions/application/subscription_list_controller.dart`](../../apps/mobile/lib/features/subscriptions/application/subscription_list_controller.dart)
- **Providers**: 
  - `subscriptionRepositoryProvider` (`Provider<SubscriptionRepository>`)
  - `subscriptionListProvider` (`AsyncNotifierProvider<SubscriptionListController, List<Subscription>>`)
  - `subscriptionByIdProvider` (`FutureProvider.family<Subscription, String>`)
- **การทำงาน**: **Source of Truth** บริหารจัดการรายการสมัครสมาชิก (เพิ่ม, แก้ไข, ลบ, ติ๊กเลือกจำลอง, Auto-import จากบัตร)
- **การนำไปใช้ใน UI**: [`apps/mobile/lib/features/subscriptions/presentation/subscriptions_tab.dart`](../../apps/mobile/lib/features/subscriptions/presentation/subscriptions_tab.dart)

#### 📁 [`apps/mobile/lib/features/subscriptions/application/subscription_filter_controller.dart`](../../apps/mobile/lib/features/subscriptions/application/subscription_filter_controller.dart)
- **Providers**: 
  - `subscriptionFilterProvider` (`NotifierProvider<SubscriptionFilterController, SubscriptionFilterState>`)
  - `visibleSubscriptionsProvider` (`Provider<AsyncValue<List<Subscription>>>`)
- **การทำงาน**: กรองรายการ Subscription ตามคำค้นหาและหมวดหมู่ (Streaming, AI, Cloud, Creative)

#### 📁 [`apps/mobile/lib/features/subscriptions/application/subscription_read_model.dart`](../../apps/mobile/lib/features/subscriptions/application/subscription_read_model.dart)
- **Providers**: 
  - `subscriptionReadModelsProvider` (`Provider<AsyncValue<List<SubscriptionReadModel>>>`)
  - `subscriptionCommandsProvider` (`Provider<SubscriptionCommands>`)
- **การทำงาน**: ทำหน้าที่เป็น **Public Boundary** ให้ Dashboard และ Savings นำไปคำนวณสถิติโดยไม่ต้องพึ่งพา Data Domain ของ Subscriptions โดยตรง

---

### 📊 5) Dashboard Feature (`apps/mobile/lib/features/dashboard/`)

#### 📁 [`apps/mobile/lib/features/dashboard/application/dashboard_summary_provider.dart`](../../apps/mobile/lib/features/dashboard/application/dashboard_summary_provider.dart)
- **Providers**: `dashboardSummaryProvider` (`Provider<AsyncValue<DashboardSummary>>`)
- **การทำงาน**: คำนวณสรุปสถิติสำคัญ:
  - **Creep Risk Score (%)**: `(ยอดจ่ายรวมรายเดือน / รายได้รวม) * 100`
  - **Unused Services**: นับจำนวนรายการที่ไม่ได้เปิดใช้งานบ่อย
  - **Upcoming Renewals**: จัดเรียงวันตัดเงินล่วงหน้า
- **การนำไปใช้ใน UI**: [`apps/mobile/lib/features/dashboard/presentation/dashboard_tab.dart`](../../apps/mobile/lib/features/dashboard/presentation/dashboard_tab.dart) อ่านค่ามาแสดงผลในการ์ด Hero Payout Card และ Bento Grid

---

### 💰 6) Savings Simulation Feature (`apps/mobile/lib/features/savings/`)

#### 📁 [`apps/mobile/lib/features/savings/application/savings_provider.dart`](../../apps/mobile/lib/features/savings/application/savings_provider.dart)
- **Providers**: 
  - `savingsViewStateProvider` (`Provider<AsyncValue<SavingsViewState>>`)
  - `savingsActionsProvider` (`Provider<SavingsActions>`)
- **การทำงาน**: คำนวณยอดเงินประหยัดรวมต่อปี ($\text{yearlySavings} = \sum \text{monthlyPrice} \times 12$) จากรายการที่ติ๊กเลือกสิมูเลชัน
- **การนำไปใช้ใน UI**: [`apps/mobile/lib/features/savings/presentation/savings_tab.dart`](../../apps/mobile/lib/features/savings/presentation/savings_tab.dart)

---

### 👤 7) Profile & Payment Cards Feature (`apps/mobile/lib/features/profile/`)

#### 📁 [`apps/mobile/lib/features/profile/application/payment_card_linking_controller.dart`](../../apps/mobile/lib/features/profile/application/payment_card_linking_controller.dart)
- **Providers**: 
  - `paymentCardRepositoryProvider` (`Provider<PaymentCardRepository>`)
  - `linkedPaymentCardsProvider` (`AsyncNotifierProvider<PaymentCardLinkingController, List<PaymentCard>>`)
  - `availablePaymentCardsProvider` (`FutureProvider<List<PaymentCard>>`)
- **การทำงาน**: จัดการการเชื่อมต่อบัตรชำระเงิน และสั่ง Auto-import รายการ Subscription ที่พบในบัตรเข้าสู่ `subscriptionListProvider` อัตโนมัติ

#### 📁 [`apps/mobile/lib/features/profile/application/user_income_controller.dart`](../../apps/mobile/lib/features/profile/application/user_income_controller.dart)
- **Providers**: `userIncomeProvider` (`NotifierProvider<UserIncomeController, double>`)
- **การทำงาน**: ดึงค่ายอดเงินคงเหลือรวมจากบัตรที่เชื่อมต่อ (`linkedPaymentCardsProvider`) เพื่อใช้เป็นฐานรายได้คำนวณ Creep Risk

#### 📁 [`apps/mobile/lib/features/profile/application/personal_info_controller.dart`](../../apps/mobile/lib/features/profile/application/personal_info_controller.dart)
- **Providers**: `personalInfoProvider` (`NotifierProvider<PersonalInfoController, PersonalInfo>`)
- **การทำงาน**: จัดการข้อมูลส่วนตัวของผู้ใช้ (ชื่อ, นามสกุล, เบอร์โทร, วันเกิด)

---

### ⚙️ 8) Settings Feature (`apps/mobile/lib/features/settings/`)

#### 📁 [`apps/mobile/lib/features/settings/application/notification_reminder_controller.dart`](../../apps/mobile/lib/features/settings/application/notification_reminder_controller.dart)
- **Providers**: `notificationReminderProvider` (`NotifierProvider<NotificationReminderController, NotificationReminderState>`)
- **การทำงาน**: ถือ State เปิด/ปิดการแจ้งเตือนเตือนล่วงหน้า และจำนวนวันเตือนความจำ

---

### 🔔 9) Notifications Center Feature (`apps/mobile/lib/features/notifications/`)

#### 📁 [`apps/mobile/lib/features/notifications/application/notification_center_controller.dart`](../../apps/mobile/lib/features/notifications/application/notification_center_controller.dart)
- **Providers**: `notificationCenterProvider` (`AsyncNotifierProvider<NotificationCenterController, List<NotificationItem>>`)
- **การทำงาน**: จัดการกล่องการแจ้งเตือน (ทำเครื่องหมายอ่านแล้ว, ล้างรายการ)

---

### 🚀 10) Onboarding Feature (`apps/mobile/lib/features/onboarding/`)

#### 📁 [`apps/mobile/lib/features/onboarding/application/onboarding_controller.dart`](../../apps/mobile/lib/features/onboarding/application/onboarding_controller.dart)
- **Providers**: `onboardingProvider` (`NotifierProvider<OnboardingController, bool>`)
- **การทำงาน**: จดจำสถานะว่าผู้ใช้เคยผ่านหน้าสไลด์แนะนำแอปแล้วหรือยัง

---

## 🛠️ 4. ตัวอย่างการใช้งานใน UI และการทดสอบ (Testing & UI Usage)

### 1) การดูและอ่านค่าใน UI (ConsumerWidget)
```dart
class ProfileIdentityCard extends ConsumerWidget {
  const ProfileIdentityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // อ่านข้อมูลส่วนตัวจาก personalInfoProvider
    final info = ref.watch(personalInfoProvider);

    return ListTile(
      title: Text('${info.firstName} ${info.lastName}'),
      subtitle: Text(info.phoneNumber),
    );
  }
}
```

### 2) การส่งคำสั่งอัปเดต State (User Interaction)
```dart
ElevatedButton(
  onPressed: () {
    // เรียกใช้ action สลับธีมเป็นโหมดมืด
    ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
  },
  child: const Text('สลับเป็นโหมดกลางคืน'),
);
```

### 3) การ Override Provider ใน Unit / Widget Test
```dart
testWidgets('แสดงผลหน้า Dashboard พร้อมข้อมูล Mock', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // Mock ข้อมูล Repository ไม่ให้ดึงข้อมูลจริงในขณะทดสอบ
        subscriptionRepositoryProvider.overrideWithValue(
          InMemorySubscriptionRepository(ioDelay: Duration.zero),
        ),
      ],
      child: const MaterialApp(home: MainNavigationShell()),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('hero-payout-card')), findsOneWidget);
});
```
