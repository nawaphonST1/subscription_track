# 📱 Frontend Architecture Rules (Flutter & Riverpod)

This reference document defines Clean Code and Architecture standards for the Flutter mobile application in `apps/mobile/`.

---

## 1. Feature-First Layered Structure

The frontend codebase is located under `apps/mobile/` and organized by business feature under `apps/mobile/lib/features/<feature>/`:

```text
apps/mobile/lib/features/<feature>/
├── domain/        # Business entities, value objects, domain logic, repository interfaces (pure Dart)
├── data/          # Repository implementations, data sources, API clients, local storage/mocks
├── application/   # Riverpod Notifiers/Controllers, providers, derived view state, form validators
└── presentation/  # Screens, tabs, modal sheets, dialogs, and feature-specific widgets
```

### Layer Dependency Direction (Strict)
```text
[Presentation] ──> [Application] ──> [Domain Contracts] <── [Data Implementation]
```

### Strict Architectural Boundaries:
1. **Domain Layer is Pure Dart:**
   - MUST NOT import `package:flutter/...` or `package:flutter_riverpod/...`.
   - Contains only entities, value objects, domain validation, and abstract repository contracts.
2. **Presentation Never Imports Data:**
   - Presentation widgets MUST NOT import repository implementations or data sources directly.
   - All state observation and command mutations MUST pass through `application/` controllers.
3. **Cross-Feature Boundaries:**
   - Feature modules MUST NOT import internal layers (`data/` or internal controllers) of another feature.
   - If Feature A needs data from Feature B, Feature B MUST expose a narrow public application contract (e.g., `features/subscriptions/application/subscription_read_model.dart`).
4. **App & Core Placement:**
   - `apps/mobile/lib/app/`: Reserved for global concerns (startup flow, GoRouter declarative routes, `MainNavigationShell`, global theme mode controller).
   - `apps/mobile/lib/core/widgets/`: Move a widget here ONLY when at least **two distinct features** genuinely share it. If used by one feature, it belongs in that feature's `presentation/widgets/`.
5. **Code Generation Integrity:**
   - NEVER manually edit generated files (`*.g.dart`, `*.freezed.dart`). Always regenerate via `cd apps/mobile && dart run build_runner build --delete-conflicting-outputs`.

---

## 2. Riverpod State Ownership & Reactive UI

State in Flutter must have an intentional, single authoritative owner.

### Controller & Notifier Responsibilities:
- Use `AsyncNotifierProvider` / `NotifierProvider` inside `application/`.
- UI widgets must remain purely **declarative**:
  - Presentation code should only render state and forward user events to controllers.
  - Business calculations, spending creep algorithms, and state transitions belong strictly in the `application/` or `domain/` layer.
- Optimistic UI updates (e.g., delete, toggle) must handle failure gracefully with state rollback and user error notification.

### State Ownership Reference in `subscription_track`:
| State / Responsibility | Authoritative Owner | Rule |
|---|---|---|
| Subscription List & CRUD | `features/subscriptions/application` | `subscriptionListProvider` owns optimistic CRUD; `Subscription.isSelected` is single source of selection. |
| Search & Filter State | `features/subscriptions/application` | Combined in a single `SubscriptionFilterState` to prevent conflicting filters. |
| Dashboard Summary & KPIs | `features/dashboard/application` | Read model derived from subscriptions; owns KPI cards, spending creep score, and renewal timeline. |
| Savings Simulation | `features/savings/application` | Derived calculation from selected subscriptions; does not hold duplicate selection state. |
| User Income & Cards | `features/profile/application` | Income derived from linked card balances; owns `PaymentCardLinkingController`. |
| Security PIN & Verification | `apps/mobile/lib/core/security/pin_provider.dart` | Owns 6-digit PIN verification and change flows. |
| Theme Mode (Light/Dark) | `apps/mobile/lib/app/application/theme_mode_controller.dart` | Global app theme state; observed by root `MaterialApp.router`. |

---

## 3. Frontend Review & Refactoring Checklist

When reviewing or refactoring Flutter code:
- [ ] Are business logic or calculations leaking into `build()` methods or presentation widgets?
- [ ] Is any widget in `domain/` importing Flutter or Riverpod?
- [ ] Are files exceeding ~200 lines mixing layout, validation, and network/state coordination?
- [ ] Is there duplicate state maintained across multiple controllers?
- [ ] Are theme colors and text styles accessed via `Theme.of(context)` or design tokens instead of hardcoded hex colors?
- [ ] Does error handling provide user feedback (e.g., SnackBar, dialog) rather than silently catching exceptions?

---

## 4. Frontend Validation Suite

Run validation from `apps/mobile/` in proportion to changes made:
1. `cd apps/mobile && dart format <path>`: Ensure clean, standard Dart formatting.
2. `cd apps/mobile && dart analyze`: Verify zero warnings and zero lint errors.
3. Targeted tests: `cd apps/mobile && flutter test test/features/<feature>/...`
4. Full test suite: `cd apps/mobile && flutter test` for cross-cutting or architectural refactors.
