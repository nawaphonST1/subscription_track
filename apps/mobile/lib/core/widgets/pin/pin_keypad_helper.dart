import 'package:flutter/material.dart';

/// Helper utility for handling keypad events on a [TextEditingController].
class PinKeypadHelper {
  PinKeypadHelper._();

  /// Appends [digit] to [controller] if length is less than [maxLength],
  /// requests focus on [focusNode], and notifies callbacks.
  static void handleDigitTap({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String digit,
    int maxLength = 6,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onCompleted,
  }) {
    if (controller.text.length < maxLength) {
      final updated = controller.text + digit;
      controller.text = updated;
      focusNode.requestFocus();
      onChanged?.call(updated);
      if (updated.length == maxLength) {
        onCompleted?.call(updated);
      }
    }
  }

  /// Clears [controller], requests focus, and notifies [onCleared] / [onChanged].
  static void handleClear({
    required TextEditingController controller,
    required FocusNode focusNode,
    VoidCallback? onCleared,
    ValueChanged<String>? onChanged,
  }) {
    if (controller.text.isNotEmpty) {
      controller.clear();
      focusNode.requestFocus();
      onCleared?.call();
      onChanged?.call('');
    }
  }

  /// Trims last character from [controller], requests focus, and notifies [onChanged].
  static void handleBackspace({
    required TextEditingController controller,
    required FocusNode focusNode,
    ValueChanged<String>? onChanged,
  }) {
    if (controller.text.isNotEmpty) {
      final current = controller.text;
      final updated = current.substring(0, current.length - 1);
      controller.text = updated;
      focusNode.requestFocus();
      onChanged?.call(updated);
    }
  }
}
