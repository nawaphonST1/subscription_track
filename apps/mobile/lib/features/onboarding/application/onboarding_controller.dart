import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final onboardingProvider = NotifierProvider<OnboardingController, bool>(
  OnboardingController.new,
);

final class OnboardingController extends Notifier<bool> {
  static const String _onboardingKey = 'onboarding_completed';

  @override
  bool build() {
    _loadFromPrefs();
    return false;
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final completed = prefs.getBool(_onboardingKey) ?? false;
      if (completed != state) {
        state = completed;
      }
    } catch (_) {}
  }

  void setCompleted(bool value) {
    state = value;
    _saveToPrefs(value);
  }

  Future<void> _saveToPrefs(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, value);
    } catch (_) {}
  }
}

