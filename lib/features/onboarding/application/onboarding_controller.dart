import 'package:flutter_riverpod/flutter_riverpod.dart';

final onboardingProvider = NotifierProvider<OnboardingController, bool>(
  OnboardingController.new,
);

final class OnboardingController extends Notifier<bool> {
  @override
  bool build() => false;

  void setCompleted(bool value) => state = value;
}
