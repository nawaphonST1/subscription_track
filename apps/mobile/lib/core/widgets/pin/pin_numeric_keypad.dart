import 'package:flutter/material.dart';

/// An on-screen numeric keypad for PIN entry (Web and Mobile).
class PinNumericKeypad extends StatelessWidget {
  const PinNumericKeypad({
    super.key,
    required this.onDigitTap,
    required this.onClearTap,
    required this.onBackspaceTap,
    this.disabled = false,
    this.buttonWidth = 68.0,
    this.buttonHeight = 44.0,
  });

  /// Fired when a digit (0–9) is tapped.
  final ValueChanged<String> onDigitTap;

  /// Fired when the "ล้าง" (clear) button is tapped.
  final VoidCallback onClearTap;

  /// Fired when the backspace button is tapped.
  final VoidCallback onBackspaceTap;

  /// Whether the keypad is disabled (e.g. during network calls).
  final bool disabled;

  /// Fixed width of each keypad button.
  final double buttonWidth;

  /// Fixed height of each keypad button.
  final double buttonHeight;

  @override
  Widget build(BuildContext context) {
    const keypadLayout = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['clear', '0', 'backspace'],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in keypadLayout)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((key) {
                if (key == 'clear') {
                  return SizedBox(
                    width: buttonWidth,
                    height: buttonHeight,
                    child: TextButton(
                      key: const Key('pin_key_clear'),
                      onPressed: disabled ? null : onClearTap,
                      child: const Text(
                        'ล้าง',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  );
                }
                if (key == 'backspace') {
                  return SizedBox(
                    width: buttonWidth,
                    height: buttonHeight,
                    child: IconButton(
                      key: const Key('pin_key_backspace'),
                      icon: const Icon(Icons.backspace_outlined, size: 20),
                      onPressed: disabled ? null : onBackspaceTap,
                    ),
                  );
                }
                return SizedBox(
                  width: buttonWidth,
                  height: buttonHeight,
                  child: OutlinedButton(
                    key: Key('pin_key_$key'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: disabled ? null : () => onDigitTap(key),
                    child: Text(
                      key,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
          ),
      ],
    );
  }
}
