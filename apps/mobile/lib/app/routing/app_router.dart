import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:subscription_track/app/application/app_flow_provider.dart';
import 'package:subscription_track/app/presentation/main_navigation_shell.dart';
import 'package:subscription_track/app/presentation/splash_screen.dart';
import 'package:subscription_track/app/routing/route_constants.dart';
import 'package:subscription_track/features/admin/presentation/admin_portal_screen.dart';
import 'package:subscription_track/features/auth/presentation/login_screen.dart';
import 'package:subscription_track/features/auth/presentation/register_screen.dart';
import 'package:subscription_track/features/auth/presentation/setup_pin_screen.dart';
import 'package:subscription_track/features/notifications/presentation/notification_center_screen.dart';
import 'package:subscription_track/features/onboarding/presentation/onboarding_screen.dart';
import 'package:subscription_track/features/dashboard/presentation/dashboard_tab.dart';
import 'package:subscription_track/features/profile/application/user_income_controller.dart';
import 'package:subscription_track/features/profile/presentation/income_editor_sheet.dart';
import 'package:subscription_track/features/profile/presentation/profile_tab.dart';
import 'package:subscription_track/features/savings/presentation/savings_tab.dart';
import 'package:subscription_track/features/settings/presentation/settings_tab.dart';
import 'package:subscription_track/features/subscriptions/presentation/add_subscription_screen.dart';
import 'package:subscription_track/features/subscriptions/presentation/select_package_screen.dart';
import 'package:subscription_track/features/subscriptions/presentation/subscriptions_tab.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier();

  // GoRouter ฟัง Listenable เพื่ออัปเดตเส้นทางเมื่อ app flow เปลี่ยน
  ref.listen<AppFlowState>(appFlowProvider, (_, __) {
    refreshNotifier.refresh();
  });
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: RouteConstants.dashboard,
    debugLogDiagnostics: kDebugMode,

    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final location = state.matchedLocation;

      final bypassAuth = ref.read(mockAuthBypassProvider);
      if (bypassAuth) {
        // สำหรับการพัฒนาและทดสอบ: เมื่อเปิด mockAuthBypassProvider
        // เปิดให้เข้าผ่าน URL Path ได้โดยตรงอย่างอิสระทุกหน้า (Direct URL Deep-Linking)
        // หากเข้าหน้า Root (/) หรือ Splash (/splash) จะส่งไปที่ Dashboard เป็นค่าเริ่มต้น
        if (location == '/' || location == RouteConstants.splash) {
          return RouteConstants.dashboard;
        }
        return null;
      }

      // --- Full Production Auth & Onboarding Redirect Guards ---
      final appFlow = ref.read(appFlowProvider);
      final isOnSplash = location == RouteConstants.splash;
      final isOnboarding = location == RouteConstants.onboarding;
      final isLoggingIn = location == RouteConstants.login;
      final isOnRegister = location == RouteConstants.register;

      // 1. หากอยู่ในสถานะเริ่มต้น (Initializing) ให้คงอยู่ที่หน้า Splash
      if (appFlow.isInitializing) {
        return isOnSplash ? null : RouteConstants.splash;
      }

      // 2. หากล็อกอินแล้ว (Authenticated) ห้ามไปหน้า Onboarding เด็ดขาด ให้ไปหน้าแรก/Dashboard
      if (appFlow.isAuthenticated) {
        // หากยังไม่ได้ตั้ง PIN ให้บังคับไปที่หน้า /setup-pin เท่านั้น
        final isOnSetupPin = location == RouteConstants.setupPin;
        if (!appFlow.isPinSetupCompleted) {
          return isOnSetupPin ? null : RouteConstants.setupPin;
        }

        // หากตั้ง PIN เสร็จแล้วแต่อยู่ในหน้า Splash, Onboarding, Login, Register, SetupPin หรือ Root (/)
        // ให้ส่งไปที่ Dashboard ทันที
        if (isOnSplash ||
            isOnboarding ||
            isLoggingIn ||
            isOnRegister ||
            isOnSetupPin ||
            location == '/') {
          return RouteConstants.dashboard;
        }

        return null;
      }

      // 3. สำหรับผู้ใช้ที่ยังไม่ได้ล็อกอิน: หากยังไม่ได้ทำ Onboarding ให้ไปที่หน้า Onboarding
      if (!appFlow.isOnboardingCompleted) {
        return isOnboarding ? null : RouteConstants.onboarding;
      }

      // 4. หากทำ Onboarding แล้วแต่ยังไม่ได้ล็อกอิน ให้ไปที่หน้า Login หรือ Register
      if (isOnSplash || isOnboarding || location == '/') {
        return RouteConstants.login;
      }

      return (isLoggingIn || isOnRegister) ? null : RouteConstants.login;

      return null;
    },

    routes: [
      GoRoute(
        path: RouteConstants.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteConstants.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteConstants.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteConstants.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteConstants.admin,
        builder: (context, state) => const AdminPortalScreen(),
      ),
      GoRoute(
        path: RouteConstants.setupPin,
        builder: (context, state) => const SetupPinScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainNavigationShell(
          navigationShell: navigationShell,
          state: state,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.dashboard,
                builder: (context, state) => const DashboardTab(),
                routes: [
                  GoRoute(
                    path: RouteConstants.notifications,
                    builder: (context, state) =>
                        const NotificationCenterScreen(),
                  ),
                  GoRoute(
                    path: RouteConstants.addSubscription,
                    builder: (context, state) =>
                        const AddSubscriptionScreen(),
                    routes: [
                      GoRoute(
                        path: RouteConstants.selectPackage,
                        builder: (context, state) =>
                            const SelectPackageScreen(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.subscriptions,
                builder: (context, state) => const SubscriptionsTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.savings,
                builder: (context, state) => const SavingsTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.settings,
                builder: (context, state) => const SettingsTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.profile,
                builder: (context, state) => ProfileTab(
                  onEditIncome: () {
                    final income = ref.read(effectiveIncomeProvider);
                    showIncomeEditorSheet(
                      context: context,
                      currentIncome: income,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'Page not found: ${state.uri.path}',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
    ),
  );
});

final class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}
