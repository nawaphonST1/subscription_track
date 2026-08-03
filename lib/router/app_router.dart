import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:subscription_track/router/route_constants.dart';
import 'package:subscription_track/screens/onboarding/onboarding_screen.dart';
import 'package:subscription_track/screens/splash_screen.dart';
import 'package:subscription_track/screens/login/login_screen.dart';
import 'package:subscription_track/screens/dashboard_screen.dart';

final appRouter = GoRouter(
  initialLocation: RouteConstants.splash,
  debugLogDiagnostics: true,
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
      builder: (context, state) => const DashboardScreen(),
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
