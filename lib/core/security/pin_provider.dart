import 'package:flutter_riverpod/flutter_riverpod.dart';

final securityPinProvider = NotifierProvider<SecurityPinNotifier, String>(() {
  return SecurityPinNotifier();
});

class SecurityPinNotifier extends Notifier<String> {
  @override
  String build() => '111111';

  void updatePin(String newPin) {
    if (newPin.length == 6 && RegExp(r'^\d+$').hasMatch(newPin)) {
      state = newPin;
    }
  }

  bool verifyPin(String pin) {
    return state == pin;
  }
}
