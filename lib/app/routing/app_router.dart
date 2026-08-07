import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:subscription_track/app/application/app_flow_provider.dart';
import 'package:subscription_track/app/presentation/main_navigation_shell.dart';
import 'package:subscription_track/app/presentation/splash_screen.dart';
import 'package:subscription_track/app/routing/route_constants.dart';
import 'package:subscription_track/features/auth/presentation/login_screen.dart';
import 'package:subscription_track/features/notifications/presentation/notification_center_screen.dart';
import 'package:subscription_track/features/onboarding/presentation/onboarding_screen.dart';

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

      /*
      // --- Full Production Auth & Onboarding Redirect Guards (Commented Out for Dev Flexibility) ---
      final appFlow = ref.read(appFlowProvider);
      final isOnSplash = location == RouteConstants.splash;
      final isOnboarding = location == RouteConstants.onboarding;
      final isLoggingIn = location == RouteConstants.login;

      // 1. หากอยู่ในสถานะเริ่มต้น (Initializing) ให้คงอยู่ที่หน้า Splash
      if (appFlow.isInitializing) {
        return isOnSplash ? null : RouteConstants.splash;
      }

      // 2. หากยังไม่ได้ทำ Onboarding ให้ไปที่หน้า Onboarding
      if (!appFlow.isOnboardingCompleted) {
        return isOnboarding ? null : RouteConstants.onboarding;
      }

      // 3. หากยังไม่ได้ล็อกอิน ให้ไปที่หน้า Login
      if (!appFlow.isAuthenticated) {
        return isLoggingIn ? null : RouteConstants.login;
      }

      // 4. หากล็อกอินเรียบร้อยแล้ว แต่อยู่ในหน้า Splash, Onboarding หรือ Login ให้เปลี่ยนไปหน้า Dashboard
      if (isOnSplash || isOnboarding || isLoggingIn) {
        return RouteConstants.dashboard;
      }
      */

      // สำหรับการพัฒนาและทดสอบ: เปิดให้เข้าผ่าน URL Path ได้โดยตรงอย่างอิสระทุกหน้า (Direct URL Deep-Linking)
      // หากเข้าหน้า Root (/) หรือ Splash (/splash) จะส่งไปที่ Dashboard เป็นค่าเริ่มต้น
      // แต่หากระบุ URL Path อื่นๆ เช่น /login หรือ /onboarding จะเปิดหน้านั้นให้ทันทีโดยไม่สกัดกั้น
      if (location == '/' || location == RouteConstants.splash) {
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
