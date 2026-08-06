import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:subscription_track/features/subscriptions/presentation/add_subscription_screen.dart';
import 'package:subscription_track/features/subscriptions/presentation/select_package_screen.dart';
import 'package:subscription_track/features/auth/presentation/login_screen.dart';
import 'package:subscription_track/providers/app_flow_provider.dart';
import 'package:subscription_track/router/route_constants.dart';
import 'package:subscription_track/screens/main_navigation_shell.dart';
import 'package:subscription_track/screens/onboarding/onboarding_screen.dart';
import 'package:subscription_track/screens/splash_screen.dart';
import 'package:subscription_track/features/notifications/presentation/notification_center_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier();

  // GoRouter ไม่รู้จัก Riverpod โดยตรง จึงแปลงการเปลี่ยน app flow
  // เป็น Listenable เพื่อประเมิน redirect ใหม่โดยไม่สร้าง Router ซ้ำ
  ref.listen<AppFlowState>(appFlowProvider, (_, __) {
    refreshNotifier.refresh();
  });
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: RouteConstants.splash,
    debugLogDiagnostics: kDebugMode,

    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isOnSplash = location == RouteConstants.splash;
      final isOnOnboarding = location == RouteConstants.onboarding;
      final isOnLogin = location == RouteConstants.login;
      final appFlow = ref.read(appFlowProvider);

      if (appFlow.isInitializing) {
        return isOnSplash ? null : RouteConstants.splash;
      }

      if (!appFlow.isOnboardingCompleted) {
        return isOnOnboarding ? null : RouteConstants.onboarding;
      }

      if (!appFlow.isAuthenticated) {
        return isOnLogin ? null : RouteConstants.login;
      }

      if (isOnSplash || isOnOnboarding || isOnLogin) {
        return RouteConstants.dashboard;
      }

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
        path: RouteConstants.dashboard,
        builder: (context, state) => const MainNavigationShell(),
        routes: [
          GoRoute(
            path: RouteConstants.addSubscription,
            builder: (context, state) => const AddSubscriptionScreen(),
            routes: [
              GoRoute(
                path: RouteConstants.selectPackage,
                builder: (context, state) => const SelectPackageScreen(),
              ),
            ],
          ),
          GoRoute(
            path: RouteConstants.notifications,
            builder: (context, state) => const NotificationCenterScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'Page not found: ${state.uri.path}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    ),
  );
});

final class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}
