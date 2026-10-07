import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/core/security/pin_provider.dart';
import 'package:subscription_track/core/theme/app_colors.dart';
import 'package:subscription_track/core/theme/app_typography.dart';
import 'package:subscription_track/core/widgets/pin/pin.dart';

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
  ConsumerState<PinVerificationDialog> createState() =>
      _PinVerificationDialogState();

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

class _PinVerificationDialogState
    extends ConsumerState<PinVerificationDialog> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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

  void _onKeypadTap(String digit) {
    if (_isLoading) return;
    PinKeypadHelper.handleDigitTap(
      controller: _pinController,
      focusNode: _focusNode,
      digit: digit,
      onChanged: (_) {
        if (_errorMessage != null) {
          setState(() => _errorMessage = null);
        }
      },
      onCompleted: _verifyPin,
    );
  }

  void _onKeypadClear() {
    if (_isLoading) return;
    PinKeypadHelper.handleClear(
      controller: _pinController,
      focusNode: _focusNode,
      onCleared: () {
        if (_errorMessage != null) {
          setState(() => _errorMessage = null);
        }
      },
    );
  }

  void _onKeypadBackspace() {
    if (_isLoading) return;
    PinKeypadHelper.handleBackspace(
      controller: _pinController,
      focusNode: _focusNode,
      onChanged: (_) {
        if (_errorMessage != null) {
          setState(() => _errorMessage = null);
        }
      },
    );
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
          Navigator.of(context).pop(
            widget.returnPinOnSuccess ? enteredPin : true,
          );
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

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      content: SingleChildScrollView(
        child: Column(
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
            const SizedBox(height: 20),
            PinCodeInput(
              textFieldKey: const Key('verify_pin_text_field'),
              controller: _pinController,
              focusNode: _focusNode,
              isLoading: _isLoading,
              hasError: _errorMessage != null,
              onCompleted: _verifyPin,
              onChanged: (val) {
                if (_errorMessage != null) {
                  setState(() => _errorMessage = null);
                }
              },
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
              const SizedBox(height: 12),
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
            const SizedBox(height: 16),
            PinNumericKeypad(
              disabled: _isLoading,
              onDigitTap: _onKeypadTap,
              onClearTap: _onKeypadClear,
              onBackspaceTap: _onKeypadBackspace,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('ยกเลิก'),
        ),
      ],
    );
  }
}
