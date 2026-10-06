import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/core/security/pin_provider.dart';
import 'package:subscription_track/core/theme/app_colors.dart';
import 'package:subscription_track/core/theme/app_typography.dart';

class PinVerificationDialog extends ConsumerStatefulWidget {
  const PinVerificationDialog({
    super.key,
    required this.title,
    this.message = 'กรุณากรอกรหัส PIN 6 หลักเพื่อยืนยันการทำรายการ',
    this.returnPinOnSuccess = false,
  });

  final String title;
  final String message;
  final bool returnPinOnSuccess;

  @override
  ConsumerState<PinVerificationDialog> createState() => _PinVerificationDialogState();

  static Future<bool> show({
    required BuildContext context,
    required String title,
    String message = 'กรุณากรอกรหัส PIN 6 หลักเพื่อยืนยันการทำรายการ',
  }) async {
    final result = await showDialog<dynamic>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PinVerificationDialog(
        title: title,
        message: message,
      ),
    );
    return result == true || result is String;
  }

  static Future<String?> showForPin({
    required BuildContext context,
    required String title,
    String message = 'กรุณากรอกรหัส PIN 6 หลักเพื่อยืนยันการทำรายการ',
  }) async {
    final result = await showDialog<dynamic>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PinVerificationDialog(
        title: title,
        message: message,
        returnPinOnSuccess: true,
      ),
    );
    if (result is String) {
      return result;
    }
    return null;
  }
}

class _PinVerificationDialogState extends ConsumerState<PinVerificationDialog> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Auto focus on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _verifyPin(String enteredPin) async {
    if (enteredPin.length != 6 || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repo = ref.read(pinRepositoryProvider);
    final result = await repo.verifyPin(enteredPin);

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = failure.displayMessage;
          _pinController.clear();
        });
        _focusNode.requestFocus();
      },
      (isValid) {
        if (isValid) {
          setState(() {
            _isLoading = false;
            _errorMessage = null;
          });
          Navigator.of(context).pop(widget.returnPinOnSuccess ? enteredPin : true);
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'รหัส PIN ไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง';
            _pinController.clear();
          });
          _focusNode.requestFocus();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = _pinController.text;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: theme.colorScheme.primary,
            size: 40,
          ),
          const SizedBox(height: 16),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: AppTypography.headingSmall.copyWith(
              color: theme.textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 24),
          // PIN input: Visual boxes underneath + transparent TextField on top spanning the exact area
          SizedBox(
            width: 280,
            height: 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                IgnorePointer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      final hasValue = index < text.length;
                      final isFocused = _focusNode.hasFocus && index == text.length;

                      return Container(
                        width: 40,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _errorMessage != null
                                ? AppColors.danger
                                : isFocused
                                    ? theme.colorScheme.primary
                                    : theme.dividerColor,
                            width: isFocused || _errorMessage != null ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          hasValue ? '•' : '',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.0,
                    child: TextField(
                      key: const Key('verify_pin_text_field'),
                      controller: _pinController,
                      focusNode: _focusNode,
                      autofocus: true,
                      enabled: !_isLoading,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (val) {
                        setState(() {
                          if (_errorMessage != null) {
                            _errorMessage = null;
                          }
                        });
                        if (val.length == 6) {
                          _verifyPin(val);
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
          ),
          if (_isLoading) ...[
            const SizedBox(height: 16),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('ยกเลิก'),
        ),
      ],
    );
  }
}
