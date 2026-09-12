# 📦 Repository Tree Overview

> **📅 วันที่อัปเดต:** 2026-09-12 21:38:35  
> **👤 อัปเดตโดย:** Nekokun2004  
> **💻 คำสั่งที่ใช้:** `tree -a -I ".git|android|ios|linux|macos|windows|web" --gitignore --dirsfirst`  
> **⚠️ หมายเหตุ:** โครงสร้างไฟล์ในเอกสารนี้สร้างขึ้นโดยเคารพกฎการยกเว้นอย่างเคร่งครัด จะไม่อัปเดตไฟล์หรือโฟลเดอร์ที่ถูกระบุไว้ใน `.gitignore` และ `.dockerignore` (หากมี) โดยเด็ดขาด ไม่ว่ากรณีใดๆ ทั้งสิ้น เพื่อป้องกันไม่ให้ Temporary files, Build artifacts, Caches, Secrets หรือไฟล์ Generated ที่ไม่จำเป็นถูกนำเข้ามาบันทึกไว้ในผังโครงการ

---

## 🌳 โครงสร้างไดเรกทอรีพร้อมคำอธิบาย (Annotated Directory Tree)

```text
.
├── .agents
│   ├── skills                                          # Local Agent Skills Directory (clean-code, dart, flutter, tree-repo)
│   │   ├── clean-code
│   │   │   ├── agents
│   │   │   │   └── openai.yaml
│   │   │   └── SKILL.md
│   │   ├── dart-add-unit-test
│   │   │   └── SKILL.md
│   │   ├── dart-build-cli-app
│   │   │   └── SKILL.md
│   │   ├── dart-collect-coverage
│   │   │   └── SKILL.md
│   │   ├── dart-fix-runtime-errors
│   │   │   └── SKILL.md
│   │   ├── dart-generate-test-mocks
│   │   │   └── SKILL.md
│   │   ├── dart-migrate-to-checks-package
│   │   │   └── SKILL.md
│   │   ├── dart-resolve-package-conflicts
│   │   │   └── SKILL.md
│   │   ├── dart-run-static-analysis
│   │   │   └── SKILL.md
│   │   ├── dart-setup-ffi-assets
│   │   │   └── SKILL.md
│   │   ├── dart-use-ffigen
│   │   │   └── SKILL.md
│   │   ├── dart-use-pattern-matching
│   │   │   └── SKILL.md
│   │   ├── dart-use-primary-constructors
│   │   │   └── SKILL.md
│   │   ├── flutter-add-integration-test
│   │   │   └── SKILL.md
│   │   ├── flutter-add-widget-preview
│   │   │   └── SKILL.md
│   │   ├── flutter-add-widget-test
│   │   │   └── SKILL.md
│   │   ├── flutter-apply-architecture-best-practices
│   │   │   └── SKILL.md
│   │   ├── flutter-build-responsive-layout
│   │   │   └── SKILL.md
│   │   ├── flutter-fix-layout-issues
│   │   │   └── SKILL.md
│   │   ├── flutter-implement-json-serialization
│   │   │   └── SKILL.md
│   │   ├── flutter-setup-declarative-routing
│   │   │   └── SKILL.md
│   │   ├── flutter-setup-localization
│   │   │   └── SKILL.md
│   │   ├── flutter-use-http-package
│   │   │   └── SKILL.md
│   │   └── tree-repo                                   # Skill for generating and maintaining repository tree overview
│   │       └── SKILL.md                                # Skill instructions for AI Agent to maintain tree_repo
│   └── tree_repo
│       └── tree_repo.md                                # Repository tree overview guide with file annotations
├── doc
│   ├── architecture
│   │   ├── feature_first_architecture.md               # Feature-First Clean Architecture Specification
│   │   ├── riverpod_architecture_guide.md              # Comprehensive Riverpod Architecture & State Management Guide
│   │   └── riverpod_providers_reference.md             # Riverpod Providers Quick Reference & Cheat Sheet
│   ├── backend
│   │   └── .gitkeep
│   ├── devops
│   │   └── .gitkeep
│   ├── frontend
│   │   └── subscription_track_frontend_screens.md      # UI Screen Specifications, Theme Policy & Component Matrix
│   ├── task
│   │   └── team_task_allocation.md                     # Developer Task Allocation, Work Breakdown & Schedule
│   └── Subscription_Track_PRD.md                       # Product Requirement Document (PRD)
├── lib
│   ├── app
│   │   ├── application
│   │   │   ├── app_flow_provider.dart                  # App startup flow state provider
│   │   │   ├── current_tab_controller.dart             # Navigation shell tab index controller
│   │   │   └── theme_mode_controller.dart              # Application ThemeMode controller & themeModeProvider
│   │   ├── presentation
│   │   │   ├── widgets
│   │   │   │   ├── main_app_header.dart                # Main header with dynamic greeting, avatar, income chip & noti button
│   │   │   │   └── main_app_navigation.dart            # Adaptive navigation bar / navigation rail widget
│   │   │   ├── main_navigation_shell.dart              # Main shell with 5 Tabs & Adaptive Navigation (BottomNav/Rail)
│   │   │   └── splash_screen.dart                      # Branded Splash screen with startup session routing
│   │   ├── routing
│   │   │   ├── app_router.dart                         # GoRouter declarative configuration with deep-linked sub-routes
│   │   │   └── route_constants.dart                    # String route path constants
│   │   └── app.dart                                    # Root MaterialApp.router configured with Light & Dark Themes
│   ├── core
│   │   ├── errors
│   │   │   ├── failures.dart                           # Application failure & exception models
│   │   │   └── failures.freezed.dart                   # Freezed generated model code
│   │   ├── layout
│   │   │   └── app_breakpoints.dart                    # Responsive layout breakpoint constants
│   │   ├── security
│   │   │   └── pin_provider.dart                       # 6-digit Security PIN state controller (securityPinProvider)
│   │   ├── theme
│   │   │   ├── app_colors.dart                         # Color palette system constants
│   │   │   ├── app_dark_theme.dart                     # Dark ThemeData builder
│   │   │   ├── app_light_theme.dart                    # Light ThemeData builder
│   │   │   ├── app_theme.dart                          # Public Theme facade (AppTheme.light & AppTheme.dark)
│   │   │   └── app_typography.dart                     # Color-neutral Typography & TextStyles
│   │   ├── utils
│   │   │   └── logger.dart                             # Development logging utility
│   │   └── widgets
│   │       ├── change_pin_dialog.dart                  # 3-step PIN change dialog modal
│   │       ├── confirmation_dialog.dart                # Theme-aware reusable confirmation dialog
│   │       ├── pin_verification_dialog.dart            # 6-digit PIN verification dialog modal with shake animation
│   │       └── service_icon.dart                       # Brand service icon rendering widget
│   ├── features
│   │   ├── auth
│   │   │   ├── application
│   │   │   │   ├── auth_provider.dart                  # Auth state notifier provider (Google/Apple/Guest)
│   │   │   │   └── auth_provider.g.dart                # JSON serializable / Riverpod generated code
│   │   │   ├── data
│   │   │   │   └── in_memory_auth_repository.dart      # InMemory authentication repository implementation
│   │   │   ├── domain
│   │   │   │   ├── auth_repository.dart                # Auth repository contract interface
│   │   │   │   ├── credit_card.dart                    # Credit card domain entity
│   │   │   │   ├── credit_card.freezed.dart            # Freezed generated model code
│   │   │   │   ├── credit_card.g.dart                  # JSON serializable / Riverpod generated code
│   │   │   │   ├── user.dart                           # User domain entity model
│   │   │   │   ├── user.freezed.dart                   # Freezed generated model code
│   │   │   │   └── user.g.dart                         # JSON serializable / Riverpod generated code
│   │   │   └── presentation
│   │   │       └── login_screen.dart                   # Login screen with Google, Apple & Guest sign-in
│   │   ├── dashboard
│   │   │   ├── application
│   │   │   │   └── dashboard_summary_provider.dart     # Dashboard summary & KPI calculator
│   │   │   └── presentation
│   │   │       ├── widgets
│   │   │       │   ├── dashboard_content.dart          # Main dashboard content layout
│   │   │       │   ├── dashboard_hero_card.dart        # Theme-aware Hero payout card with Creep Risk score
│   │   │       │   ├── dashboard_renewals_section.dart # Section for upcoming billing renewals
│   │   │       │   └── dashboard_unused_alert.dart     # Alert card for unused subscriptions
│   │   │       └── dashboard_tab.dart                  # Main Dashboard Tab view
│   │   ├── notifications
│   │   │   ├── application
│   │   │   │   └── notification_center_controller.dart # Notification center controller & filtering state
│   │   │   ├── data
│   │   │   │   └── mock_notification_data.dart         # Seed and mock notifications dataset
│   │   │   ├── domain
│   │   │   │   ├── app_notification.dart               # Notification domain model
│   │   │   │   ├── app_notification.freezed.dart       # Freezed generated model code
│   │   │   │   └── app_notification.g.dart             # JSON serializable / Riverpod generated code
│   │   │   └── presentation
│   │   │       ├── widgets
│   │   │       │   ├── notification_filter_bar.dart    # Choice chips filter for notifications (All/Unread/System)
│   │   │       │   └── notification_list.dart          # List view rendering grouped notifications
│   │   │       ├── notification_center_screen.dart     # Notification Center screen with 3 tabs
│   │   │       └── notification_ui_extensions.dart     # UI extensions for notification icons and styling
│   │   ├── onboarding
│   │   │   ├── application
│   │   │   │   └── onboarding_controller.dart          # Onboarding completion persistence state controller
│   │   │   └── presentation
│   │   │       ├── visuals
│   │   │       │   ├── renewal_alert_visual.dart       # Visual bento illustration for renewal alerts
│   │   │       │   ├── subscription_stack_visual.dart  # Visual bento illustration for subscription stack
│   │   │       │   └── unused_alert_visual.dart        # Visual bento illustration for unused alerts
│   │   │       ├── onboarding_controls.dart            # Story navigation controls, skip & next buttons
│   │   │       ├── onboarding_data.dart                # Onboarding slide content and feature descriptions
│   │   │       ├── onboarding_page.dart                # Onboarding slide layout template
│   │   │       ├── onboarding_progress_bar.dart        # Segmented progress bar widget
│   │   │       └── onboarding_screen.dart              # Onboarding PageView screen container
│   │   ├── profile
│   │   │   ├── application
│   │   │   │   ├── payment_card_linking_controller.dart # Controller managing payment cards & auto-import
│   │   │   │   ├── personal_info_controller.dart       # Personal user info state controller
│   │   │   │   └── user_income_controller.dart         # Income calculation derived from card balances
│   │   │   ├── data
│   │   │   │   └── in_memory_payment_card_repository.dart # Mock card repository (KBank, SCB, UOB, Krungsri)
│   │   │   ├── domain
│   │   │   │   ├── payment_card.dart                   # Payment card domain entity model
│   │   │   │   └── payment_card_repository.dart        # Payment card repository contract interface
│   │   │   └── presentation
│   │   │       ├── widgets
│   │   │       │   ├── linked_accounts_card.dart       # Card displaying linked banking accounts & balance
│   │   │       │   ├── personal_info_sheet.dart        # Modal bottom sheet for editing personal profile info
│   │   │       │   ├── profile_identity_card.dart      # User identity display card with avatar
│   │   │       │   └── profile_settings_card.dart      # Card containing account security & action items
│   │   │       ├── add_payment_card_sheet.dart         # Modal bottom sheet for adding card & auto-importing
│   │   │       ├── income_editor_sheet.dart            # Modal bottom sheet for manually editing income
│   │   │       ├── payment_card_ui_extensions.dart     # UI helpers for card bank branding & styling
│   │   │       └── profile_tab.dart                    # Profile Tab view displaying identity and cards
│   │   ├── savings
│   │   │   ├── application
│   │   │   │   └── savings_provider.dart               # Savings simulation & yearly target calculator
│   │   │   └── presentation
│   │   │       ├── widgets
│   │   │       │   ├── savings_checklist.dart          # Interactive checklist of cancellable subscriptions
│   │   │       │   └── savings_summary.dart            # Hero summary of potential monthly/yearly savings
│   │   │       └── savings_tab.dart                    # Savings Tab view & cancellation simulator
│   │   ├── settings
│   │   │   ├── application
│   │   │   │   └── notification_reminder_controller.dart # Reminder frequency and toggle state controller
│   │   │   └── presentation
│   │   │       └── settings_tab.dart                   # Settings Tab view with Dark/Light theme mode switch
│   │   └── subscriptions
│   │       ├── application
│   │       │   ├── subscription_filter_controller.dart # Controller for category, search & status filters
│   │       │   ├── subscription_form_validator.dart    # Form validation rules for subscription inputs
│   │       │   ├── subscription_list_controller.dart   # Riverpod AsyncNotifier for subscription CRUD
│   │       │   └── subscription_read_model.dart        # Read model boundary for subscription presentation
│   │       ├── data
│   │       │   └── in_memory_subscription_repository.dart # In-memory subscription data source implementation
│   │       ├── domain
│   │       │   ├── preset_package_catalog.dart         # Catalog of 10 popular subscription preset packages
│   │       │   ├── preset_package.dart                 # Preset package domain entity
│   │       │   ├── subscription.dart                   # Subscription domain entity model
│   │       │   ├── subscription.freezed.dart           # Freezed generated model code
│   │       │   ├── subscription.g.dart                 # JSON serializable / Riverpod generated code
│   │       │   └── subscription_repository.dart        # Subscription repository contract interface
│   │       └── presentation
│   │           ├── widgets
│   │           │   ├── preset_package_grid.dart        # Grid layout for browsing preset packages
│   │           │   ├── preset_picker_card.dart         # Card widget for picking preset subscription
│   │           │   ├── preset_search_field.dart        # Search input for filtering preset packages
│   │           │   ├── subscription_appearance_selector.dart # Color & icon selector widget
│   │           │   ├── subscription_collection.dart    # Subscription collection view
│   │           │   ├── subscription_detail_header.dart # Detail sheet header view
│   │           │   ├── subscription_detail_overview.dart # Detail sheet overview section
│   │           │   ├── subscription_detail_sheet.dart  # Modal bottom sheet for subscription details
│   │           │   ├── subscription_empty_state.dart   # Empty state view when no subscriptions exist
│   │           │   ├── subscription_filter_bar.dart    # Choice chips bar for category filters
│   │           │   ├── subscription_general_fields.dart # Theme-derived form input fields
│   │           │   ├── subscription_list_tile.dart     # Theme-derived list tile for subscription
│   │           │   ├── subscription_reminder_editor.dart # Editor widget for billing reminder days
│   │           │   └── usage_status_selector.dart      # Usage status selector chip bar
│   │           ├── add_subscription_screen.dart        # Screen for adding new custom or preset subscription
│   │           ├── select_package_screen.dart          # Screen for selecting preset packages from catalog
│   │           ├── subscriptions_tab.dart              # Subscriptions Tab view with search & filters
│   │           └── subscription_ui_extensions.dart     # UI extensions for badge status, categories & currency
│   └── main.dart                                       # App entrypoint running ProviderScope + App
├── test
│   ├── app
│   │   ├── application
│   │   │   ├── current_tab_controller_test.dart        # Unit tests for CurrentTabController
│   │   │   └── theme_mode_controller_test.dart         # Unit tests for ThemeModeController
│   │   ├── presentation
│   │   │   ├── main_navigation_shell_test.dart         # Responsive Widget tests for MainNavigationShell
│   │   │   └── splash_screen_theme_test.dart           # Splash screen theme tests
│   │   └── routing
│   │       └── app_router_test.dart                    # Declarative router navigation tests
│   ├── core
│   │   └── widgets
│   │       └── confirmation_dialog_test.dart           # Widget tests for ConfirmationDialog
│   └── features
│       ├── auth
│       │   └── application
│       │       └── auth_provider_test.dart             # Auth state notifier unit tests
│       ├── dashboard
│       │   └── application
│       │       └── dashboard_summary_provider_test.dart # Dashboard KPI calculations unit tests
│       ├── notifications
│       │   ├── application
│       │   │   └── notification_center_controller_test.dart # Notification controller unit tests
│       │   └── presentation
│       │       ├── notification_theme_test.dart        # Notification UI theme tests
│       │       └── notification_ui_extensions_test.dart # Notification formatting unit tests
│       ├── onboarding
│       │   ├── application
│       │   │   └── onboarding_controller_test.dart     # Onboarding state unit tests
│       │   └── presentation
│       │       └── onboarding_page_theme_test.dart     # Onboarding UI theme tests
│       ├── profile
│       │   └── application
│       │       └── user_income_controller_test.dart    # Income calculation and card balance unit tests
│       ├── savings
│       │   └── application
│       │       └── savings_provider_test.dart          # Savings calculation unit tests
│       ├── settings
│       │   ├── application
│       │   │   └── notification_reminder_controller_test.dart # Settings controller unit tests
│       │   └── presentation
│       │       └── settings_tab_test.dart              # Settings tab widget & theme tests
│       └── subscriptions
│           ├── application
│           │   ├── subscription_filter_controller_test.dart # Subscription filtering unit tests
│           │   └── subscription_form_validator_test.dart # Subscription form validation unit tests
│           ├── data
│           │   └── subscription_repository_test.dart   # Unit tests for InMemorySubscriptionRepository
│           └── presentation
│               └── subscription_theme_test.dart        # Subscription widget theme integration tests
├── analysis_options.yaml                               # Linter rules and static analysis configuration
├── .gitignore
├── .metadata
├── pubspec.lock                                        # Locked exact dependency versions
├── pubspec.yaml                                        # Flutter project dependencies and package configuration
├── README.md                                           # Project introduction, getting started, and setup guide
└── skills-lock.json                                    # Locked configuration for local agent skills

116 directories, 171 files
```

---

## 🧭 สรุปหน้าที่ของโฟลเดอร์หลัก (Key Directories Overview)

| โฟลเดอร์หลัก | ขอบเขตหน้าที่และความรับผิดชอบ (Responsibilities) |
|---|---|
| `.agents/` | รวบรวมคำสั่งการทำงานของระบบ Agent (Skills, Prompts, Cheat Sheets และ `tree_repo`) |
| `doc/` | เอกสารข้อกำหนดของระบบ (PRD, สถาปัตยกรรม Feature-First/Riverpod, แผนจัดสรรงาน) |
| `lib/app/` | จุดศูนย์กลางระดับแอปพลิเคชัน (Root MaterialApp, Startup Flow, GoRouter, Navigation Shell) |
| `lib/core/` | ส่วนประกอบและโมดูลส่วนกลางที่ใช้ร่วมกัน (ธีม, ไดอะล็อกยืนยัน/PIN, ตัวช่วย Logger, Breakpoints) |
| `lib/features/` | โมดูลแยกตามฟีเจอร์ธุรกิจ (Feature-First Architecture: auth, dashboard, profile, ฯลฯ) |
| `test/` | ชุดการทดสอบระบบแบบอัตโนมัติ (Unit Tests, Widget Tests, Theme Tests, Controller Tests) |
