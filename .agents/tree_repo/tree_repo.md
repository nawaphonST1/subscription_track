# 📦 Repository Tree Overview

> **📅 วันที่อัปเดต:** 2026-09-16 12:02:41
> **👤 อัปเดตโดย:** Nekokun2004
> **💻 คำสั่งที่ใช้:** `tree -a -I ".git|android|ios|linux|macos|windows|web|node_modules|dist|coverage|.env|.env.*|*.log|.pnpm-store|.DS_Store|.idea|.vscode" --gitignore --dirsfirst`
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
│   │   └── tree-repo                                   # Skill for generating and maintaining repository tree overview
│   │       └── SKILL.md                                # Skill instructions and operational workflow
│   └── tree_repo
│       └── tree_repo.md                                # Repository tree overview guide with file annotations
├── .codex                                              # Codex repository-local configuration boundary
├── .github
│   └── workflows                                       # GitHub Actions CI/CD workflows boundary
│       └── .gitkeep                                    # Keep directory tracked in git
├── apps                                                # Full-stack application packages directory
│   ├── mobile                                          # Mobile application (Flutter & Riverpod)
│       ├── lib                                         # Flutter application source code
│       │   ├── app
│       │   │   ├── application
│       │   │   │   ├── app_flow_provider.dart          # App startup flow state provider
│       │   │   │   ├── current_tab_controller.dart     # Navigation shell tab index controller
│       │   │   │   └── theme_mode_controller.dart      # Application ThemeMode controller & themeModeProvider
│       │   │   ├── presentation
│       │   │   │   ├── widgets
│       │   │   │   │   ├── main_app_header.dart        # Main header with dynamic greeting, avatar, income chip & noti button
│       │   │   │   │   └── main_app_navigation.dart    # Adaptive navigation bar / navigation rail widget
│       │   │   │   ├── main_navigation_shell.dart      # Main shell with 5 Tabs & Adaptive Navigation (BottomNav/Rail)
│       │   │   │   └── splash_screen.dart              # Branded Splash screen with startup session routing
│       │   │   ├── routing
│       │   │   │   ├── app_router.dart                 # GoRouter declarative configuration with deep-linked sub-routes
│       │   │   │   └── route_constants.dart            # String route path constants
│       │   │   └── app.dart                            # Root MaterialApp.router configured with Light & Dark Themes
│       │   ├── core
│       │   │   ├── errors
│       │   │   │   ├── failures.dart                   # Application failure & exception models
│       │   │   │   └── failures.freezed.dart           # Freezed generated model code
│       │   │   ├── layout
│       │   │   │   └── app_breakpoints.dart            # Responsive layout breakpoint constants
│       │   │   ├── security
│       │   │   │   └── pin_provider.dart               # 6-digit Security PIN state controller (securityPinProvider)
│       │   │   ├── theme
│       │   │   │   ├── app_colors.dart                 # Color palette system constants
│       │   │   │   ├── app_dark_theme.dart             # Dark ThemeData builder
│       │   │   │   ├── app_light_theme.dart            # Light ThemeData builder
│       │   │   │   ├── app_theme.dart                  # Public Theme facade (AppTheme.light & AppTheme.dark)
│       │   │   │   └── app_typography.dart             # Color-neutral Typography & TextStyles
│       │   │   ├── utils
│       │   │   │   └── logger.dart                     # Development logging utility
│       │   │   └── widgets
│       │   │       ├── change_pin_dialog.dart          # 3-step PIN change dialog modal
│       │   │       ├── confirmation_dialog.dart        # Theme-aware reusable confirmation dialog
│       │   │       ├── pin_verification_dialog.dart    # 6-digit PIN verification dialog modal with shake animation
│       │   │       └── service_icon.dart               # Brand service icon rendering widget
│       │   ├── features
│       │   │   ├── auth
│       │   │   │   ├── application
│       │   │   │   │   ├── auth_provider.dart          # Auth state notifier provider (Google/Apple/Guest)
│       │   │   │   │   └── auth_provider.g.dart        # JSON serializable / Riverpod generated code
│       │   │   │   ├── data
│       │   │   │   │   └── in_memory_auth_repository.dart # InMemory authentication repository implementation
│       │   │   │   ├── domain
│       │   │   │   │   ├── auth_repository.dart        # Auth repository contract interface
│       │   │   │   │   ├── credit_card.dart            # Credit card domain entity
│       │   │   │   │   ├── credit_card.freezed.dart    # Freezed generated model code
│       │   │   │   │   ├── credit_card.g.dart          # JSON serializable / Riverpod generated code
│       │   │   │   │   ├── user.dart                   # User domain entity model
│       │   │   │   │   ├── user.freezed.dart           # Freezed generated model code
│       │   │   │   │   └── user.g.dart                 # JSON serializable / Riverpod generated code
│       │   │   │   └── presentation
│       │   │   │       └── login_screen.dart           # Login screen with Google, Apple & Guest sign-in
│       │   │   ├── dashboard
│       │   │   │   ├── application
│       │   │   │   │   └── dashboard_summary_provider.dart # Dashboard summary & KPI calculator
│       │   │   │   └── presentation
│       │   │   │       ├── widgets
│       │   │   │       │   ├── dashboard_content.dart  # Main dashboard content layout
│       │   │   │       │   ├── dashboard_hero_card.dart # Theme-aware Hero payout card with Creep Risk score
│       │   │   │       │   ├── dashboard_renewals_section.dart # Section for upcoming billing renewals
│       │   │   │       │   └── dashboard_unused_alert.dart # Alert card for unused subscriptions
│       │   │   │       └── dashboard_tab.dart          # Main Dashboard Tab view
│       │   │   ├── notifications
│       │   │   │   ├── application
│       │   │   │   │   └── notification_center_controller.dart # Notification center state controller
│       │   │   │   ├── data
│       │   │   │   │   └── mock_notification_data.dart # In-memory Notification Center fixture data
│       │   │   │   ├── domain
│       │   │   │   │   ├── app_notification.dart      # Frontend notification read model
│       │   │   │   │   ├── app_notification.freezed.dart # Freezed generated model code
│       │   │   │   │   └── app_notification.g.dart     # JSON serializable / Riverpod generated code
│       │   │   │   └── presentation
│       │   │   │       ├── widgets
│       │   │   │       │   ├── notification_filter_bar.dart # Notification category/unread filter controls
│       │   │   │       │   └── notification_list.dart # Notification Center list and empty-state renderer
│       │   │   │       ├── notification_center_screen.dart # Notification Center screen and tabs
│       │   │   │       └── notification_ui_extensions.dart # UI helper extensions for notification display
│       │   │   ├── onboarding
│       │   │   │   ├── application
│       │   │   │   │   └── onboarding_controller.dart  # Onboarding progression & completion controller
│       │   │   │   └── presentation
│       │   │   │       ├── visuals
│       │   │   │       │   ├── renewal_alert_visual.dart # Onboarding illustration for upcoming renewals
│       │   │   │       │   ├── subscription_stack_visual.dart # Onboarding subscription overview illustration
│       │   │   │       │   └── unused_alert_visual.dart # Onboarding unused-subscription illustration
│       │   │   │       ├── onboarding_controls.dart   # Next/skip/get-started onboarding controls
│       │   │   │       ├── onboarding_data.dart       # Onboarding page content definitions
│       │   │   │       ├── onboarding_page.dart       # Reusable onboarding page layout
│       │   │   │       ├── onboarding_progress_bar.dart # Current onboarding-page progress indicator
│       │   │   │       └── onboarding_screen.dart     # Onboarding PageView flow screen
│       │   │   ├── profile
│       │   │   │   ├── application
│       │   │   │   │   ├── payment_card_linking_controller.dart # Bank card linking controller with duplicate billing detector
│       │   │   │   │   ├── personal_info_controller.dart # User personal details and profile form controller
│       │   │   │   │   └── user_income_controller.dart # User income calculation controller derived from card balances
│       │   │   │   ├── data
│       │   │   │   │   └── in_memory_payment_card_repository.dart # Mock linked-card and recurring-charge repository
│       │   │   │   ├── domain
│       │   │   │   │   ├── payment_card.dart          # Frontend mock payment-card and detected-charge models
│       │   │   │   │   └── payment_card_repository.dart # Payment-card simulation repository contract
│       │   │   │   └── presentation
│       │   │   │       ├── widgets
│       │   │   │       │   ├── linked_accounts_card.dart # Profile summary of simulated linked payment cards
│       │   │   │       │   ├── personal_info_sheet.dart # Editable personal-profile bottom sheet
│       │   │   │       │   ├── profile_identity_card.dart # User avatar, identity and account summary card
│       │   │   │       │   └── profile_settings_card.dart # Profile shortcuts for income, PIN and personal data
│       │   │   │       ├── add_payment_card_sheet.dart # Mock card-linking and recurring-charge import sheet
│       │   │   │       ├── income_editor_sheet.dart   # Monthly reference income editor sheet
│       │   │   │       ├── payment_card_ui_extensions.dart # Presentation formatting for mock payment cards
│       │   │   │       └── profile_tab.dart            # User profile, income and settings hub tab
│       │   │   ├── savings
│       │   │   │   ├── application
│       │   │   │   │   └── savings_provider.dart       # Savings simulator provider calculating retained capital
│       │   │   │   └── presentation
│       │   │   │       ├── widgets
│       │   │   │       │   ├── savings_checklist.dart # Selectable subscription list for savings simulation
│       │   │   │       │   └── savings_summary.dart   # Derived monthly/yearly savings result card
│       │   │   │       └── savings_tab.dart            # Interactive savings simulator tab with toggleable subscriptions
│       │   │   ├── settings
│       │   │   │   ├── application
│       │   │   │   │   └── notification_reminder_controller.dart # Notification reminder lead-time preferences controller
│       │   │   │   └── presentation
│       │   │   │       └── settings_tab.dart           # Application settings tab with PIN change, reminders & theme toggle
│       │   │   └── subscriptions
│       │   │       ├── application
│       │   │       │   ├── subscription_filter_controller.dart # Subscription search filter & sorting controller
│       │   │       │   ├── subscription_form_validator.dart # Validation rules for new subscription entry form
│       │   │       │   ├── subscription_list_controller.dart # Subscription list controller with optimistic CRUD operations
│       │   │       │   └── subscription_read_model.dart # Optimized read model for multi-currency subscription views
│       │   │       ├── data
│       │   │       │   └── in_memory_subscription_repository.dart # InMemory subscription persistence repository
│       │   │       ├── domain
│       │   │       │   ├── preset_package_catalog.dart # Preset catalog of popular Thai & international subscriptions
│       │   │       │   ├── preset_package.dart        # Frontend preset-package selection model
│       │   │       │   ├── subscription.dart           # Subscription domain entity with Creep Risk scoring
│       │   │       │   ├── subscription.freezed.dart   # Freezed generated model code
│       │   │       │   ├── subscription.g.dart         # JSON serializable / Riverpod generated code
│       │   │       │   └── subscription_repository.dart # Subscription repository contract interface
│       │   │       └── presentation
│       │   │           ├── widgets
│       │   │           │   ├── preset_package_grid.dart # Searchable preset-package result grid
│       │   │           │   ├── preset_picker_card.dart # Entry card opening the preset-package picker
│       │   │           │   ├── preset_search_field.dart # Preset package search input
│       │   │           │   ├── subscription_appearance_selector.dart # Color and brand icon selector for subscription
│       │   │           │   ├── subscription_collection.dart # Subscription list/grid responsive collection
│       │   │           │   ├── subscription_detail_header.dart # Service identity header for detail sheet
│       │   │           │   ├── subscription_detail_overview.dart # Price, billing and usage detail summary
│       │   │           │   ├── subscription_detail_sheet.dart # Edit, reminder and cancellation bottom sheet
│       │   │           │   ├── subscription_empty_state.dart # Empty/search-no-result subscription state
│       │   │           │   ├── subscription_filter_bar.dart # Search and status filters for subscriptions
│       │   │           │   ├── subscription_general_fields.dart # Name, price and billing-cycle form fields
│       │   │           │   ├── subscription_list_tile.dart # Subscription summary list item
│       │   │           │   ├── subscription_reminder_editor.dart # Per-subscription reminder override controls
│       │   │           │   └── usage_status_selector.dart # Frequent/moderate/unused selector
│       │   │           ├── add_subscription_screen.dart # Add custom subscription form screen
│       │   │           ├── select_package_screen.dart  # Select popular subscription package screen
│       │   │           ├── subscriptions_tab.dart      # Main subscriptions management tab with list & search
│       │   │           └── subscription_ui_extensions.dart # Subscription display labels, colors and formatting
│       │   └── main.dart                               # App entrypoint running ProviderScope + App
│       ├── test                                        # Automated tests directory
│       │   ├── app
│       │   │   ├── application
│       │   │   │   ├── current_tab_controller_test.dart # Unit tests for CurrentTabController
│       │   │   │   └── theme_mode_controller_test.dart # Unit tests for ThemeModeController
│       │   │   ├── presentation
│       │   │   │   ├── main_navigation_shell_test.dart # Responsive Widget tests for MainNavigationShell
│       │   │   │   └── splash_screen_theme_test.dart   # Splash screen theme tests
│       │   │   └── routing
│       │   │       └── app_router_test.dart            # Declarative router navigation tests
│       │   ├── core
│       │   │   └── widgets
│       │   │       └── confirmation_dialog_test.dart   # Widget tests for ConfirmationDialog
│       │   └── features
│       │       ├── auth
│       │       │   └── application
│       │       │       └── auth_provider_test.dart     # Auth state notifier unit tests
│       │       ├── dashboard
│       │       │   └── application
│       │       │       └── dashboard_summary_provider_test.dart # Dashboard KPI calculations unit tests
│       │       ├── notifications
│       │       │   ├── application
│       │       │   │   └── notification_center_controller_test.dart # Notification controller unit tests
│       │       │   └── presentation
│       │       │       ├── notification_theme_test.dart # Notification UI theme tests
│       │       │       └── notification_ui_extensions_test.dart # Notification formatting unit tests
│       │       ├── onboarding
│       │       │   ├── application
│       │       │   │   └── onboarding_controller_test.dart # Onboarding state unit tests
│       │       │   └── presentation
│       │       │       └── onboarding_page_theme_test.dart # Onboarding UI theme tests
│       │       ├── profile
│       │       │   └── application
│       │       │       └── user_income_controller_test.dart # Income calculation and card balance unit tests
│       │       ├── savings
│       │       │   └── application
│       │       │       └── savings_provider_test.dart  # Savings calculation unit tests
│       │       ├── settings
│       │       │   ├── application
│       │       │   │   └── notification_reminder_controller_test.dart # Settings controller unit tests
│       │       │   └── presentation
│       │       │       └── settings_tab_test.dart      # Settings tab widget & theme tests
│       │       └── subscriptions
│       │           ├── application
│       │           │   ├── subscription_filter_controller_test.dart # Subscription filtering unit tests
│       │           │   └── subscription_form_validator_test.dart # Subscription form validation unit tests
│       │           ├── data
│       │           │   └── subscription_repository_test.dart # Unit tests for InMemorySubscriptionRepository
│       │           └── presentation
│       │               └── subscription_theme_test.dart # Subscription widget theme integration tests
│       ├── analysis_options.yaml                       # Linter rules and static analysis configuration
│       ├── .fvmrc                                     # Flutter SDK version selection for FVM
│       ├── .gitignore                                  # Monorepo git ignore rules
│       ├── .metadata                                   # Flutter project metadata
│       ├── pubspec.lock                                # Locked Flutter/Dart dependency graph
│       └── pubspec.yaml                                # Flutter package metadata, dependencies and assets
│   └── server                                          # NestJS backend application boundary
│       ├── src                                         # NestJS source and configuration boundary
│       │   ├── config                                  # Typed, validated application and database environment settings
│       │   │   ├── app.config.ts                       # Typed app runtime namespace (environment, host and port)
│       │   │   ├── database.config.ts                  # Typed PostgreSQL connection contract without a database client
│       │   │   ├── env.validation.spec.ts              # Unit tests for fail-fast environment parsing rules
│       │   │   └── env.validation.ts                   # Zod environment schema and redacted validation errors
│       │   ├── swagger                                 # Swagger UI and OpenAPI documentation configuration
│       │   │   ├── swagger.config.spec.ts              # Unit tests for Swagger document generation and environment gating
│       │   │   └── swagger.config.ts                   # Swagger/OpenAPI setup and Bearer auth configuration
│       │   ├── app.controller.spec.ts                  # Unit tests for AppController
│       │   ├── app.controller.ts                       # Standard NestJS root controller
│       │   ├── app.module.spec.ts                      # Root module compilation test with explicit test environment
│       │   ├── app.module.ts                           # Global ConfigModule composition root
│       │   ├── app.service.ts                          # Standard NestJS root service
│       │   ├── main.ts                                 # HTTP runtime bootstrap using typed app configuration and Swagger setup
│       │   └── worker.ts                               # Future separate Worker runtime boundary
│       ├── Dockerfile                                  # Multi-stage Node 24 image for development, quality gates and non-root runtime
│       ├── .dockerignore                               # Restricts server image context from secrets, dependencies and generated artifacts
│       ├── eslint.config.mjs                           # ESLint flat configuration for TypeScript source
│       ├── nest-cli.json                               # NestJS CLI build configuration
│       ├── .nvmrc                                      # Pinned Node.js development runtime
│       ├── package.json                                # Server dependencies, scripts, Node and pnpm requirements
│       ├── pnpm-lock.yaml                              # Reproducible pnpm dependency graph
│       ├── pnpm-workspace.yaml                         # Local pnpm allow-list for reviewed native build scripts
│       ├── .prettierrc                                 # Server TypeScript formatting policy
│       ├── README.md                                   # NestJS server documentation
│       ├── tsconfig.build.json                         # NestJS production TypeScript build configuration
│       └── tsconfig.json                               # Strict TypeScript compiler and incremental build policy
├── doc                                                 # Cross-project documentation directory
│   ├── architecture
│   │   ├── feature_first_architecture.md               # Feature-First Clean Architecture Specification
│   │   ├── riverpod_architecture_guide.md              # Comprehensive Riverpod Architecture & State Management Guide
│   │   └── riverpod_providers_reference.md             # Riverpod Providers Quick Reference & Cheat Sheet
│   ├── backend
│   │   ├── api                                        # Canonical public REST API standards and contract conventions
│   │   │   ├── api_contract_v1.md                     # Human-readable API v1 endpoint, DTO, ownership and error contract
│   │   │   ├── api_standards.md                      # API Standards v1: HTTP, JSON, errors, auth, pagination and serialization
│   │   │   └── openapi_v1.yaml                       # Machine-readable OpenAPI 3.0 contract matching API Contract v1
│   │   ├── database                                   # Canonical PostgreSQL relational database design documents
│   │   │   └── erd_v1.md                              # Physical ERD v1: tables, columns, constraints, indexes and persistence assumptions
│   │   ├── .gitkeep                                    # Keep directory tracked in git
│   │   ├── backend_architecture_v1.md                  # Canonical Backend Architecture v1: modules, runtimes, data and async boundaries
│   │   └── domain_model_v1.md                          # Domain Model v1: entities, value objects, lifecycles, invariants and ERD decisions
│   ├── devops
│   │   └── .gitkeep                                    # Keep directory tracked in git
│   ├── frontend
│   │   └── subscription_track_frontend_screens.md      # UI Screen Specifications, Theme Policy & Component Matrix
│   ├── task
│   │   └── team_task_allocation.md                     # Developer Task Allocation, Work Breakdown & Schedule
│   └── Subscription_Track_PRD.md                       # Product Requirement Document (PRD)
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
│   └── .gitkeep                                        # Keep directory tracked in git
├── .gitignore                                          # Monorepo git ignore rules
├── README.md                                           # Full-stack monorepo project overview & getting started
├── docker-compose.yml                                  # Development API and PostgreSQL 17 orchestration with future services disabled
└── skills-lock.json                                    # Locked configuration for local agent skills

132 directories, 215 files
```

---

## 🧭 สรุปหน้าที่ของโฟลเดอร์หลัก (Key Directories Overview)

| โฟลเดอร์หลัก | ขอบเขตหน้าที่และความรับผิดชอบ (Responsibilities) |
|---|---|
| `.agents/` | รวบรวมคำสั่งการทำงานของระบบ Agent (Skills, Prompts, Cheat Sheets และ `tree_repo`) |
| `.github/` | ขอบเขตเวิร์กโฟลว์ CI/CD บน GitHub Actions (ปัจจุบันเป็นโฟลเดอร์ boundary) |
| `apps/mobile/` | แอปพลิเคชันมือถือ Flutter (Riverpod, Feature-First Architecture, iOS/Android) |
| `apps/server/` | NestJS Modular Monolith พร้อม typed configuration, Swagger documentation, default controller/service และ multi-stage Docker targets; ยังไม่มี TypeORM, Redis, BullMQ หรือ feature implementation |
| `doc/` | เอกสารข้อกำหนดและแบบระบบ (PRD, Backend Architecture, Domain Model, PostgreSQL ERD, API Standards/Contract/OpenAPI, สถาปัตยกรรม Frontend และแผนงาน) |
| `infra/` | ขอบเขตการตั้งค่า Infrastructure ระยะถัดไป; BE-004 orchestration ปัจจุบันอยู่ที่ root Compose และยังไม่สร้าง Nginx/Redis implementation |
| `scripts/` | ขอบเขตสคริปต์อัตโนมัติระดับ Repository (ปัจจุบันเป็นโฟลเดอร์ boundary) |
