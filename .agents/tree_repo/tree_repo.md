# 📅 Repository Tree Overview — Updated: 2026-08-06

```text
└── subscription_track
    ├── .agents
    │   ├── skills                                   # 23 Local Agent Skills Directory (including clean-code)
    │   └── tree_repo
    │       └── tree_repo.md                         # Repository tree overview guide
    ├── doc
    │   ├── Subscription_Track_PRD.md                # Product Requirement Document (PRD)
    │   ├── architecture
    │   │   └── feature_first_architecture.md        # Feature-First Clean Architecture Specification
    │   ├── frontend
    │   │   └── subscription_track_frontend_screens.md # UI Screen Specifications (11 Screens)
    │   └── task
    │       └── team_task_allocation.md              # 3-Developer Task Allocation & Schedule
    ├── lib
    │   ├── main.dart                                # App entrypoint running ProviderScope + App
    │   ├── app
    │   │   ├── app.dart                             # Root MaterialApp.router configured with Dark Fintech Theme
    │   │   ├── application
    │   │   │   ├── app_flow_provider.dart           # App startup flow state provider (Splash -> Onboarding -> Login -> Dashboard)
    │   │   │   └── current_tab_controller.dart      # Navigation shell tab index controller
    │   │   ├── presentation
    │   │   │   ├── main_navigation_shell.dart       # Main shell with 5 Tabs & Adaptive Navigation (BottomNav/Rail)
    │   │   │   ├── splash_screen.dart               # Splash screen with Thai title & loading spinner
    │   │   │   └── widgets
    │   │   │       ├── main_app_header.dart         # Main application header with income chip & profile button
    │   │   │       └── main_app_navigation.dart     # Adaptive navigation bar / navigation rail widget
    │   │   └── routing
    │   │       ├── app_router.dart                  # GoRouter declarative configuration
    │   │       └── route_constants.dart             # String route path constants
    │   ├── core
    │   │   ├── constants
    │   │   │   └── app_constants.dart               # Core application constants
    │   │   ├── errors
    │   │   │   └── failures.dart                    # Application failure & exception models
    │   │   ├── layout
    │   │   │   └── app_breakpoints.dart             # Responsive layout breakpoint constants (mobile 375, tablet 600, desktop 1200)
    │   │   ├── theme
    │   │   │   ├── app_colors.dart                  # Color palette system (bgPrimary, primary, danger, etc.)
    │   │   │   ├── app_theme.dart                  # ThemeData configuration (Dark Mode, Buttons, Inputs)
    │   │   │   └── app_typography.dart              # Typography & TextStyles
    │   │   └── utils
    │   │       ├── extensions.dart                  # Utility extension methods
    │   │       └── logger.dart                      # Development logging utility
    │   └── features                                 # Feature-First Architecture Modules
    │       ├── auth                                 # Authentication Feature
    │       │   ├── application
    │       │   │   └── auth_provider.dart           # Auth stateNotifier provider
    │       │   ├── data
    │       │   │   └── in_memory_auth_repository.dart # InMemory authentication repository implementation
    │       │   ├── domain
    │       │   │   ├── auth_repository.dart         # Auth repository contract interface
    │       │   │   └── user.dart                    # User domain entity model
    │       │   └── presentation
    │       │       └── login_screen.dart            # Login screen with Google Auth mock
    │       ├── dashboard                            # Dashboard Feature
    │       │   └── presentation
    │       │       ├── dashboard_tab.dart           # Main Dashboard Tab view
    │       │       └── widgets
    │       │           ├── dashboard_content.dart   # Main dashboard content layout
    │       │           ├── dashboard_hero_card.dart # Hero payout card with Creep Risk score
    │       │           ├── dashboard_renewals_section.dart # Section for upcoming billing renewals
    │       │           └── dashboard_unused_alert.dart # Alert card for unused subscriptions
    │       ├── notifications                        # Notification Center Feature
    │       │   ├── application                      # Notification application logic
    │       │   ├── data                             # Notification data layer
    │       │   ├── domain                           # Notification domain models & interfaces
    │       │   └── presentation
    │       │       └── notification_center_screen.dart # Notification Center screen
    │       ├── onboarding                           # Onboarding Presentation Feature
    │       │   ├── application                      # Onboarding persistence state controller
    │       │   └── presentation
    │       │       ├── onboarding_controls.dart     # StoryProgressBar, Header & Navigation Controls
    │       │       ├── onboarding_data.dart         # Onboarding slide data list in Thai
    │       │       ├── onboarding_page.dart         # Single onboarding slide template
    │       │       ├── onboarding_screen.dart       # Onboarding PageView container
    │       │       └── onboarding_visuals.dart      # Bento Stack Visual Cards (Responsive)
    │       ├── profile                              # User Profile Feature
    │       │   ├── application                      # Profile & user income state controller
    │       │   └── presentation                     # Profile Tab view & widgets
    │       ├── savings                              # Savings Simulation Feature
    │       │   ├── application                      # Savings simulation goal controller
    │       │   └── presentation                     # Savings Tab view & cancellation checklist
    │       ├── settings                             # App Settings Feature
    │       │   ├── application                      # App settings state controller
    │       │   └── presentation                     # App Settings Tab view
    │       └── subscriptions                        # Subscriptions Management Feature
    │           ├── application
    │           │   ├── subscription_filter_controller.dart # Controller for category & search filters
    │           │   ├── subscription_form_validator.dart # Form validator for adding/editing subscription
    │           │   └── subscription_list_controller.dart # Notifier controller for subscription CRUD operations
    │           ├── data
    │           │   ├── in_memory_subscription_repository.dart # InMemory repository implementation
    │           │   └── preset_package_catalog.dart # Catalog data of predefined subscription packages
    │           ├── domain
    │           │   ├── preset_package.dart          # Preset package entity model
    │           │   ├── subscription.dart            # Subscription domain entity
    │           │   └── subscription_repository.dart # Subscription repository contract interface
    │           └── presentation
    │               ├── add_subscription_screen.dart # Form screen for adding new subscription
    │               ├── select_package_screen.dart   # Screen for selecting predefined package
    │               ├── subscription_ui_extensions.dart # UI Extensions for subscription status & colors
    │               ├── subscriptions_tab.dart       # Subscriptions Tab view
    │               └── widgets
    │                   ├── preset_package_grid.dart # Grid layout for preset packages
    │                   ├── preset_picker_card.dart  # Card widget for picking preset subscription
    │                   ├── preset_search_field.dart # Search input field for preset packages
    │                   ├── subscription_appearance_selector.dart # Color & icon selector widget
    │                   ├── subscription_collection.dart # Subscription collection view
    │                   ├── subscription_detail_header.dart # Detail sheet header view
    │                   ├── subscription_detail_overview.dart # Detail sheet overview section
    │                   ├── subscription_detail_sheet.dart # Modal bottom sheet for subscription details
    │                   ├── subscription_empty_state.dart # Empty state view when no subscriptions exist
    │                   ├── subscription_filter_bar.dart # Choice chips bar for category filters
    │                   ├── subscription_general_fields.dart # Form input fields for subscription info
    │                   ├── subscription_list_tile.dart # List tile for displaying single subscription
    │                   ├── subscription_reminder_editor.dart # Editor widget for billing reminder days
    │                   └── usage_status_selector.dart # Usage status selector chip bar
    ├── test
    │   ├── mocks.dart                               # Shared Mockito test mocks
    │   ├── widget_test.dart                         # E2E Widget Tests for App Flow & Navigation
    │   ├── repositories
    │   │   └── subscription_repository_test.dart    # Unit tests for InMemorySubscriptionRepository
    │   ├── screens
    │   │   └── main_navigation_shell_test.dart      # Responsive Widget Tests for MainNavigationShell
    │   └── widgets
    │       └── common
    │           └── confirmation_dialog_test.dart    # Widget tests for ConfirmationDialog
    └── pubspec.yaml                                 # Flutter Project Configuration & Dependency Manifest
```
