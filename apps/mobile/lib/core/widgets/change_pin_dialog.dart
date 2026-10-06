import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/core/security/pin_provider.dart';
import 'package:subscription_track/core/theme/app_colors.dart';
import 'package:subscription_track/core/theme/app_typography.dart';

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
    if (_pinController.text.length < 6) {
      final updated = _pinController.text + key;
      _pinController.text = updated;
      setState(() {
        _errorMessage = null;
      });
      _focusNode.requestFocus();
      if (updated.length == 6) {
        _handlePinSubmit(updated);
      }
    }
  }

  void _onKeypadClear() {
    if (_isLoading || _pinController.text.isEmpty) return;
    setState(() {
      _pinController.clear();
      _errorMessage = null;
    });
    _focusNode.requestFocus();
  }

  void _onKeypadBackspace() {
    if (_isLoading || _pinController.text.isEmpty) return;
    final current = _pinController.text;
    _pinController.text = current.substring(0, current.length - 1);
    setState(() {
      _errorMessage = null;
    });
    _focusNode.requestFocus();
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

  Widget _buildKeypad(ThemeData theme) {
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
                    width: 68,
                    height: 44,
                    child: TextButton(
                      key: const Key('pin_key_clear'),
                      onPressed:
                          _isLoading || _pinController.text.isEmpty
                              ? null
                              : _onKeypadClear,
                      child: const Text('ล้าง', style: TextStyle(fontSize: 13)),
                    ),
                  );
                }
                if (key == 'backspace') {
                  return SizedBox(
                    width: 68,
                    height: 44,
                    child: IconButton(
                      key: const Key('pin_key_backspace'),
                      icon: const Icon(Icons.backspace_outlined, size: 20),
                      onPressed:
                          _isLoading || _pinController.text.isEmpty
                              ? null
                              : _onKeypadBackspace,
                    ),
                  );
                }
                return SizedBox(
                  width: 68,
                  height: 44,
                  child: OutlinedButton(
                    key: Key('pin_key_$key'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: _isLoading ? null : () => _onKeypadTap(key),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = _pinController.text;

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
            // Robust PIN input: Visual boxes underneath + transparent TextField on top spanning the exact area
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
                        final isFocused =
                            _focusNode.hasFocus && index == text.length;

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
                        key: const Key('change_pin_text_field'),
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
                            _handlePinSubmit(val);
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
              const SizedBox(height: 12),
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
            // On-screen keypad for direct clicking on web/desktop and mobile
            _buildKeypad(theme),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
      ],
    );
  }
}
