# 📦 Repository Tree Overview

> **📅 วันที่อัปเดต:** 2026-09-26 01:00:19
> **👤 อัปเดตโดย:** Nekokun2004
> **💻 คำสั่งที่ใช้:** `tree -a -I ".git|android|ios|linux|macos|windows|web" --gitignore --dirsfirst`
> **⚠️ หมายเหตุ:** โครงสร้างไฟล์ในเอกสารนี้สร้างขึ้นโดยเคารพกฎการยกเว้นอย่างเคร่งครัด จะไม่อัปเดตไฟล์หรือโฟลเดอร์ที่ถูกระบุไว้ใน `.gitignore` และ `.dockerignore` (หากมี) โดยเด็ดขาด ไม่ว่ากรณีใดๆ ทั้งสิ้น เพื่อป้องกันไม่ให้ Temporary files, Build artifacts, Caches, Secrets หรือไฟล์ Generated ที่ไม่จำเป็นถูกนำเข้ามาบันทึกไว้ในผังโครงการ

---

## 🌳 โครงสร้างไดเรกทอรีพร้อมคำอธิบาย (Annotated Directory Tree)

```text
.
├── .agents
│   ├── skills                                          # Local Agent Skills Directory (clean-code, dart, flutter, tree-repo)
│   │   ├── clean-code                                  # Repository-wide clean code and architecture review skill
│   │   │   ├── agents
│   │   │   │   └── openai.yaml                         # Agent display name and default prompt metadata
│   │   │   ├── async_and_redis.md                      # BullMQ background workers and Redis caching rules
│   │   │   ├── backend_architecture.md                 # NestJS Modular Monolith, TypeORM and PostgreSQL rules
│   │   │   ├── frontend_architecture.md                # Flutter, Riverpod and Feature-First Clean Architecture rules
│   │   │   ├── infrastructure_architecture.md          # Docker, Compose, Nginx, CI/CD and observability rules
│   │   │   └── SKILL.md                                # Skill instructions and operational workflow
│   │   ├── dart-add-unit-test
│   │   │   └── SKILL.md                                # Skill instructions and operational workflow
│   │   ├── dart-build-cli-app
│   │   │   └── SKILL.md                                # Skill instructions and operational workflow
│   │   ├── dart-collect-coverage
│   │   │   └── SKILL.md                                # Skill instructions and operational workflow
│   │   ├── dart-fix-runtime-errors
│   │   │   └── SKILL.md                                # Skill instructions and operational workflow
│   │   ├── dart-generate-test-mocks
│   │   │   └── SKILL.md                                # Skill instructions and operational workflow
│   │   ├── dart-migrate-to-checks-package
│   │   │   └── SKILL.md                                # Skill instructions and operational workflow
│   │   ├── dart-resolve-package-conflicts
│   │   │   └── SKILL.md                                # Skill instructions and operational workflow
│   │   ├── dart-run-static-analysis
│   │   │   └── SKILL.md                                # Skill instructions and operational workflow
│   │   ├── dart-setup-ffi-assets
│   │   │   └── SKILL.md                                # Skill instructions and operational workflow
│   │   ├── dart-use-ffigen
│   │   │   └── SKILL.md                                # Skill instructions and operational workflow
│   │   ├── dart-use-pattern-matching
│   │   │   └── SKILL.md                                # Skill instructions and operational workflow
│   │   ├── dart-use-primary-constructors
│   │   │   └── SKILL.md                                # Skill instructions and operational workflow
│   │   ├── flutter-add-integration-test
│   │   │   └── SKILL.md                                # Skill instructions and operational workflow
│   │   ├── flutter-add-widget-preview
│   │   │   └── SKILL.md                                # Skill instructions and operational workflow
│   │   ├── flutter-add-widget-test
│   │   │   └── SKILL.md                                # Skill instructions and operational workflow
│   │   ├── flutter-apply-architecture-best-practices
│   │   │   └── SKILL.md                                # Skill instructions and operational workflow
│   │   ├── flutter-build-responsive-layout
│   │   │   └── SKILL.md                                # Skill instructions and operational workflow
│   │   ├── flutter-fix-layout-issues
│   │   │   └── SKILL.md                                # Skill instructions and operational workflow
│   │   ├── flutter-implement-json-serialization
│   │   │   └── SKILL.md                                # Skill instructions and operational workflow
│   │   ├── flutter-setup-declarative-routing
│   │   │   └── SKILL.md                                # Skill instructions and operational workflow
│   │   ├── flutter-setup-localization
│   │   │   └── SKILL.md                                # Skill instructions and operational workflow
│   │   ├── flutter-use-http-package
│   │   │   └── SKILL.md                                # Skill instructions and operational workflow
│   │   ├── pr-code-review_ne
│   │   └── tree-repo                                   # Skill for generating and maintaining repository tree overview
│   │       └── SKILL.md                                # Skill instructions and operational workflow
│   └── tree_repo
│       └── tree_repo.md                                # Repository tree overview guide with file annotations
├── apps                                                # Full-stack application packages directory
│   ├── mobile                                          # Mobile application (Flutter & Riverpod)
│   │   ├── lib                                         # Flutter application source code
│   │   │   ├── app
│   │   │   │   ├── application
│   │   │   │   │   ├── app_flow_provider.dart          # App startup flow state provider
│   │   │   │   │   ├── current_tab_controller.dart     # Navigation shell tab index controller
│   │   │   │   │   └── theme_mode_controller.dart      # Application ThemeMode controller & themeModeProvider
│   │   │   │   ├── presentation
│   │   │   │   │   ├── widgets
│   │   │   │   │   │   ├── main_app_header.dart        # Main header with dynamic greeting, avatar, income chip & noti button
│   │   │   │   │   │   └── main_app_navigation.dart    # Adaptive navigation bar / navigation rail widget
│   │   │   │   │   ├── main_navigation_shell.dart      # Main shell with 5 Tabs & Adaptive Navigation (BottomNav/Rail)
│   │   │   │   │   └── splash_screen.dart              # Branded Splash screen with startup session routing
│   │   │   │   ├── routing
│   │   │   │   │   ├── app_router.dart                 # GoRouter declarative configuration with deep-linked sub-routes
│   │   │   │   │   └── route_constants.dart            # String route path constants
│   │   │   │   └── app.dart                            # Root MaterialApp.router configured with Light & Dark Themes
│   │   │   ├── core
│   │   │   │   ├── errors
│   │   │   │   │   ├── failures.dart                   # Application failure & exception models
│   │   │   │   │   └── failures.freezed.dart           # Freezed generated model code
│   │   │   │   ├── layout
│   │   │   │   │   └── app_breakpoints.dart            # Responsive layout breakpoint constants
│   │   │   │   ├── security
│   │   │   │   │   └── pin_provider.dart               # 6-digit Security PIN state controller (securityPinProvider)
│   │   │   │   ├── theme
│   │   │   │   │   ├── app_colors.dart                 # Color palette system constants
│   │   │   │   │   ├── app_dark_theme.dart             # Dark ThemeData builder
│   │   │   │   │   ├── app_light_theme.dart            # Light ThemeData builder
│   │   │   │   │   ├── app_theme.dart                  # Public Theme facade (AppTheme.light & AppTheme.dark)
│   │   │   │   │   └── app_typography.dart             # Color-neutral Typography & TextStyles
│   │   │   │   ├── utils
│   │   │   │   │   └── logger.dart                     # Development logging utility
│   │   │   │   └── widgets
│   │   │   │       ├── change_pin_dialog.dart          # 3-step PIN change dialog modal
│   │   │   │       ├── confirmation_dialog.dart        # Theme-aware reusable confirmation dialog
│   │   │   │       ├── pin_verification_dialog.dart    # 6-digit PIN verification dialog modal with shake animation
│   │   │   │       └── service_icon.dart               # Brand service icon rendering widget
│   │   │   ├── features
│   │   │   │   ├── auth
│   │   │   │   │   ├── application
│   │   │   │   │   │   ├── auth_provider.dart          # Auth state notifier provider (Google/Apple/Guest)
│   │   │   │   │   │   └── auth_provider.g.dart        # JSON serializable / Riverpod generated code
│   │   │   │   │   ├── data
│   │   │   │   │   │   └── in_memory_auth_repository.dart  # InMemory authentication repository implementation
│   │   │   │   │   ├── domain
│   │   │   │   │   │   ├── auth_repository.dart        # Auth repository contract interface
│   │   │   │   │   │   ├── credit_card.dart            # Credit card domain entity
│   │   │   │   │   │   ├── credit_card.freezed.dart    # Freezed generated model code
│   │   │   │   │   │   ├── credit_card.g.dart          # JSON serializable / Riverpod generated code
│   │   │   │   │   │   ├── user.dart                   # User domain entity model
│   │   │   │   │   │   ├── user.freezed.dart           # Freezed generated model code
│   │   │   │   │   │   └── user.g.dart                 # JSON serializable / Riverpod generated code
│   │   │   │   │   └── presentation
│   │   │   │   │       └── login_screen.dart           # Login screen with Google, Apple & Guest sign-in
│   │   │   │   ├── dashboard
│   │   │   │   │   ├── application
│   │   │   │   │   │   └── dashboard_summary_provider.dart  # Dashboard summary & KPI calculator
│   │   │   │   │   └── presentation
│   │   │   │   │       ├── widgets
│   │   │   │   │       │   ├── dashboard_content.dart  # Main dashboard content layout
│   │   │   │   │       │   ├── dashboard_hero_card.dart  # Theme-aware Hero payout card with Creep Risk score
│   │   │   │   │       │   ├── dashboard_renewals_section.dart  # Section for upcoming billing renewals
│   │   │   │   │       │   └── dashboard_unused_alert.dart  # Alert card for unused subscriptions
│   │   │   │   │       └── dashboard_tab.dart          # Main Dashboard Tab view
│   │   │   │   ├── notifications
│   │   │   │   │   ├── application
│   │   │   │   │   │   └── notification_center_controller.dart  # Notification center state controller
│   │   │   │   │   ├── data
│   │   │   │   │   │   └── mock_notification_data.dart # In-memory Notification Center fixture data
│   │   │   │   │   ├── domain
│   │   │   │   │   │   ├── app_notification.dart       # Frontend notification read model
│   │   │   │   │   │   ├── app_notification.freezed.dart  # Freezed generated model code
│   │   │   │   │   │   └── app_notification.g.dart     # JSON serializable / Riverpod generated code
│   │   │   │   │   └── presentation
│   │   │   │   │       ├── widgets
│   │   │   │   │       │   ├── notification_filter_bar.dart  # Notification category/unread filter controls
│   │   │   │   │       │   └── notification_list.dart  # Notification Center list and empty-state renderer
│   │   │   │   │       ├── notification_center_screen.dart  # Notification Center screen and tabs
│   │   │   │   │       └── notification_ui_extensions.dart  # UI helper extensions for notification display
│   │   │   │   ├── onboarding
│   │   │   │   │   ├── application
│   │   │   │   │   │   └── onboarding_controller.dart  # Onboarding progression & completion controller
│   │   │   │   │   └── presentation
│   │   │   │   │       ├── visuals
│   │   │   │   │       │   ├── renewal_alert_visual.dart  # Onboarding illustration for upcoming renewals
│   │   │   │   │       │   ├── subscription_stack_visual.dart  # Onboarding subscription overview illustration
│   │   │   │   │       │   └── unused_alert_visual.dart  # Onboarding unused-subscription illustration
│   │   │   │   │       ├── onboarding_controls.dart    # Next/skip/get-started onboarding controls
│   │   │   │   │       ├── onboarding_data.dart        # Onboarding page content definitions
│   │   │   │   │       ├── onboarding_page.dart        # Reusable onboarding page layout
│   │   │   │   │       ├── onboarding_progress_bar.dart  # Current onboarding-page progress indicator
│   │   │   │   │       └── onboarding_screen.dart      # Onboarding PageView flow screen
│   │   │   │   ├── profile
│   │   │   │   │   ├── application
│   │   │   │   │   │   ├── payment_card_linking_controller.dart  # Bank card linking controller with duplicate billing detector
│   │   │   │   │   │   ├── personal_info_controller.dart  # User personal details and profile form controller
│   │   │   │   │   │   └── user_income_controller.dart # User income calculation controller derived from card balances
│   │   │   │   │   ├── data
│   │   │   │   │   │   └── in_memory_payment_card_repository.dart  # Mock linked-card and recurring-charge repository
│   │   │   │   │   ├── domain
│   │   │   │   │   │   ├── payment_card.dart           # Frontend mock payment-card and detected-charge models
│   │   │   │   │   │   └── payment_card_repository.dart  # Payment-card simulation repository contract
│   │   │   │   │   └── presentation
│   │   │   │   │       ├── widgets
│   │   │   │   │       │   ├── linked_accounts_card.dart  # Profile summary of simulated linked payment cards
│   │   │   │   │       │   ├── personal_info_sheet.dart  # Editable personal-profile bottom sheet
│   │   │   │   │       │   ├── profile_identity_card.dart  # User avatar, identity and account summary card
│   │   │   │   │       │   └── profile_settings_card.dart  # Profile shortcuts for income, PIN and personal data
│   │   │   │   │       ├── add_payment_card_sheet.dart # Mock card-linking and recurring-charge import sheet
│   │   │   │   │       ├── income_editor_sheet.dart    # Monthly reference income editor sheet
│   │   │   │   │       ├── payment_card_ui_extensions.dart  # Presentation formatting for mock payment cards
│   │   │   │   │       └── profile_tab.dart            # User profile, income and settings hub tab
│   │   │   │   ├── savings
│   │   │   │   │   ├── application
│   │   │   │   │   │   └── savings_provider.dart       # Savings simulator provider calculating retained capital
│   │   │   │   │   └── presentation
│   │   │   │   │       ├── widgets
│   │   │   │   │       │   ├── savings_checklist.dart  # Selectable subscription list for savings simulation
│   │   │   │   │       │   └── savings_summary.dart    # Derived monthly/yearly savings result card
│   │   │   │   │       └── savings_tab.dart            # Interactive savings simulator tab with toggleable subscriptions
│   │   │   │   ├── settings
│   │   │   │   │   ├── application
│   │   │   │   │   │   └── notification_reminder_controller.dart  # Notification reminder lead-time preferences controller
│   │   │   │   │   └── presentation
│   │   │   │   │       └── settings_tab.dart           # Application settings tab with PIN change, reminders & theme toggle
│   │   │   │   └── subscriptions
│   │   │   │       ├── application
│   │   │   │       │   ├── subscription_filter_controller.dart  # Subscription search filter & sorting controller
│   │   │   │       │   ├── subscription_form_validator.dart  # Validation rules for new subscription entry form
│   │   │   │       │   ├── subscription_list_controller.dart  # Subscription list controller with optimistic CRUD operations
│   │   │   │       │   └── subscription_read_model.dart  # Optimized read model for multi-currency subscription views
│   │   │   │       ├── data
│   │   │   │       │   └── in_memory_subscription_repository.dart  # InMemory subscription persistence repository
│   │   │   │       ├── domain
│   │   │   │       │   ├── preset_package_catalog.dart # Preset catalog of popular Thai & international subscriptions
│   │   │   │       │   ├── preset_package.dart         # Frontend preset-package selection model
│   │   │   │       │   ├── subscription.dart           # Subscription domain entity with Creep Risk scoring
│   │   │   │       │   ├── subscription.freezed.dart   # Freezed generated model code
│   │   │   │       │   ├── subscription.g.dart         # JSON serializable / Riverpod generated code
│   │   │   │       │   └── subscription_repository.dart  # Subscription repository contract interface
│   │   │   │       └── presentation
│   │   │   │           ├── widgets
│   │   │   │           │   ├── preset_package_grid.dart  # Searchable preset-package result grid
│   │   │   │           │   ├── preset_picker_card.dart # Entry card opening the preset-package picker
│   │   │   │           │   ├── preset_search_field.dart  # Preset package search input
│   │   │   │           │   ├── subscription_appearance_selector.dart  # Color and brand icon selector for subscription
│   │   │   │           │   ├── subscription_collection.dart  # Subscription list/grid responsive collection
│   │   │   │           │   ├── subscription_detail_header.dart  # Service identity header for detail sheet
│   │   │   │           │   ├── subscription_detail_overview.dart  # Price, billing and usage detail summary
│   │   │   │           │   ├── subscription_detail_sheet.dart  # Edit, reminder and cancellation bottom sheet
│   │   │   │           │   ├── subscription_empty_state.dart  # Empty/search-no-result subscription state
│   │   │   │           │   ├── subscription_filter_bar.dart  # Search and status filters for subscriptions
│   │   │   │           │   ├── subscription_general_fields.dart  # Name, price and billing-cycle form fields
│   │   │   │           │   ├── subscription_list_tile.dart  # Subscription summary list item
│   │   │   │           │   ├── subscription_reminder_editor.dart  # Per-subscription reminder override controls
│   │   │   │           │   └── usage_status_selector.dart  # Frequent/moderate/unused selector
│   │   │   │           ├── add_subscription_screen.dart  # Add custom subscription form screen
│   │   │   │           ├── select_package_screen.dart  # Select popular subscription package screen
│   │   │   │           ├── subscriptions_tab.dart      # Main subscriptions management tab with list & search
│   │   │   │           └── subscription_ui_extensions.dart  # Subscription display labels, colors and formatting
│   │   │   └── main.dart                               # App entrypoint running ProviderScope + App
│   │   ├── test                                        # Automated tests directory
│   │   │   ├── app
│   │   │   │   ├── application
│   │   │   │   │   ├── current_tab_controller_test.dart  # Unit tests for CurrentTabController
│   │   │   │   │   └── theme_mode_controller_test.dart # Unit tests for ThemeModeController
│   │   │   │   ├── presentation
│   │   │   │   │   ├── main_navigation_shell_test.dart # Responsive Widget tests for MainNavigationShell
│   │   │   │   │   └── splash_screen_theme_test.dart   # Splash screen theme tests
│   │   │   │   └── routing
│   │   │   │       └── app_router_test.dart            # Declarative router navigation tests
│   │   │   ├── core
│   │   │   │   └── widgets
│   │   │   │       └── confirmation_dialog_test.dart   # Widget tests for ConfirmationDialog
│   │   │   └── features
│   │   │       ├── auth
│   │   │       │   └── application
│   │   │       │       └── auth_provider_test.dart     # Auth state notifier unit tests
│   │   │       ├── dashboard
│   │   │       │   └── application
│   │   │       │       └── dashboard_summary_provider_test.dart  # Dashboard KPI calculations unit tests
│   │   │       ├── notifications
│   │   │       │   ├── application
│   │   │       │   │   └── notification_center_controller_test.dart  # Notification controller unit tests
│   │   │       │   └── presentation
│   │   │       │       ├── notification_theme_test.dart  # Notification UI theme tests
│   │   │       │       └── notification_ui_extensions_test.dart  # Notification formatting unit tests
│   │   │       ├── onboarding
│   │   │       │   ├── application
│   │   │       │   │   └── onboarding_controller_test.dart  # Onboarding state unit tests
│   │   │       │   └── presentation
│   │   │       │       └── onboarding_page_theme_test.dart  # Onboarding UI theme tests
│   │   │       ├── profile
│   │   │       │   └── application
│   │   │       │       └── user_income_controller_test.dart  # Income calculation and card balance unit tests
│   │   │       ├── savings
│   │   │       │   └── application
│   │   │       │       └── savings_provider_test.dart  # Savings calculation unit tests
│   │   │       ├── settings
│   │   │       │   ├── application
│   │   │       │   │   └── notification_reminder_controller_test.dart  # Settings controller unit tests
│   │   │       │   └── presentation
│   │   │       │       └── settings_tab_test.dart      # Settings tab widget & theme tests
│   │   │       └── subscriptions
│   │   │           ├── application
│   │   │           │   ├── subscription_filter_controller_test.dart  # Subscription filtering unit tests
│   │   │           │   └── subscription_form_validator_test.dart  # Subscription form validation unit tests
│   │   │           ├── data
│   │   │           │   └── subscription_repository_test.dart  # Unit tests for InMemorySubscriptionRepository
│   │   │           └── presentation
│   │   │               └── subscription_theme_test.dart  # Subscription widget theme integration tests
│   │   ├── analysis_options.yaml                       # Linter rules and static analysis configuration
│   │   ├── .fvmrc                                      # Flutter SDK version selection for FVM
│   │   ├── .gitignore                                  # Monorepo git ignore rules
│   │   ├── .metadata                                   # Flutter project metadata
│   │   ├── pubspec.lock                                # Locked Flutter/Dart dependency graph
│   │   └── pubspec.yaml                                # Flutter package metadata, dependencies and assets
│   └── server                                          # NestJS backend application boundary (Modular Monolith, Prisma ORM)
│       ├── apps
│       │   └── server
│       │       └── prisma
│       │           └── migrations
│       │               └── 20260921000000_baseline
│       ├── prisma                                      # Prisma schema, migrations and development seed data
│       │   ├── migrations                              # Prisma database migrations history
│       │   │   ├── 20260921000000_baseline             # Baseline database schema migration
│       │   │   │   └── migration.sql                   # Baseline PostgreSQL tables, indexes and constraints
│       │   │   ├── 20260922000000_add_device_registrations  # Device registration migration for push tokens (BE-401)
│       │   │   │   └── migration.sql                   # Creates device_registrations table with unique user-token index
│       │   │   └── migration_lock.toml                 # Prisma migration engine provider lock
│       │   ├── schema.prisma                           # PostgreSQL data model used by PrismaClient
│       │   ├── seed.d.ts                               # TypeScript declaration file for database seed script
│       │   ├── seed.js                                 # Compiled JavaScript seed execution script
│       │   ├── seed.js.map                             # Source map for compiled database seed script
│       │   └── seed.ts                                 # Development database seed entry point
│       ├── src                                         # NestJS source, modules, guards and configuration
│       │   ├── auth                                    # JWT authentication controller, service and strategy
│       │   │   ├── dto
│       │   │   │   ├── login.dto.ts                    # DTO ตรวจสอบข้อมูลเข้าสู่ระบบด้วย Email และ Password
│       │   │   │   └── register.dto.ts                 # DTO ตรวจสอบข้อมูลลงทะเบียนผู้ใช้ใหม่
│       │   │   ├── strategies
│       │   │   │   ├── jwt.strategy.spec.ts            # Unit coverage for JWT user resolution and projection
│       │   │   │   └── jwt.strategy.ts                 # Passport JWT strategy with User.id lookup
│       │   │   ├── auth.controller.ts                  # Public registration and login endpoints
│       │   │   ├── auth.module.ts                      # JWT and Passport module wiring
│       │   │   └── auth.service.ts                     # Credential verification and JWT issuance
│       │   ├── common                                  # Cross-cutting authentication and HTTP response concerns
│       │   │   ├── decorators
│       │   │   │   ├── current-user.decorator.ts       # Extracts verified request.user in controllers
│       │   │   │   └── public.decorator.ts             # Opts endpoints out of the global JWT guard
│       │   │   ├── filters
│       │   │   │   └── http-exception.filter.ts        # Safe public HTTP error envelope for expected and internal errors
│       │   │   ├── guards
│       │   │   │   ├── jwt-auth.guard.spec.ts          # Unit coverage for public-route and default-deny behavior
│       │   │   │   └── jwt-auth.guard.ts               # Global Passport JWT guard
│       │   │   └── interceptors
│       │   │       └── transform.interceptor.ts        # Success response envelope
│       │   ├── config                                  # Typed, validated application and database environment settings
│       │   │   ├── app.config.ts                       # Typed app runtime namespace (environment, host and port)
│       │   │   ├── database.config.ts                  # Typed PostgreSQL connection contract without a database client
│       │   │   ├── env.validation.spec.ts              # Unit tests for fail-fast environment parsing rules
│       │   │   └── env.validation.ts                   # Zod environment schema with exact JWT secret validation
│       │   ├── creep-score                             # Subscription spending risk calculations (Creep Score)
│       │   │   ├── creep-score.controller.ts           # Endpoint คำนวณความเสี่ยงค่าใช้จ่าย Subscription (Creep Risk)
│       │   │   ├── creep-score.module.ts               # โมดูลวิเคราะห์และประเมิน Creep Score ของผู้ใช้
│       │   │   ├── creep-score.service.spec.ts         # Unit tests การคำนวณ Creep Score และระดับความเสี่ยง
│       │   │   └── creep-score.service.ts              # Service คำนวณ Creep Score จากจำนวน, ค่าใช้จ่าย และการใช้งาน
│       │   ├── device-registrations                    # Device registration and push token management boundary (BE-401)
│       │   │   ├── dto
│       │   │   │   └── register-device.dto.ts          # DTO ลงทะเบียน FCM/APNS Device Token ของอุปกรณ์
│       │   │   ├── device-registrations.controller.ts  # Endpoint จัดการลงทะเบียน Device Push Token (BE-401)
│       │   │   ├── device-registrations.module.ts      # โมดูลเชื่อมต่อระบบจัดการอุปกรณ์และ Push Notification Token
│       │   │   ├── device-registrations.service.spec.ts  # Unit tests สำหรับ Device Registration และ Upsert logic
│       │   │   └── device-registrations.service.ts     # Service จัดการบันทึกและอัปเดต Device Token ของผู้ใช้
│       │   ├── notifications                           # User notification and alert operations
│       │   │   ├── notifications.controller.ts         # Endpoint ดึงรายการแจ้งเตือนและอัปเดตสถานะ Read ใน Notification Center
│       │   │   ├── notifications.module.ts             # โมดูลจัดการประวัติการแจ้งเตือนของผู้ใช้
│       │   │   └── notifications.service.ts            # Service ค้นหาและอัปเดตการแจ้งเตือนในฐานข้อมูล
│       │   ├── packages                                # Predefined subscription packages and catalog operations
│       │   │   ├── dto
│       │   │   │   ├── create-package.dto.ts           # DTO สำหรับสร้างแพ็กเกจบริการยอดนิยมในระบบ
│       │   │   │   ├── query-package.dto.ts            # DTO ค้นหาและกรองรายการแพ็กเกจตามหมวดหมู่
│       │   │   │   └── update-package.dto.ts           # DTO อัปเดตข้อมูลแพ็กเกจและราคา
│       │   │   ├── packages.controller.ts              # Endpoint ให้บริการข้อมูลแพ็กเกจยอดนิยม (Catalog)
│       │   │   ├── packages.module.ts                  # โมดูลจัดการแค็ตตาล็อกบริการและแพ็กเกจสำเร็จรูป
│       │   │   ├── packages.service.spec.ts            # Unit tests การค้นหาและกรองข้อมูลแพ็กเกจบริการ
│       │   │   └── packages.service.ts                 # Service ดึงข้อมูลแค็ตตาล็อกแพ็กเกจบริการยอดนิยม
│       │   ├── payment-cards                           # Payment card ownership and linking operations
│       │   │   ├── dto
│       │   │   │   ├── create-card.dto.ts              # DTO สำหรับเพิ่มบัตรชำระเงินใหม่
│       │   │   │   ├── link-mock-card.dto.ts           # DTO ผูกบัตรจำลองพร้อมตรวจจับรายการเรียกเก็บซ้ำ
│       │   │   │   └── update-card.dto.ts              # DTO แก้ไขข้อมูลบัตรและวงเงิน
│       │   │   ├── payment-cards.controller.ts         # Endpoint จัดการผูกบัตรและจำลองการตรวจจับยอดเรียกเก็บ
│       │   │   ├── payment-cards.module.ts             # โมดูลจัดการบัตรชำระเงินและรายการตัดบัตรจำลอง
│       │   │   ├── payment-cards.service.spec.ts       # Unit tests ตรวจจับ Recurring Subscriptions จากบัตร
│       │   │   └── payment-cards.service.ts            # Service จัดการผูกบัตรและตรวจจับการเรียกเก็บค่าบริการ
│       │   ├── prisma                                  # Nest PrismaClient lifecycle provider
│       │   │   ├── prisma.module.ts                    # Global PrismaClient provider module
│       │   │   └── prisma.service.ts                   # PrismaClient lifecycle management and connection hooks
│       │   ├── savings                                 # Subscription cancellation and savings calculations
│       │   │   ├── dto
│       │   │   │   └── batch-cancel.dto.ts             # DTO ส่งรายการ Subscription เพื่อจำลองเงินที่จะประหยัดได้
│       │   │   ├── savings.controller.ts               # Endpoint คำนวณเงินออมสะสมจากการยกเลิก Subscription
│       │   │   ├── savings.module.ts                   # โมดูลจำลองและคำนวณการประหยัดค่าใช้จ่าย
│       │   │   ├── savings.service.spec.ts             # Unit tests การคำนวณเงินที่ประหยัดได้รายเดือน/รายปี
│       │   │   └── savings.service.ts                  # Service คำนวณเงินคงเหลือที่ประหยัดได้จากการยกเลิกบริการ
│       │   ├── subscriptions                           # User subscription CRUD and lifecycle operations
│       │   │   ├── dto
│       │   │   │   ├── create-subscription.dto.ts      # DTO สร้างรายการติดตาม Subscription พร้อมรอบบิลและการเตือน
│       │   │   │   ├── query-subscription.dto.ts       # DTO กรองและค้นหารายการ Subscription ของผู้ใช้
│       │   │   │   └── update-subscription.dto.ts      # DTO อัปเดตข้อมูล Subscription วันต่ออายุ และสถานะการใช้งาน
│       │   │   ├── subscriptions.controller.ts         # Endpoint จัดการ CRUD รายการ Subscription ของผู้ใช้
│       │   │   ├── subscriptions.module.ts             # โมดูลจัดการวงจรชีวิต Subscription และการต่ออายุ
│       │   │   ├── subscriptions.service.spec.ts       # Unit tests สำหรับ Subscription CRUD และการคำนวณวันต่ออายุ
│       │   │   └── subscriptions.service.ts            # Service จัดการฐานข้อมูลและ Business Logic ของ Subscription
│       │   ├── swagger                                 # Swagger UI and OpenAPI documentation configuration
│       │   │   ├── swagger.config.spec.ts              # Unit tests for Swagger document generation and environment gating
│       │   │   └── swagger.config.ts                   # Swagger/OpenAPI setup and Bearer auth configuration
│       │   ├── users                                   # Authenticated user profile and PIN operations
│       │   │   ├── dto
│       │   │   │   ├── change-pin.dto.ts               # DTO เปลี่ยนรหัส PIN 6 หลักพร้อมตรวจ PIN เดิม
│       │   │   │   ├── update-income.dto.ts            # DTO อัปเดตรายได้อ้างอิงรายเดือนของผู้ใช้
│       │   │   │   ├── update-profile.dto.ts           # DTO แก้ไขข้อมูลโปรไฟล์และชื่อผู้ใช้
│       │   │   │   └── verify-pin.dto.ts               # DTO ตรวจสอบความถูกต้องของรหัส PIN 6 หลัก
│       │   │   ├── users.controller.ts                 # Endpoint จัดการข้อมูลโปรไฟล์, รายได้ และ PIN ผู้ใช้
│       │   │   ├── users.module.ts                     # โมดูลจัดการข้อมูลผู้ใช้และระบบรักษาความปลอดภัย PIN
│       │   │   ├── users.service.spec.ts               # Unit tests การแฮช PIN, ยืนยันรหัส และอัปเดตโปรไฟล์
│       │   │   └── users.service.ts                    # Service จัดการ User CRUD, ตรวจสอบ PIN และอัปเดตรายได้
│       │   ├── app.controller.spec.ts                  # Unit tests for AppController
│       │   ├── app.controller.ts                       # Standard NestJS root controller
│       │   ├── app.module.spec.ts                      # Root module compilation test with explicit test environment
│       │   ├── app.module.ts                           # Global ConfigModule composition root
│       │   ├── app.service.ts                          # Standard NestJS root service
│       │   ├── main.ts                                 # HTTP runtime bootstrap using typed app configuration and Swagger setup
│       │   └── worker.ts                               # Future separate Worker runtime boundary
│       ├── test                                        # Application-level HTTP tests and database integration tests
│       │   ├── auth.e2e.spec.ts                        # Login-to-profile HTTP flow; not database-backed E2E
│       │   ├── auth.integration.spec.ts                # JWT guard/Passport/HTTP component integration and safe-error regression
│       │   ├── device-registrations.integration.spec.ts  # Integration tests for device registration endpoint with mock auth
│       │   ├── device-registrations.postgres.integration.spec.ts  # Database integration tests for device registration on real PostgreSQL
│       │   └── subscriptions.integration.spec.ts       # Integration tests for subscription endpoints, validation, and user scoping
│       ├── docker-compose.yml                          # Server-level Compose for backend and PostgreSQL container execution
│       ├── Dockerfile                                  # Multi-stage Node 24 image for development, quality gates and non-root runtime
│       ├── .dockerignore                               # Restricts server image context from secrets, dependencies and generated artifacts
│       ├── .env.example                                # Safe environment-variable template including JWT contract
│       ├── eslint.config.mjs                           # ESLint flat configuration for TypeScript source
│       ├── nest-cli.json                               # NestJS CLI build configuration
│       ├── .nvmrc                                      # Pinned Node.js development runtime
│       ├── package.json                                # Server dependencies, scripts, Node and pnpm requirements
│       ├── package-lock.json                           # Locked NPM dependency graph for server package
│       ├── pnpm-lock.yaml                              # Reproducible pnpm dependency graph
│       ├── pnpm-workspace.yaml                         # Local pnpm allow-list for reviewed native build scripts
│       ├── .prettierrc                                 # Server TypeScript formatting policy
│       ├── README.md                                   # NestJS server documentation
│       ├── tsconfig.build.json                         # NestJS production TypeScript build configuration
│       └── tsconfig.json                               # Strict TypeScript compiler policy for source and decorator-bearing tests
├── doc                                                 # Cross-project documentation directory
│   ├── architecture
│   │   ├── feature_first_architecture.md               # Feature-First Clean Architecture Specification
│   │   ├── riverpod_architecture_guide.md              # Comprehensive Riverpod Architecture & State Management Guide
│   │   └── riverpod_providers_reference.md             # Riverpod Providers Quick Reference & Cheat Sheet
│   ├── backend
│   │   ├── api                                         # Canonical public REST API standards and contract conventions
│   │   │   ├── api_contract_v1.md                      # Human-readable API v1 endpoint, DTO, ownership and error contract
│   │   │   ├── api_standards.md                        # API Standards v1: HTTP, JSON, errors, auth, pagination and serialization
│   │   │   └── openapi_v1.yaml                         # Machine-readable OpenAPI 3.0 contract matching API Contract v1
│   │   ├── database                                    # Canonical PostgreSQL relational database design documents
│   │   │   └── erd_v1.md                               # Physical ERD v1: tables, columns, constraints, indexes and persistence assumptions
│   │   ├── backend_architecture_v1.md                  # Canonical Backend Architecture v1: modules, runtimes, data and async boundaries
│   │   ├── domain_model_v1.md                          # Domain Model v1: entities, value objects, lifecycles, invariants and ERD decisions
│   │   └── .gitkeep                                    # Keep directory tracked in git
│   ├── devops
│   │   └── .gitkeep                                    # Keep directory tracked in git
│   ├── frontend
│   │   └── subscription_track_frontend_screens.md      # UI Screen Specifications, Theme Policy & Component Matrix
│   ├── task
│   │   └── team_task_allocation.md                     # Developer Task Allocation, Work Breakdown & Schedule
│   └── Subscription_Track_PRD.md                       # Product Requirement Document (PRD)
├── .github
│   └── workflows                                       # GitHub Actions CI/CD workflows boundary
│       └── .gitkeep                                    # Keep directory tracked in git
├── infra                                               # Infrastructure configuration boundary
│   ├── monitoring                                      # Monitoring infrastructure boundary
│   │   └── .gitkeep                                    # Keep directory tracked in git
│   ├── nginx                                           # Nginx reverse proxy infrastructure boundary
│   │   └── .gitkeep                                    # Keep directory tracked in git
│   ├── postgres                                        # PostgreSQL database infrastructure boundary
│   │   └── .gitkeep                                    # Keep directory tracked in git
│   └── redis                                           # Redis infrastructure boundary
│       └── .gitkeep                                    # Keep directory tracked in git
├── scripts                                             # Repository automation scripts boundary
│   ├── .gitkeep                                        # Keep directory tracked in git
│   └── run_checks_terminals.sh                         # Shell script to run linter, test and static checks across monorepo
├── docker-compose.yml                                  # Development API and PostgreSQL 16 orchestration
├── .env.example                                        # Root environment variables template for local and container setup
├── .gitignore                                          # Monorepo git ignore rules
├── README.md                                           # Full-stack monorepo project overview & getting started
└── skills-lock.json                                    # Locked configuration for local agent skills

166 directories, 294 files
```

---

## 🧭 สรุปหน้าที่ของโฟลเดอร์หลัก (Key Directories Overview)

| โฟลเดอร์หลัก | ขอบเขตหน้าที่และความรับผิดชอบ (Responsibilities) |
|---|---|
| `.agents/` | รวบรวมคำสั่งการทำงานของระบบ Agent (Skills, Prompts, Cheat Sheets และ `tree_repo`) |
| `.github/` | ขอบเขตเวิร์กโฟลว์ CI/CD บน GitHub Actions (ปัจจุบันเป็นโฟลเดอร์ boundary) |
| `apps/mobile/` | แอปพลิเคชันมือถือ Flutter (Riverpod, Feature-First Architecture, iOS/Android) พร้อมระบบจัดการ Subscription, วิเคราะห์ Creep Risk, จำลองเงินออม และ Notification Center |
| `apps/server/` | NestJS Modular Monolith บน Node.js พร้อม Prisma ORM (PostgreSQL), JWT Authentication, Device Push Token Registration (BE-401), Subscriptions CRUD, Payment Cards, Savings, Creep Score, Swagger OpenAPI docs, และ Docker runtime |
| `doc/` | เอกสารข้อกำหนดและแบบระบบ (PRD, Backend Architecture, Domain Model, PostgreSQL ERD, API Standards/Contract/OpenAPI, สถาปัตยกรรม Frontend และแผนงาน) |
| `infra/` | ขอบเขตการตั้งค่า Infrastructure ระยะถัดไป (Nginx, Monitoring, PostgreSQL, Redis) |
| `scripts/` | สคริปต์อัตโนมัติระดับ Repository รวมถึงสคริปต์รันระบบทดสอบและตรวจสอบคุณภาพโค้ด (`run_checks_terminals.sh`) |
