import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:subscription_track/core/theme/app_colors.dart';

/// A secure, Web- and Mobile-compatible PIN code input widget.
///
/// Implements a dual-layer stack architecture:
/// 1. Bottom layer: Visual dot/digit segmented boxes wrapped in [IgnorePointer]
///    to reflect state without capturing or blocking pointer events.
/// 2. Top layer: An invisible [TextField] spanning the exact bounding box,
///    allowing native focus, physical keyboard input, virtual keyboard, and
///    paste events across all platforms.
class PinCodeInput extends StatelessWidget {
  const PinCodeInput({
    super.key,
    required this.controller,
    required this.focusNode,
    this.textFieldKey,
    this.length = 6,
    this.hasError = false,
    this.isLoading = false,
    this.obscureText = true,
    this.autoFocus = true,
    this.onCompleted,
    this.onChanged,
    this.boxWidth = 40.0,
    this.boxHeight = 48.0,
    this.boxSpacing = 8.0,
    this.textStyle,
  });

  /// Controller managing the entered PIN text.
  final TextEditingController controller;

  /// FocusNode managing focus for the input field.
  final FocusNode focusNode;

  /// Optional Key assigned directly to the internal [TextField] for testing.
  final Key? textFieldKey;

  /// The total number of PIN digits (defaults to 6).
  final int length;

  /// Whether the input is currently in an error state.
  final bool hasError;

  /// Whether the input is currently disabled/loading.
  final bool isLoading;

  /// Whether to obscure digits with bullets `•` (defaults to true).
  final bool obscureText;

  /// Whether to automatically request focus on launch.
  final bool autoFocus;

  /// Callback fired when exactly [length] digits have been entered.
  final ValueChanged<String>? onCompleted;

  /// Callback fired whenever the text value changes.
  final ValueChanged<String>? onChanged;

  /// Width of each digit box.
  final double boxWidth;

  /// Height of each digit box.
  final double boxHeight;

  /// Spacing between digit boxes.
  final double boxSpacing;

  /// Text style for displayed digits/bullets.
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalWidth = (boxWidth * length) + (boxSpacing * (length - 1));

    return ListenableBuilder(
      listenable: Listenable.merge([controller, focusNode]),
      builder: (context, _) {
        final text = controller.text;

        return SizedBox(
          width: totalWidth,
          height: boxHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Layer 1: Visual segmented boxes (IgnorePointer ensures no hit-test collision)
              IgnorePointer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(length, (index) {
                    final hasValue = index < text.length;
                    final isFocused = focusNode.hasFocus && index == text.length;

                    final borderColor = hasError
                        ? AppColors.danger
                        : isFocused
                            ? theme.colorScheme.primary
                            : theme.dividerColor;

                    final borderWidth = isFocused || hasError ? 2.0 : 1.0;

                    final displayText = hasValue
                        ? (obscureText ? '•' : text[index])
                        : '';

                    return Container(
                      width: boxWidth,
                      height: boxHeight,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: borderColor,
                          width: borderWidth,
                        ),
                      ),
                      child: Text(
                        displayText,
                        style: textStyle ??
                            const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    );
                  }),
                ),
              ),

              // Layer 2: Invisible TextField spanning the exact area
              Positioned.fill(
                child: Opacity(
                  opacity: 0.0,
                  child: TextField(
                    key: textFieldKey ?? const Key('pin_code_text_field'),
                    controller: controller,
                    focusNode: focusNode,
                    autofocus: autoFocus,
                    enabled: !isLoading,
                    keyboardType: TextInputType.number,
                    maxLength: length,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    showCursor: false,
                    cursorColor: Colors.transparent,
                    onChanged: (val) {
                      onChanged?.call(val);
                      if (val.length == length) {
                        onCompleted?.call(val);
                      }
                    },
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
