import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:subscription_track/features/subscriptions/presentation/add_subscription_screen.dart';
import 'package:subscription_track/features/subscriptions/presentation/select_package_screen.dart';
import 'package:subscription_track/features/auth/presentation/login_screen.dart';
import 'package:subscription_track/features/onboarding/presentation/onboarding_screen.dart';
import 'package:subscription_track/app/application/app_flow_provider.dart';
import 'package:subscription_track/app/presentation/main_navigation_shell.dart';
import 'package:subscription_track/app/presentation/splash_screen.dart';
import 'package:subscription_track/app/routing/route_constants.dart';
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

      // เอา Guards Redirect ออกชั่วคราวเพื่อความสะดวกในการ dev
      // โดยให้ข้ามหน้า Splash ไปยัง Dashboard เป็นหลัก ส่วนหน้าอื่น ๆ สามารถกดเข้าตรง ๆ ได้เลย
      if (isOnSplash) {
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
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
    ),
  );
});

final class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}
