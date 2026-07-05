import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Subscription Creep Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0F1D), // Dark navy theme background
        primaryColor: const Color(0xFF3B82F6),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6),
          secondary: Color(0xFF10B981),
          surface: Color(0xFF131C2E),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'sans-serif'),
          bodyMedium: TextStyle(fontFamily: 'sans-serif'),
        ),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}
