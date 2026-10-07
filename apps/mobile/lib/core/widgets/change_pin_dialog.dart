import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/core/security/pin_provider.dart';
import 'package:subscription_track/core/theme/app_colors.dart';
import 'package:subscription_track/core/theme/app_typography.dart';
import 'package:subscription_track/core/widgets/pin/pin.dart';

class ChangePinDialog extends ConsumerStatefulWidget {
  const ChangePinDialog({super.key});

  @override
  ConsumerState<ChangePinDialog> createState() => _ChangePinDialogState();

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ChangePinDialog(),
    );
  }
}

enum ChangePinStep { verifyOld, enterNew, confirmNew }

class _ChangePinDialogState extends ConsumerState<ChangePinDialog> {
  ChangePinStep _step = ChangePinStep.verifyOld;
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _errorMessage;
  bool _isLoading = false;

  String _oldPin = '';
  String _newPin = '';

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

  void _onKeypadTap(String key) {
    if (_isLoading) return;
    PinKeypadHelper.handleDigitTap(
      controller: _pinController,
      focusNode: _focusNode,
      digit: key,
      onChanged: (_) {
        if (_errorMessage != null) {
          setState(() => _errorMessage = null);
        }
      },
      onCompleted: _handlePinSubmit,
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

  Future<void> _handlePinSubmit(String value) async {
    if (value.length != 6 || _isLoading) return;

    setState(() {
      _errorMessage = null;
    });

    final repo = ref.read(pinRepositoryProvider);

    switch (_step) {
      case ChangePinStep.verifyOld:
        setState(() {
          _isLoading = true;
        });

        final result = await repo.verifyPin(value);
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
                _oldPin = value;
                _step = ChangePinStep.enterNew;
                _pinController.clear();
              });
              _focusNode.requestFocus();
            } else {
              setState(() {
                _isLoading = false;
                _errorMessage = 'รหัส PIN เดิมไม่ถูกต้อง';
                _pinController.clear();
              });
              _focusNode.requestFocus();
            }
          },
        );

      case ChangePinStep.enterNew:
        if (value == _oldPin) {
          setState(() {
            _errorMessage = 'รหัส PIN ใหม่ต้องไม่ซ้ำกับรหัสเดิม';
            _pinController.clear();
          });
          _focusNode.requestFocus();
          return;
        }

        // Prevent weak patterns (repeated digits or simple sequences)
        final isRepeated = RegExp(r'^(\d)\1{5}$').hasMatch(value);
        if (isRepeated || value == '123456' || value == '654321') {
          setState(() {
            _errorMessage =
                'PIN is too weak. Please avoid sequential (123456) or repeated numbers (111111).';
            _pinController.clear();
          });
          _focusNode.requestFocus();
          return;
        }

        setState(() {
          _newPin = value;
          _step = ChangePinStep.confirmNew;
          _pinController.clear();
        });
        _focusNode.requestFocus();

      case ChangePinStep.confirmNew:
        if (value != _newPin) {
          setState(() {
            _errorMessage = 'PINs do not match. Please try again.';
            _step = ChangePinStep.enterNew;
            _newPin = '';
            _pinController.clear();
          });
          _focusNode.requestFocus();
          return;
        }

        setState(() {
          _isLoading = true;
        });

        final result = await repo.changePin(
          currentPin: _oldPin,
          newPin: _newPin,
        );

        if (!mounted) return;

        result.fold(
          (failure) {
            setState(() {
              _isLoading = false;
              _errorMessage = failure.displayMessage;
              _pinController.clear();
              final isAuthError = failure.maybeWhen(
                unauthorized: () => true,
                orElse: () => false,
              );
              if (isAuthError ||
                  failure.displayMessage.contains('เดิม') ||
                  failure.displayMessage.contains('current')) {
                _step = ChangePinStep.verifyOld;
                _oldPin = '';
                _newPin = '';
              }
            });
            _focusNode.requestFocus();
          },
          (_) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('เปลี่ยนรหัส PIN สำเร็จแล้ว')),
            );
            Navigator.of(context).pop();
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final title = switch (_step) {
      ChangePinStep.verifyOld => 'ยืนยัน PIN เดิม',
      ChangePinStep.enterNew => 'ตั้งค่า PIN ใหม่',
      ChangePinStep.confirmNew => 'ยืนยัน PIN ใหม่',
    };

    final message = switch (_step) {
      ChangePinStep.verifyOld => 'กรุณากรอกรหัส PIN เดิมของคุณเพื่อทำรายการ',
      ChangePinStep.enterNew => 'กรุณากรอกรหัส PIN ใหม่ 6 หลัก',
      ChangePinStep.confirmNew => 'กรุณากรอกรหัส PIN ใหม่อีกครั้งเพื่อยืนยัน',
    };

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              _step == ChangePinStep.verifyOld
                  ? Icons.security_rounded
                  : Icons.lock_reset_rounded,
              color: theme.colorScheme.primary,
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.headingSmall.copyWith(
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 18),
            PinCodeInput(
              textFieldKey: const Key('change_pin_text_field'),
              controller: _pinController,
              focusNode: _focusNode,
              isLoading: _isLoading,
              hasError: _errorMessage != null,
              onCompleted: _handlePinSubmit,
              onChanged: (val) {
                if (_errorMessage != null) {
                  setState(() => _errorMessage = null);
                }
              },
            ),
            const SizedBox(height: 10),
            if (_isLoading) ...[
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(height: 8),
            ],
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 6),
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
              _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
      ],
    );
  }
}
