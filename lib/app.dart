import 'package:flutter/material.dart';
import 'package:subscription_track/core/theme/app_theme.dart';
import 'package:subscription_track/router/app_router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Subscription Track',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
