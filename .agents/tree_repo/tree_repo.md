# 📅 Repository Tree Overview — Updated: 2026-08-07

```text
└── subscription_track
    ├── .agents
    │   ├── skills                                   # Local Agent Skills Directory (including clean-code)
    │   └── tree_repo
    │       └── tree_repo.md                         # Repository tree overview guide
    ├── doc
    │   ├── Subscription_Track_PRD.md                # Product Requirement Document (PRD)
    │   ├── architecture
    │   │   └── feature_first_architecture.md        # Feature-First Clean Architecture Specification
    │   ├── frontend
    │   │   └── subscription_track_frontend_screens.md # UI Screen Specifications & Theme Policy
    │   └── task
    │       └── team_task_allocation.md              # Developer Task Allocation & Schedule
    ├── lib
    │   ├── main.dart                                # App entrypoint running ProviderScope + App
    │   ├── app
    │   │   ├── app.dart                             # Root MaterialApp.router configured with Light & Dark Themes
    │   │   ├── application
    │   │   │   ├── app_flow_provider.dart           # App startup flow state provider
    │   │   │   ├── current_tab_controller.dart      # Navigation shell tab index controller
    │   │   │   └── theme_mode_controller.dart       # Application ThemeMode controller & themeModeProvider
    │   │   ├── presentation
    │   │   │   ├── main_navigation_shell.dart       # Main shell with 5 Tabs & Adaptive Navigation (BottomNav/Rail)
    │   │   │   ├── splash_screen.dart               # Branded-dark Splash screen with title & loading spinner
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
    │   │   │   └── app_breakpoints.dart             # Responsive layout breakpoint constants
    │   │   ├── theme
    │   │   │   ├── app_colors.dart                  # Color palette system constants
    │   │   │   ├── app_dark_theme.dart              # Dark ThemeData builder
    │   │   │   ├── app_light_theme.dart             # Light ThemeData builder
    │   │   │   ├── app_theme.dart                  # Public Theme facade (AppTheme.light & AppTheme.dark)
    │   │   │   └── app_typography.dart              # Color-neutral Typography & TextStyles
    │   │   ├── utils
    │   │   │   ├── extensions.dart                  # Utility extension methods
    │   │   │   └── logger.dart                      # Development logging utility
    │   │   └── widgets
    │   │       ├── confirmation_dialog.dart         # Theme-aware reusable confirmation dialog
    │   │       └── service_icon.dart                # Brand service icon rendering widget
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
    │       │   ├── application
    │       │   │   └── dashboard_summary_provider.dart # Dashboard summary & KPI calculator
    │       │   └── presentation
    │       │       ├── dashboard_tab.dart           # Main Dashboard Tab view
    │       │       └── widgets
    │       │           ├── dashboard_content.dart   # Main dashboard content layout
    │       │           ├── dashboard_hero_card.dart # Theme-aware Hero payout card with Creep Risk score
    │       │           ├── dashboard_renewals_section.dart # Section for upcoming billing renewals
    │       │           └── dashboard_unused_alert.dart # Alert card for unused subscriptions
    │       ├── notifications                        # Notification Center Feature
    │       │   ├── application                      # Notification application logic
    │       │   ├── data                             # Notification data layer
    │       │   ├── domain                           # Notification domain models & interfaces
    │       │   └── presentation
    │       │       └── notification_center_screen.dart # Theme-aware Notification Center screen
    │       ├── onboarding                           # Onboarding Presentation Feature
    │       │   ├── application                      # Onboarding persistence state controller
    │       │   └── presentation
    │       │       ├── onboarding_controls.dart     # StoryProgressBar, Header & Navigation Controls
    │       │       ├── onboarding_data.dart         # Onboarding slide data list in Thai
    │       │       ├── onboarding_page.dart         # Branded-dark onboarding slide template
    │       │       ├── onboarding_screen.dart       # Onboarding PageView container
    │       │       └── onboarding_visuals.dart      # Bento Stack Visual Cards
    │       ├── profile                              # User Profile Feature
    │       │   ├── application                      # Profile & user income state controller
    │       │   └── presentation
    │       │       ├── income_editor_sheet.dart     # Modal bottom sheet for updating monthly income
    │       │       └── profile_tab.dart             # User Profile Tab view
    │       ├── savings                              # Savings Simulation Feature
    │       │   ├── application                      # Savings simulation goal controller
    │       │   └── presentation                     # Savings Tab view & cancellation checklist
    │       ├── settings                             # App Settings Feature
    │       │   ├── application                      # App settings & reminder controllers
    │       │   └── presentation
    │       │       └── settings_tab.dart            # App Settings Tab view with Light/Dark mode switch
    │       └── subscriptions                        # Subscriptions Management Feature
    │           ├── application
    │           │   ├── subscription_filter_controller.dart # Controller for category & search filters
    │           │   ├── subscription_form_validator.dart # Form validator for adding/editing subscription
    │           │   ├── subscription_list_controller.dart # Notifier controller for subscription CRUD
    │           │   └── subscription_read_model.dart  # Public read model boundary
    │           ├── data
    │           │   ├── in_memory_subscription_repository.dart # InMemory repository implementation
    │           │   └── preset_package_catalog.dart # Predefined subscription packages catalog
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
    │                   ├── preset_package_grid.dart # Theme-aware grid layout for preset packages
    │                   ├── preset_picker_card.dart  # Card widget for picking preset subscription
    │                   ├── preset_search_field.dart # Theme-aware search input for preset packages
    │                   ├── subscription_appearance_selector.dart # Color & icon selector widget
    │                   ├── subscription_collection.dart # Subscription collection view
    │                   ├── subscription_detail_header.dart # Detail sheet header view
    │                   ├── subscription_detail_overview.dart # Detail sheet overview section
    │                   ├── subscription_detail_sheet.dart # Modal bottom sheet for subscription details
    │                   ├── subscription_empty_state.dart # Empty state view when no subscriptions exist
    │                   ├── subscription_filter_bar.dart # Choice chips bar for category filters
    │                   ├── subscription_general_fields.dart # Theme-derived form input fields
    │                   ├── subscription_list_tile.dart # Theme-derived list tile for subscription
    │                   ├── subscription_reminder_editor.dart # Editor widget for billing reminder days
    │                   └── usage_status_selector.dart # Usage status selector chip bar
    └── test
        ├── app
        │   ├── application
        │   │   ├── current_tab_controller_test.dart # Unit tests for CurrentTabController
        │   │   └── theme_mode_controller_test.dart  # Unit tests for ThemeModeController
        │   ├── presentation
        │   │   └── main_navigation_shell_test.dart  # Responsive Widget tests for MainNavigationShell
        │   └── routing
        │       └── app_router_test.dart             # Declarative router tests
        ├── core
        │   └── widgets
        │       └── confirmation_dialog_test.dart    # Widget tests for ConfirmationDialog
        └── features
            ├── settings
            │   └── presentation
            │       └── settings_tab_test.dart       # Widget & theme integration tests for SettingsTab
            └── subscriptions
                └── data
                    └── subscription_repository_test.dart # Unit tests for InMemorySubscriptionRepository
```
